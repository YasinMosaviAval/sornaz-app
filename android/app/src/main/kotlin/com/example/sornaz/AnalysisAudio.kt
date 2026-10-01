package com.example.sornaz

import android.content.Context
import android.media.AudioFormat
import android.media.MediaCodec
import android.media.MediaCodecInfo
import android.media.MediaExtractor
import android.media.MediaFormat
import android.net.Uri
import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream
import java.util.concurrent.Executors
import java.util.concurrent.atomic.AtomicBoolean

/** Decodes to a temporary s16le file without keeping the recording in memory. */
class AnalysisAudio(context: Context, messenger: BinaryMessenger) {
    private val app = context.applicationContext
    private val main = Handler(Looper.getMainLooper())
    private val worker = Executors.newSingleThreadExecutor()
    private val cancelled = AtomicBoolean(false)
    @Volatile private var busy = false

    init {
        MethodChannel(messenger, "sornaz/analysis_audio").setMethodCallHandler { call, result ->
            when (call.method) {
                "cancel" -> { cancelled.set(true); result.success(null) }
                "decode" -> {
                    if (busy) { result.error("DECODE_FAILED", "Decoder is busy", null); return@setMethodCallHandler }
                    busy = true
                    cancelled.set(false)
                    val source = call.argument<String>("source") ?: ""
                    val content = call.argument<Boolean>("contentUri") == true
                    worker.execute {
                        try {
                            val value = decode(source, content)
                            main.post { result.success(value) }
                        } catch (error: Exception) {
                            val code = when {
                                cancelled.get() -> "CANCELLED"
                                error is java.io.FileNotFoundException -> "MISSING_FILE"
                                error is UnsupportedOperationException -> "UNSUPPORTED_FORMAT"
                                else -> "DECODE_FAILED"
                            }
                            main.post { result.error(code, error.message, null) }
                        } finally { busy = false }
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun decode(source: String, content: Boolean): Map<String, Any> {
        val extractor = MediaExtractor()
        var codec: MediaCodec? = null
        var target: File? = null
        try {
            if (content) {
                val uri = Uri.parse(source)
                if (uri.scheme != "content") throw UnsupportedOperationException("Expected content URI")
                extractor.setDataSource(app, uri, null)
            } else {
                val file = File(source)
                if (!file.isFile) throw java.io.FileNotFoundException(source)
                extractor.setDataSource(file.absolutePath)
            }
            val track = (0 until extractor.trackCount).firstOrNull {
                extractor.getTrackFormat(it).getString(MediaFormat.KEY_MIME)?.startsWith("audio/") == true
            } ?: throw UnsupportedOperationException("No audio track")
            val format = extractor.getTrackFormat(track)
            val mime = format.getString(MediaFormat.KEY_MIME)
                ?: throw UnsupportedOperationException("Unknown audio codec")
            if (mime != "audio/mp4a-latm") throw UnsupportedOperationException("Only AAC-LC recordings are supported")
            if (format.containsKey(MediaFormat.KEY_AAC_PROFILE) &&
                format.getInteger(MediaFormat.KEY_AAC_PROFILE) != MediaCodecInfo.CodecProfileLevel.AACObjectLC)
                throw UnsupportedOperationException("Only AAC-LC recordings are supported")
            extractor.selectTrack(track)
            val decoder = MediaCodec.createDecoderByType(mime)
            codec = decoder
            decoder.configure(format, null, null, 0)
            decoder.start()
            val decodedFile = File.createTempFile("analysis-decoded-", ".s16le", app.cacheDir)
            target = decodedFile
            val output = FileOutputStream(decodedFile)
            var inputDone = false
            var outputDone = false
            var sampleRate = format.getInteger(MediaFormat.KEY_SAMPLE_RATE)
            var channels = format.getInteger(MediaFormat.KEY_CHANNEL_COUNT)
            val info = MediaCodec.BufferInfo()
            output.use { sink ->
                while (!outputDone) {
                    if (cancelled.get()) throw InterruptedException("Cancelled")
                    if (!inputDone) {
                        val index = decoder.dequeueInputBuffer(10000)
                        if (index >= 0) {
                            val buffer = decoder.getInputBuffer(index)!!
                            buffer.clear()
                            val size = extractor.readSampleData(buffer, 0)
                            if (size < 0) {
                                decoder.queueInputBuffer(index, 0, 0, 0, MediaCodec.BUFFER_FLAG_END_OF_STREAM)
                                inputDone = true
                            } else {
                                decoder.queueInputBuffer(index, 0, size, extractor.sampleTime, 0)
                                extractor.advance()
                            }
                        }
                    }
                    when (val index = decoder.dequeueOutputBuffer(info, 10000)) {
                        MediaCodec.INFO_OUTPUT_FORMAT_CHANGED -> {
                            val decoded = decoder.outputFormat
                            sampleRate = decoded.getInteger(MediaFormat.KEY_SAMPLE_RATE)
                            channels = decoded.getInteger(MediaFormat.KEY_CHANNEL_COUNT)
                            val encoding = if (decoded.containsKey(MediaFormat.KEY_PCM_ENCODING))
                                decoded.getInteger(MediaFormat.KEY_PCM_ENCODING) else AudioFormat.ENCODING_PCM_16BIT
                            if (encoding != AudioFormat.ENCODING_PCM_16BIT)
                                throw UnsupportedOperationException("Decoder did not produce 16-bit PCM")
                        }
                        else -> if (index >= 0) {
                            if (info.size > 0) {
                                val bytes = ByteArray(minOf(info.size, 65536))
                                val buffer = decoder.getOutputBuffer(index)!!
                                buffer.position(info.offset)
                                buffer.limit(info.offset + info.size)
                                while (buffer.hasRemaining()) {
                                    val count = minOf(buffer.remaining(), bytes.size)
                                    buffer.get(bytes, 0, count)
                                    sink.write(bytes, 0, count)
                                }
                            }
                            outputDone = info.flags and MediaCodec.BUFFER_FLAG_END_OF_STREAM != 0
                            decoder.releaseOutputBuffer(index, false)
                        }
                    }
                }
            }
            if (cancelled.get()) throw InterruptedException("Cancelled")
            return mapOf(
                "path" to decodedFile.absolutePath, "sampleRate" to sampleRate,
                "channels" to channels,
                "durationUs" to if (format.containsKey(MediaFormat.KEY_DURATION)) format.getLong(MediaFormat.KEY_DURATION) else 0L,
                "mime" to mime,
            )
        } catch (error: Exception) {
            target?.delete()
            throw error
        } finally {
            try { codec?.stop() } catch (_: Exception) {}
            codec?.release()
            extractor.release()
        }
    }
}
