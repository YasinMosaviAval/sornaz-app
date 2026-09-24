package com.example.sornaz

import android.app.Activity
import android.media.MediaScannerConnection
import android.net.Uri
import androidx.media3.common.MediaItem
import androidx.media3.common.MimeTypes
import androidx.media3.transformer.*
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import java.io.File

/** Render to a separate file first; originals are changed only by commit. */
class AudioCrop(private val activity: Activity, messenger: BinaryMessenger) {
    private var transformer: Transformer? = null
    init {
        MethodChannel(messenger, "sornaz/audio_crop").setMethodCallHandler { call, result ->
            try {
                when (call.method) {
                    "render" -> {
                        check(transformer == null) { "An export is already running" }
                        val source = call.argument<String>("source")!!
                        val start = call.argument<Number>("start")!!.toLong()
                        val end = call.argument<Number>("end")!!.toLong()
                        require(start >= 0 && end > start)
                        val uri = if (source.startsWith("content:")) Uri.parse(source) else Uri.fromFile(File(source))
                        val video = call.argument<Boolean>("video") == true
                        val out = File(activity.cacheDir, "crop-${System.nanoTime()}.${if(video) "mp4" else "m4a"}")
                        val media = MediaItem.Builder().setUri(uri).setClippingConfiguration(
                            MediaItem.ClippingConfiguration.Builder().setStartPositionMs(start).setEndPositionMs(end).build()
                        ).build()
                        transformer = Transformer.Builder(activity).setAudioMimeType(MimeTypes.AUDIO_AAC).setVideoMimeType(MimeTypes.VIDEO_H264)
                            .addListener(object : Transformer.Listener {
                                override fun onCompleted(composition: Composition, exportResult: ExportResult) {
                                    transformer = null
                                    result.success(out.path)
                                }
                                override fun onError(composition: Composition, exportResult: ExportResult, exception: ExportException) {
                                    transformer = null; out.delete()
                                    result.error("CROP_FAILED", exception.message, null)
                                }
                            }).build()
                        try {
                            transformer!!.start(EditedMediaItem.Builder(media).setRemoveVideo(!video).build(), out.path)
                        } catch (e: Exception) {
                            transformer?.cancel(); transformer = null; out.delete()
                            throw e
                        }
                    }
                    "commit" -> Thread {
                        try {
                            val staged = File(call.argument<String>("staged")!!).canonicalFile
                            require(staged.parentFile == activity.cacheDir.canonicalFile && staged.name.startsWith("crop-") && staged.length() > 0)
                            val source = call.argument<String>("source")!!
                            val replace = call.argument<Boolean>("replace") == true
                            val destination: String
                            if (source.startsWith("content:")) {
                                require(replace) { "New recordings must be published through recording storage" }
                                val uri = Uri.parse(source)
                                val backup = File(activity.cacheDir, "crop-backup-${System.nanoTime()}")
                                activity.contentResolver.openInputStream(uri)!!.use { input -> backup.outputStream().use { input.copyTo(it) } }
                                var safeToRemoveBackup = false
                                try {
                                    try {
                                        activity.contentResolver.openOutputStream(uri, "wt")!!.use { output -> staged.inputStream().use { it.copyTo(output) } }
                                        safeToRemoveBackup = true
                                    } catch (e: Exception) {
                                        activity.contentResolver.openOutputStream(uri, "wt")!!.use { output -> backup.inputStream().use { it.copyTo(output) } }
                                        safeToRemoveBackup = true
                                        throw e
                                    }
                                } finally { if (safeToRemoveBackup) backup.delete() }
                                destination = source
                            } else {
                                val original = File(source).canonicalFile
                                val name = original.nameWithoutExtension + if (replace) ".m4a" else "_crop_${System.currentTimeMillis()}.m4a"
                                val target = File(original.parentFile, name)
                                require(target == original || !target.exists()) { "A file with the output name already exists" }
                                val temp = File(original.parentFile, ".crop-${System.nanoTime()}.tmp")
                                val backup = File(original.parentFile, ".crop-backup-${System.nanoTime()}")
                                try {
                                    staged.copyTo(temp)
                                    if (replace) check(original.renameTo(backup)) { "Cannot replace this file" }
                                    if (!temp.renameTo(target)) {
                                        if (replace) check(backup.renameTo(original))
                                        error("Cannot save cropped audio")
                                    }
                                    if (replace) backup.delete()
                                } finally { temp.delete() }
                                destination = target.path
                                MediaScannerConnection.scanFile(activity, arrayOf(original.path, target.path), null, null)
                            }
                            staged.delete()
                            activity.runOnUiThread { result.success(destination) }
                        } catch (e: Exception) { activity.runOnUiThread { result.error("SAVE_FAILED", e.message, null) } }
                    }.start()
                    else -> result.notImplemented()
                }
            } catch (e: Exception) { result.error("CROP_FAILED", e.message, null) }
        }
    }
}
