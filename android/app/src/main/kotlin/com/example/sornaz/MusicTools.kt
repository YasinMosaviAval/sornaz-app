package com.example.sornaz

import android.app.Activity
import android.content.ContentValues
import android.content.Intent
import android.media.RingtoneManager
import android.net.Uri
import android.os.Build
import android.provider.MediaStore
import android.provider.Settings
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MusicTools(private val activity: Activity, messenger: BinaryMessenger) {
    init {
        MethodChannel(messenger, "sornaz/music_tools").setMethodCallHandler { call, result ->
            if (call.method != "ringtone") { result.notImplemented(); return@setMethodCallHandler }
            try {
                if (!Settings.System.canWrite(activity)) {
                    activity.startActivity(Intent(Settings.ACTION_MANAGE_WRITE_SETTINGS, Uri.parse("package:${activity.packageName}")))
                    result.error("PERMISSION", "Allow modifying system settings, then select Set as Ringtone again.", null)
                    return@setMethodCallHandler
                }
                val file = File(requireNotNull(call.argument<String>("path")))
                require(file.isFile)
                val legacyCopy = if (Build.VERSION.SDK_INT < 29) {
                    val folder = File(android.os.Environment.getExternalStoragePublicDirectory(android.os.Environment.DIRECTORY_RINGTONES), "Sornaz")
                    require(folder.isDirectory || folder.mkdirs())
                    File(folder, "${System.currentTimeMillis()}-${file.name}").also { file.copyTo(it) }
                } else null
                val values = ContentValues().apply {
                    put(MediaStore.Audio.Media.DISPLAY_NAME, file.name)
                    put(MediaStore.Audio.Media.TITLE, file.nameWithoutExtension)
                    put(MediaStore.Audio.Media.MIME_TYPE, android.webkit.MimeTypeMap.getSingleton().getMimeTypeFromExtension(file.extension.lowercase()) ?: "audio/mpeg")
                    put(MediaStore.Audio.Media.IS_RINGTONE, 1)
                    if (Build.VERSION.SDK_INT >= 29) {
                        put(MediaStore.Audio.Media.RELATIVE_PATH, "Ringtones/Sornaz")
                        put(MediaStore.Audio.Media.IS_PENDING, 1)
                    } else put(MediaStore.Audio.Media.DATA, requireNotNull(legacyCopy).path)
                }
                val resolver = activity.contentResolver
                val uri = try { requireNotNull(resolver.insert(MediaStore.Audio.Media.EXTERNAL_CONTENT_URI, values)) }
                    catch (e: Exception) { legacyCopy?.delete(); throw e }
                try {
                    if (Build.VERSION.SDK_INT >= 29) {
                        requireNotNull(resolver.openOutputStream(uri)).use { output -> file.inputStream().use { it.copyTo(output) } }
                        resolver.update(uri, ContentValues().apply { put(MediaStore.Audio.Media.IS_PENDING, 0) }, null, null)
                    }
                    RingtoneManager.setActualDefaultRingtoneUri(activity, RingtoneManager.TYPE_RINGTONE, uri)
                    result.success(null)
                } catch (e: Exception) { resolver.delete(uri, null, null); throw e }
            } catch (e: Exception) { result.error("RINGTONE_FAILED", e.message, null) }
        }
    }
}
