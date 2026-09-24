package com.example.sornaz

import android.app.Activity
import android.content.ContentUris
import android.os.Build
import android.provider.MediaStore
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

class DeviceVideos(private val activity: Activity, messenger: BinaryMessenger) {
    private var pendingResult: MethodChannel.Result? = null
    private var pendingAction: (() -> Unit)? = null
    fun onResult(requestCode: Int, resultCode: Int): Boolean {
        if(requestCode != 8621) return false
        val result = pendingResult ?: return true
        val action = pendingAction
        pendingResult = null; pendingAction = null
        if(resultCode != Activity.RESULT_OK) { result.error("CANCELLED", "Media change cancelled", null); return true }
        try { action?.invoke() } catch(e: Exception) { result.error("VIDEO_ACTION", e.message, null) }
        return true
    }
    private fun mutate(uris: List<android.net.Uri>, action: () -> Unit, result: MethodChannel.Result) {
        try { action(); result.success(null) }
        catch (e: SecurityException) {
            try {
                val sender = if (Build.VERSION.SDK_INT >= 30) MediaStore.createWriteRequest(activity.contentResolver, uris).intentSender
                    else if (Build.VERSION.SDK_INT >= 29 && e is android.app.RecoverableSecurityException) e.userAction.actionIntent.intentSender
                    else throw e
                pendingResult = result
                // Android 10 grants access one item at a time. Resume the batch
                // and request the next grant without prematurely completing it.
                pendingAction = { mutate(uris, action, result) }
                activity.startIntentSenderForResult(sender, 8621, null, 0, 0, 0)
            } catch (failure: Exception) {
                pendingResult = null; pendingAction = null
                result.error("VIDEO_ACTION", failure.message, null)
            }
        } catch (e: Exception) { result.error("VIDEO_ACTION", e.message, null) }
    }
    init {
        MethodChannel(messenger, "sornaz/device_videos").setMethodCallHandler { call, result ->
            if (call.method == "sdk") result.success(Build.VERSION.SDK_INT)
            else if (call.method == "list") Thread {
                try {
                    val entries = mutableListOf<Map<String, Any>>()
                    val collection = MediaStore.Video.Media.EXTERNAL_CONTENT_URI
                    val columns = arrayOf(MediaStore.Video.Media._ID, MediaStore.Video.Media.DISPLAY_NAME,
                        MediaStore.Video.Media.DURATION, MediaStore.Video.Media.BUCKET_DISPLAY_NAME, MediaStore.Video.Media.BUCKET_ID)
                    activity.contentResolver.query(collection, columns, null, null, "${MediaStore.Video.Media.DATE_ADDED} DESC")?.use { cursor ->
                        while (cursor.moveToNext()) {
                            entries.add(mapOf("uri" to ContentUris.withAppendedId(collection, cursor.getLong(0)).toString(),
                                "name" to (cursor.getString(1) ?: "Video"), "duration" to cursor.getLong(2),
                                "folder" to (cursor.getString(3) ?: "Videos"), "folderId" to cursor.getLong(4).toString()))
                        }
                    }
                    activity.runOnUiThread { result.success(entries) }
                } catch (e: Exception) { activity.runOnUiThread { result.error("VIDEO_LIBRARY", e.message, null) } }
            }.start()
            else if (call.method in listOf("rename", "delete", "share", "saveCrop")) {
                try {
                    val uris = (call.argument<List<String>>("uris") ?: emptyList()).map { android.net.Uri.parse(it) }
                    require(uris.all { it.scheme == "content" && it.authority == "media" })
                    when (call.method) {
                        "share" -> {
                            require(uris.isNotEmpty())
                            val intent = android.content.Intent(android.content.Intent.ACTION_SEND_MULTIPLE).apply {
                                type = "video/*"
                                putParcelableArrayListExtra(android.content.Intent.EXTRA_STREAM, ArrayList(uris))
                                clipData = android.content.ClipData.newUri(activity.contentResolver, "Videos", uris.first()).also { clip -> uris.drop(1).forEach { clip.addItem(android.content.ClipData.Item(it)) } }
                                addFlags(android.content.Intent.FLAG_GRANT_READ_URI_PERMISSION)
                            }
                            activity.startActivity(android.content.Intent.createChooser(intent, "Share videos")); result.success(null)
                        }
                        "saveCrop" -> {
                          Thread { try {
                            val staged = java.io.File(call.argument<String>("staged")!!).canonicalFile
                            require(staged.parentFile == activity.cacheDir.canonicalFile && staged.name.startsWith("crop-") && staged.extension == "mp4" && staged.length() > 0)
                            val name = "video_crop_${System.currentTimeMillis()}.mp4"
                            if (Build.VERSION.SDK_INT >= 29) {
                                val values = android.content.ContentValues().apply { put(MediaStore.Video.Media.DISPLAY_NAME, name); put(MediaStore.Video.Media.MIME_TYPE, "video/mp4"); put(MediaStore.Video.Media.RELATIVE_PATH, "Movies/Sornaz"); put(MediaStore.Video.Media.IS_PENDING, 1) }
                                val uri = activity.contentResolver.insert(MediaStore.Video.Media.EXTERNAL_CONTENT_URI, values) ?: error("Cannot create video")
                                try {
                                    activity.contentResolver.openOutputStream(uri)!!.use { out -> staged.inputStream().use { it.copyTo(out) } }
                                    activity.contentResolver.update(uri, android.content.ContentValues().apply { put(MediaStore.Video.Media.IS_PENDING, 0) }, null, null)
                                    activity.runOnUiThread { result.success(uri.toString()) }
                                } catch (e: Exception) { activity.contentResolver.delete(uri, null, null); throw e }
                            } else {
                                val directory = java.io.File(android.os.Environment.getExternalStoragePublicDirectory(android.os.Environment.DIRECTORY_MOVIES), "Sornaz").apply { mkdirs() }
                                val file = java.io.File(directory, name); staged.copyTo(file)
                                android.media.MediaScannerConnection.scanFile(activity, arrayOf(file.path), arrayOf("video/mp4"), null)
                                activity.runOnUiThread { result.success(file.path) }
                            }
                            staged.delete()
                          } catch(e: Exception) { activity.runOnUiThread { result.error("VIDEO_ACTION", e.message, null) } } }.start()
                        }
                        else -> {
                            require(uris.isNotEmpty())
                            check(pendingResult == null) { "Another media request is pending" }
                            if (Build.VERSION.SDK_INT >= 30 && call.method == "delete") {
                                val sender = MediaStore.createDeleteRequest(activity.contentResolver, uris).intentSender
                                pendingResult = result
                                pendingAction = { result.success(null) }
                                activity.startIntentSenderForResult(sender, 8621, null, 0, 0, 0)
                                return@setMethodCallHandler
                            }
                            val action = {
                                if (call.method == "delete") uris.forEach { activity.contentResolver.delete(it, null, null) }
                                else {
                                    require(uris.size == 1)
                                    val name = call.argument<String>("name")!!.trim()
                                    require(name.isNotEmpty() && name.length <= 180 && !name.contains('/') && !name.contains('\\'))
                                    check(activity.contentResolver.update(uris.single(), android.content.ContentValues().apply { put(MediaStore.Video.Media.DISPLAY_NAME, name) }, null, null) > 0)
                                }
                                Unit
                            }
                            mutate(uris, action, result)
                        }
                    }
                } catch(e: Exception) { pendingResult = null; pendingAction = null; result.error("VIDEO_ACTION", e.message, null) }
            } else result.notImplemented()
        }
    }
}
