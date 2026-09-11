package com.example.sornaz
import android.content.Context
import android.net.Uri
import android.media.MediaExtractor
import android.media.MediaFormat
import android.media.MediaMuxer
import android.media.MediaCodec
import java.io.File
import java.nio.ByteBuffer

object AudioSplice {
    fun replace(context: Context, original: Uri, replacement: File, atMs: Long, keepTail: Boolean = true) {
        require(atMs >= 0 && replacement.isFile)
        val old = MediaExtractor(); val new = MediaExtractor()
        val output = File(context.cacheDir, "splice-${System.nanoTime()}.m4a")
        val backup = File(context.cacheDir, "splice-backup-${System.nanoTime()}.m4a")
        var muxer: MediaMuxer? = null
        try {
            context.contentResolver.openInputStream(original)!!.use { input -> backup.outputStream().use { input.copyTo(it) } }
            old.setDataSource(backup.path); new.setDataSource(replacement.path)
            fun audio(ex: MediaExtractor): Int = (0 until ex.trackCount).first { ex.getTrackFormat(it).getString(MediaFormat.KEY_MIME)?.startsWith("audio/") == true }
            val oldIndex = audio(old); val newIndex = audio(new)
            val format = old.getTrackFormat(oldIndex); val newFormat = new.getTrackFormat(newIndex)
            for (key in listOf(MediaFormat.KEY_SAMPLE_RATE, MediaFormat.KEY_CHANNEL_COUNT)) require(format.getInteger(key) == newFormat.getInteger(key))
            require(format.getString(MediaFormat.KEY_MIME) == newFormat.getString(MediaFormat.KEY_MIME))
            old.selectTrack(oldIndex); new.selectTrack(newIndex)
            val writer = MediaMuxer(output.path, MediaMuxer.OutputFormat.MUXER_OUTPUT_MPEG_4)
            muxer = writer
            val track = writer.addTrack(format); writer.start()
            val buffer = ByteBuffer.allocate(1024 * 1024); val info = MediaCodec.BufferInfo()
            var last = -1L
            fun copy(ex: MediaExtractor, from: Long, until: Long, shift: Long) {
                ex.seekTo(from, MediaExtractor.SEEK_TO_PREVIOUS_SYNC)
                while(ex.sampleTime >= 0 && ex.sampleTime < until) {
                    val time = ex.sampleTime
                    if(time >= from) {
                        val size = ex.readSampleData(buffer, 0)
                        if(size < 0) break
                        val timestamp = time + shift
                        if(timestamp > last) {
                            info.set(0, size, timestamp, ex.sampleFlags)
                            writer.writeSampleData(track, buffer, info); last = timestamp
                        }
                    }
                    ex.advance()
                }
            }
            val at = atMs * 1000
            val duration = newFormat.getLong(MediaFormat.KEY_DURATION)
            copy(old, 0, at, 0); copy(new, 0, Long.MAX_VALUE, at)
            if (keepTail) copy(old, at + duration, Long.MAX_VALUE, 0)
            writer.stop(); writer.release(); muxer = null
            try { context.contentResolver.openOutputStream(original, "wt")!!.use { out -> output.inputStream().use { it.copyTo(out) } } }
            catch (e: Exception) {
                context.contentResolver.openOutputStream(original, "wt")!!.use { out -> backup.inputStream().use { it.copyTo(out) } }
                throw e
            }
        } finally {
            old.release(); new.release(); muxer?.release(); output.delete(); backup.delete()
        }
    }
}
