package com.example.sornaz

import android.app.Activity
import android.content.ContentUris
import android.content.ContentValues
import android.media.MediaScannerConnection
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import java.io.File

/** Scoped-storage edits must use MediaStore and its system consent dialog. */
class MediaFiles(private val activity: Activity, messenger: BinaryMessenger) {
    private var pending: (() -> Unit)? = null
    private var pendingResult: MethodChannel.Result? = null

    fun onResult(requestCode: Int, resultCode: Int): Boolean {
        if (requestCode != 8622) return false
        val retry = pending
        val result = pendingResult
        pending = null
        pendingResult = null
        if (resultCode == Activity.RESULT_OK) retry?.invoke()
        else result?.error("CANCELLED", "Media change cancelled", null)
        return true
    }

    private fun edit(uri: Uri, result: MethodChannel.Result, action: () -> String) {
        try { result.success(action()) }
        catch (e: SecurityException) {
            try {
                val sender = if (Build.VERSION.SDK_INT >= 30)
                    MediaStore.createWriteRequest(activity.contentResolver, listOf(uri)).intentSender
                else if (Build.VERSION.SDK_INT >= 29 && e is android.app.RecoverableSecurityException)
                    e.userAction.actionIntent.intentSender
                else throw e
                check(pendingResult == null) { "Another media edit is pending" }
                pendingResult = result
                pending = { edit(uri, result, action) }
                activity.startIntentSenderForResult(sender, 8622, null, 0, 0, 0)
            } catch (failure: Exception) {
                pending = null; pendingResult = null
                result.error("MEDIA_EDIT", failure.message, null)
            }
        } catch (e: Exception) { result.error("MEDIA_EDIT", e.message, null) }
    }

    init {
        MethodChannel(messenger, "sornaz/media_files").setMethodCallHandler { call, result ->
            when (call.method) {
                "listAudio" -> Thread {
                    try {
                        val entries = mutableListOf<Map<String, Any>>()
                        val columns = arrayOf(MediaStore.Audio.Media.DATA, MediaStore.Audio.Media.DISPLAY_NAME,
                            MediaStore.Audio.Media.DURATION, MediaStore.Audio.Media.DATE_ADDED)
                        activity.contentResolver.query(MediaStore.Audio.Media.EXTERNAL_CONTENT_URI,
                            columns, null, null, null)?.use { cursor ->
                            while (cursor.moveToNext()) {
                                val path = cursor.getString(0) ?: continue
                                entries.add(mapOf("path" to path, "name" to (cursor.getString(1) ?: File(path).name),
                                    "duration" to cursor.getLong(2), "addedAt" to cursor.getLong(3)))
                            }
                        }
                        activity.runOnUiThread { result.success(entries) }
                    } catch (e: Exception) {
                        activity.runOnUiThread { result.error("MEDIA_SCAN", e.message, null) }
                    }
                }.start()
                "relocate" -> {
                    try {
                        check(pendingResult == null) { "Another media edit is pending" }
                        val source = call.argument<String>("source")!!
                        val destination = File(call.argument<String>("destination")!!).canonicalFile
                        require(destination.name.isNotBlank() && destination.name != "." && destination.name != "..")
                        require(destination.parentFile?.isDirectory == true) { "Destination folder is unavailable" }
                        val resolver = activity.contentResolver
                        var uri = Uri.parse(source).takeIf { it.scheme == "content" && it.authority == "media" }
                        if (uri == null) {
                            val collection = MediaStore.Audio.Media.EXTERNAL_CONTENT_URI
                            resolver.query(collection, arrayOf(MediaStore.Files.FileColumns._ID),
                                "${MediaStore.Files.FileColumns.DATA} = ?", arrayOf(source), null)?.use { cursor ->
                                if (cursor.moveToFirst()) uri = ContentUris.withAppendedId(collection, cursor.getLong(0))
                            }
                        }
                        val mediaUri = uri
                        if (mediaUri == null || Build.VERSION.SDK_INT < 29) {
                            val original = File(source)
                            require(!destination.exists()) { "A file with this name already exists" }
                            check(original.renameTo(destination)) { "Cannot move this file" }
                            MediaScannerConnection.scanFile(activity, arrayOf(source, destination.path), null, null)
                            result.success(destination.path)
                        } else {
                            // Resolve the real source path and volume before changing any file.
                            var originalPath: String? = null
                            resolver.query(mediaUri, arrayOf(MediaStore.MediaColumns.DATA), null, null, null)?.use {
                                if (it.moveToFirst()) originalPath = it.getString(0)
                            }
                            val original = File(originalPath ?: error("Media path unavailable")).canonicalFile
                            if (original == destination) { result.success(destination.path); return@setMethodCallHandler }
                            val primary = Environment.getExternalStorageDirectory().canonicalPath
                            val root = if (original.path.startsWith("$primary/")) primary
                                else Regex("^(/storage/[^/]+)/").find(original.path)?.groupValues?.get(1)
                                    ?: error("Unsupported storage volume")
                            require(destination.path.startsWith("$root/")) { "Choose a folder on the same storage volume" }
                            val relative = destination.parentFile!!.path.removePrefix("$root/") + "/"
                            edit(mediaUri, result) {
                                require(!destination.exists()) { "A file with this name already exists" }
                                val values = ContentValues().apply {
                                    put(MediaStore.MediaColumns.DISPLAY_NAME, destination.name)
                                    put(MediaStore.MediaColumns.RELATIVE_PATH, relative)
                                }
                                check(resolver.update(mediaUri, values, null, null) > 0) { "Media file was not updated" }
                                var path = destination.path
                                resolver.query(mediaUri, arrayOf(MediaStore.MediaColumns.DATA), null, null, null)?.use {
                                    if (it.moveToFirst()) path = it.getString(0) ?: path
                                }
                                path
                            }
                        }
                    } catch (e: Exception) { result.error("MEDIA_EDIT", e.message, null) }
                }
                else -> result.notImplemented()
            }
        }
    }
}
