package com.example.sornaz

import android.content.Context
import android.media.AudioAttributes
import android.media.AudioFormat
import android.media.AudioTrack
import android.os.Handler
import android.os.Looper
import android.os.Process
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import java.nio.ByteBuffer
import java.nio.ByteOrder
import kotlin.math.*

/** Audio is scheduled by PCM sample position, independent of Flutter frames. */
class PracticeMetronome(private val context: Context, messenger: BinaryMessenger) {
    private val main = Handler(Looper.getMainLooper())
    private var sink: EventChannel.EventSink? = null
    @Volatile private var running = false
    @Volatile private var bpm = 120
    @Volatile private var beats = 4
    @Volatile private var subdivisions = 1
    @Volatile private var volumes = floatArrayOf(1f, .75f, .1f)
    @Volatile private var maxFrames = Long.MAX_VALUE
    @Volatile private var maxBars = 0
    private var worker: Thread? = null
    private var track: AudioTrack? = null
    private val samples by lazy { listOf("accent", "tick", "sub_tick").map { loadWav(it) } }
    init {
        EventChannel(messenger, "sornaz/metronome/events").setStreamHandler(object: EventChannel.StreamHandler {
            override fun onListen(args: Any?, events: EventChannel.EventSink) { sink = events }
            override fun onCancel(args: Any?) { sink = null }
        })
        MethodChannel(messenger, "sornaz/metronome").setMethodCallHandler { call, result ->
            try {
                if (call.method == "stop") { stop(); result.success(null) }
                else if (call.method == "start" || call.method == "configure") {
                    bpm = (call.argument<Int>("bpm") ?: bpm).coerceIn(30, 300)
                    beats = (call.argument<Int>("beats") ?: beats).coerceIn(1, 16)
                    subdivisions = (call.argument<Int>("subdivisions") ?: subdivisions).coerceIn(1, 4)
                    volumes = floatArrayOf(
                        (call.argument<Double>("accent") ?: 1.0).toFloat(),
                        (call.argument<Double>("tick") ?: .75).toFloat(),
                        (call.argument<Double>("sub") ?: .1).toFloat())
                    if (call.method == "start") {
                        stop()
                        val seconds = call.argument<Int>("seconds") ?: 0
                        maxFrames = if (seconds > 0) seconds.toLong() * 44100 else Long.MAX_VALUE
                        maxBars = call.argument<Int>("bars") ?: 0
                        start()
                    }
                    result.success(null)
                } else result.notImplemented()
            } catch (e: Exception) { result.error("METRONOME_FAILED", e.message, null) }
        }
    }
    private fun loadWav(name: String): FloatArray {
        val bytes = context.assets.open("flutter_assets/assets/audio/$name.wav").use { it.readBytes() }
        val b = ByteBuffer.wrap(bytes).order(ByteOrder.LITTLE_ENDIAN)
        var offset = 12; var format = 1; var channels = 1; var rate = 44100; var bits = 16
        var start = 0; var length = 0
        while (offset + 8 <= bytes.size) {
            val id = String(bytes, offset, 4, Charsets.US_ASCII)
            val size = b.getInt(offset + 4)
            if (size < 0 || offset + 8L + size > bytes.size) break
            if (id == "fmt ") {
                format = b.getShort(offset + 8).toInt(); channels = b.getShort(offset + 10).toInt()
                rate = b.getInt(offset + 12); bits = b.getShort(offset + 22).toInt()
            }
            if (id == "data") { start = offset + 8; length = size; break }
            offset += 8 + size + (size % 2)
        }
        require(start > 0 && channels > 0 && rate > 0 && ((format == 3 && bits == 32) || (format == 1 && bits == 16)))
        val count = length / (bits / 8) / channels
        val mono = FloatArray(count) { frame ->
            var value = 0f
            for (c in 0 until channels) {
                val index = start + (frame * channels + c) * (bits / 8)
                value += if (format == 3) b.getFloat(index) else b.getShort(index) / 32768f
            }
            value / channels
        }
        return FloatArray((count * 44100.0 / rate).ceilToInt()) { i ->
            val source = i * rate / 44100.0; val left = floor(source).toInt().coerceIn(0, count - 1)
            val right = min(left + 1, count - 1)
            (mono[left] + (mono[right] - mono[left]) * (source - left)).toFloat()
        }
    }
    private fun Double.ceilToInt() = ceil(this).toInt()
    private fun start() {
        val sounds = samples
        val minimum = AudioTrack.getMinBufferSize(44100, AudioFormat.CHANNEL_OUT_MONO, AudioFormat.ENCODING_PCM_16BIT)
        val audio = AudioTrack.Builder().setAudioAttributes(AudioAttributes.Builder()
            .setUsage(AudioAttributes.USAGE_MEDIA).setContentType(AudioAttributes.CONTENT_TYPE_MUSIC).build())
            .setAudioFormat(AudioFormat.Builder().setSampleRate(44100).setChannelMask(AudioFormat.CHANNEL_OUT_MONO)
                .setEncoding(AudioFormat.ENCODING_PCM_16BIT).build())
            .setBufferSizeInBytes(max(minimum, 2048)).setTransferMode(AudioTrack.MODE_STREAM).build()
        require(audio.state == AudioTrack.STATE_INITIALIZED)
        track = audio; running = true
        worker = Thread {
            Process.setThreadPriority(Process.THREAD_PRIORITY_AUDIO)
            var frame = 0L; var nextTick = 0.0; var beat = 0; var sub = 0; var bar = 1
            var sound = sounds[0]; var sampleIndex = sound.size; var gain = 1f
            val buffer = ShortArray(256)
            try {
                audio.play()
                while (running && frame < maxFrames) {
                    var count = 0
                    while (count < buffer.size && frame < maxFrames && running) {
                        if (frame >= nextTick.roundToLong()) {
                            if (maxBars > 0 && bar > maxBars) { running = false; break }
                            val index = if (sub != 0) 2 else if (beat == 0) 0 else 1
                            sound = sounds[index]; sampleIndex = 0; gain = volumes[index].coerceIn(0f, 1f)
                            val event = mapOf("beat" to beat + 1, "bar" to bar, "accent" to (index == 0))
                            if (sub == 0) main.post { if (running) sink?.success(event) }
                            nextTick += 44100.0 * 60 / bpm / subdivisions
                            sub++
                            if (sub >= subdivisions) { sub = 0; beat++; if (beat >= beats) { beat = 0; bar++ } }
                        }
                        val value = if (sampleIndex < sound.size) sound[sampleIndex++] * gain else 0f
                        buffer[count++] = (value.coerceIn(-1f, 1f) * 32767).toInt().toShort(); frame++
                    }
                    var written = 0
                    while (running && written < count) {
                        val n = audio.write(buffer, written, count - written, AudioTrack.WRITE_BLOCKING)
                        if (n <= 0) throw IllegalStateException("Audio output stopped: $n")
                        written += n
                    }
                }
                // Finish queued samples for a timed/bar-limited practice session.
                if (frame >= maxFrames || (maxBars > 0 && bar > maxBars)) {
                    audio.stop()
                    main.post { sink?.success(mapOf("finished" to true)) }
                }
            } catch (e: Exception) {
                if (running) main.post { sink?.error("AUDIO_OUTPUT", e.message, null) }
            } finally { running = false; try { audio.release() } catch (_: Exception) {} }
        }.apply { name = "SornazMetronomeAudio"; start() }
    }
    fun stop() {
        running = false
        try { track?.pause(); track?.flush() } catch (_: Exception) {}
        worker?.join(500)
        worker = null; track = null
    }
}
