package com.example.sornaz

import android.app.Activity
import android.content.ContentUris
import android.os.Build
import android.provider.MediaStore
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

class DeviceVideos(activity: Activity, messenger: BinaryMessenger) {
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
            else result.notImplemented()
        }
    }
}
