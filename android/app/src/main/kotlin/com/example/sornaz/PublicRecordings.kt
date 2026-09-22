package com.example.sornaz

import android.content.ContentUris
import android.content.ContentValues
import android.content.Context
import android.content.Intent
import android.content.ClipData
import android.os.Build
import android.os.Environment
import android.os.Handler
import android.os.Looper
import android.provider.MediaStore
import android.provider.DocumentsContract
import android.net.Uri
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.util.concurrent.Executors

class PublicRecordings(private val context: Context, messenger: BinaryMessenger) {
    private val resolver = context.contentResolver
    private val collection = MediaStore.Audio.Media.EXTERNAL_CONTENT_URI
    private val main = Handler(Looper.getMainLooper())
    private val work = Executors.newSingleThreadExecutor()
    private val folder = "Music/Sornaz/"
    init {
        MethodChannel(messenger, "sornaz/recordings").setMethodCallHandler { call, result ->
            if (call.method == "sdk") { result.success(Build.VERSION.SDK_INT); return@setMethodCallHandler }
            work.execute {
                try {
                    val value: Any? = when (call.method) {
                        "save" -> save(call.argument<String>("path") ?: "")
                        "list" -> list()
                        "describe" -> describe(owned(call.argument<String>("uri") ?: ""))
                        "spliceDraft" -> {
                            val original = File(call.argument<String>("original") ?: "").canonicalFile
                            val segment = File(call.argument<String>("segment") ?: "").canonicalFile
                            for (file in listOf(original, segment)) require(file.isFile && file.extension == "m4a" && file.parentFile?.name == "Recordings" && file.path.startsWith(File(context.applicationInfo.dataDir).canonicalPath + File.separator))
                            require(original != segment)
                            AudioSplice.replace(context, Uri.fromFile(original), segment, call.argument<Number>("at")!!.toLong(), false)
                            segment.delete()
                            null
                        }
                        "overwrite" -> {
                            val uri = owned(call.argument<String>("uri") ?: "")
                            val replacement = File(call.argument<String>("path") ?: "").canonicalFile
                            require(replacement.path.startsWith(File(context.applicationInfo.dataDir).canonicalPath + File.separator) && replacement.parentFile?.name == "Recordings")
                            AudioSplice.replace(context, uri, replacement, call.argument<Number>("at")!!.toLong())
                            null
                        }
                        "materialize" -> {
                            val uri = owned(call.argument<String>("uri") ?: "")
                            val target = File(context.cacheDir, "recording-edit-${System.nanoTime()}.m4a")
                            resolver.openInputStream(uri)!!.use { input -> target.outputStream().use { input.copyTo(it) } }
                            target.absolutePath
                        }
                        "rename" -> {
                            val uri = owned(call.argument<String>("uri") ?: "")
                            val name = call.argument<String>("name") ?: ""
                            require(name.matches(Regex("[^/\\\\\u0000]{1,100}")))
                            val renamed = "Sornaz_" + name.removePrefix("Sornaz_").removeSuffix(".m4a") + ".m4a"
                            if (DocumentsContract.isDocumentUri(context, uri)) {
                                DocumentsContract.renameDocument(resolver, uri, renamed)?.toString()
                            } else {
                                resolver.update(uri, ContentValues().apply { put(MediaStore.Audio.Media.DISPLAY_NAME, renamed) }, null, null)
                                uri.toString()
                            }
                        }
                        "delete" -> {
                            val uri = owned(call.argument<String>("uri") ?: "")
                            if (DocumentsContract.isDocumentUri(context, uri)) DocumentsContract.deleteDocument(resolver, uri)
                            else resolver.delete(uri, null, null)
                        }
                        "share" -> {
                            val uri = owned(call.argument<String>("uri") ?: "")
                            val intent = Intent(Intent.ACTION_SEND).apply {
                                type = "audio/mp4"; putExtra(Intent.EXTRA_STREAM, uri)
                                clipData = ClipData.newRawUri("Sornaz recording", uri)
                                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                            }
                            main.post { context.startActivity(Intent.createChooser(intent, "Sornaz").addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)) }
                            null
                        }
                        else -> throw IllegalArgumentException("Unknown recording operation")
                    }
                    main.post { result.success(value) }
                } catch (e: Exception) { main.post { result.error("RECORDING_STORAGE", e.message, null) } }
            }
        }
    }
    private fun owned(value: String): Uri {
        require(list().any { it["uri"] == value }) { "Recording is not in the Sornaz folder" }
        return Uri.parse(value)
    }
    private fun list(): List<Map<String, Any>> {
        val results = mutableListOf<Map<String, Any>>()
        val pathColumn = if (Build.VERSION.SDK_INT >= 29) MediaStore.Audio.Media.RELATIVE_PATH else MediaStore.Audio.Media.DATA
        val path = if (Build.VERSION.SDK_INT >= 29) folder else File(Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_MUSIC), "Sornaz").absolutePath + "/%"
        val selection = if (Build.VERSION.SDK_INT >= 29) "$pathColumn = ? AND ${MediaStore.Audio.Media.IS_PENDING} = 0" else "$pathColumn LIKE ?"
        resolver.query(collection, arrayOf(MediaStore.Audio.Media._ID, MediaStore.Audio.Media.DISPLAY_NAME, MediaStore.Audio.Media.DATE_MODIFIED), selection, arrayOf(path), "${MediaStore.Audio.Media.DATE_MODIFIED} DESC")?.use { cursor ->
            while (cursor.moveToNext()) {
                results.add(mapOf("uri" to ContentUris.withAppendedId(collection, cursor.getLong(0)).toString(), "name" to cursor.getString(1), "modified" to cursor.getLong(2) * 1000))
            }
        }
        results.addAll(RecordingWorkspace.list(context))
        return results
    }
    private fun describe(uri: Uri): Map<String, String> {
        val details = linkedMapOf<String, String>("path" to uri.toString())
        val retriever = android.media.MediaMetadataRetriever()
        try {
            retriever.setDataSource(context, uri)
            for ((name, key) in mapOf("durationMs" to 9, "bitrate" to 20, "mime" to 12,
                "sampleRate" to 38, "title" to 7, "artist" to 2, "album" to 1)) {
                try { retriever.extractMetadata(key)?.let { details[name] = it } } catch (_: Exception) {}
            }
        } finally { retriever.release() }
        if (DocumentsContract.isDocumentUri(context, uri)) {
            details["location"] = DocumentsContract.getDocumentId(uri).substringBeforeLast('/')
        } else {
            val column = if (Build.VERSION.SDK_INT >= 29) MediaStore.Audio.Media.RELATIVE_PATH else MediaStore.Audio.Media.DATA
            resolver.query(uri, arrayOf(column), null, null, null)?.use { cursor ->
                if (cursor.moveToFirst()) {
                    val path = cursor.getString(0) ?: ""
                    details["location"] = if (Build.VERSION.SDK_INT >= 29) path else File(path).parent.orEmpty()
                }
            }
        }
        return details
    }
    private fun save(path: String): String {
        val source = File(path).canonicalFile
        require(source.isFile && source.extension == "m4a" && source.parentFile?.name == "Recordings" && source.path.startsWith(File(context.applicationInfo.dataDir).canonicalPath + File.separator))
        val treeValue = context.getSharedPreferences("recording_workspace", 0).getString("tree", null)
        if (treeValue != null) {
            val tree = Uri.parse(treeValue)
            val parent = DocumentsContract.buildDocumentUriUsingTree(tree, DocumentsContract.getTreeDocumentId(tree))
            val target = DocumentsContract.createDocument(resolver, parent, "audio/mp4", "Sornaz_${source.name}") ?: error("Could not create recording")
            try { resolver.openOutputStream(target, "w")!!.use { output -> source.inputStream().use { it.copyTo(output) } } }
            catch (e: Exception) { DocumentsContract.deleteDocument(resolver, target); throw e }
            return target.toString()
        }
        val values = ContentValues().apply {
            put(MediaStore.Audio.Media.DISPLAY_NAME, "Sornaz_${source.name}")
            put(MediaStore.Audio.Media.MIME_TYPE, "audio/mp4")
            put(MediaStore.Audio.Media.IS_MUSIC, 0)
            put(MediaStore.Audio.Media.DATE_ADDED, System.currentTimeMillis() / 1000)
            if (Build.VERSION.SDK_INT >= 29) {
                put(MediaStore.Audio.Media.RELATIVE_PATH, folder)
                put(MediaStore.Audio.Media.IS_PENDING, 1)
            } else {
                val dir = File(Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_MUSIC), "Sornaz")
                require(dir.exists() || dir.mkdirs())
                put(MediaStore.Audio.Media.DATA, File(dir, "Sornaz_${source.name}").absolutePath)
            }
        }
        val uri = resolver.insert(collection, values) ?: error("Cannot create public recording")
        try {
            val output = resolver.openOutputStream(uri) ?: error("Cannot open public recording")
            output.use { sink -> source.inputStream().use { input -> input.copyTo(sink) } }
            if (Build.VERSION.SDK_INT >= 29) resolver.update(uri, ContentValues().apply { put(MediaStore.Audio.Media.IS_PENDING, 0) }, null, null)
            return uri.toString()
        } catch (e: Exception) { resolver.delete(uri, null, null); throw e }
    }
}
