package com.example.sornaz

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.provider.DocumentsContract
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

class RecordingWorkspace(private val activity: Activity, messenger: BinaryMessenger) {
    private var pending: MethodChannel.Result? = null
    private val prefs = activity.getSharedPreferences("recording_workspace", 0)
    init {
        MethodChannel(messenger, "sornaz/recording_workspace").setMethodCallHandler { call, result ->
            when(call.method) {
                "location" -> result.success(prefs.getString("tree", null) ?: "Music/Sornaz")
                "choose" -> {
                    if (pending != null) { result.error("BUSY", "Folder selection is already open", null) }
                    else {
                        pending = result
                        activity.startActivityForResult(Intent(Intent.ACTION_OPEN_DOCUMENT_TREE).addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION or Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION), 8206)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }
    fun onResult(request: Int, code: Int, data: Intent?): Boolean {
        if (request != 8206) return false
        val callback = pending; pending = null
        val uri = data?.data
        if (code != Activity.RESULT_OK || uri == null) { callback?.success(null); return true }
        try {
            activity.contentResolver.takePersistableUriPermission(uri, data.flags and (Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION))
            val roots = (prefs.getStringSet("trees", emptySet()) ?: emptySet()).toMutableSet()
            roots.add(uri.toString())
            prefs.edit().putString("tree", uri.toString()).putStringSet("trees", roots).apply()
            callback?.success(uri.toString())
        } catch (e: Exception) { callback?.error("FOLDER", "Could not access folder", null) }
        return true
    }
    companion object {
        fun list(context: android.content.Context): List<Map<String, Any>> {
            val roots = context.getSharedPreferences("recording_workspace", 0).getStringSet("trees", emptySet()) ?: emptySet()
            val result = mutableListOf<Map<String, Any>>()
            for (root in roots) {
                val tree = Uri.parse(root)
                try {
                    val children = DocumentsContract.buildChildDocumentsUriUsingTree(tree, DocumentsContract.getTreeDocumentId(tree))
                    context.contentResolver.query(children, arrayOf(DocumentsContract.Document.COLUMN_DOCUMENT_ID, DocumentsContract.Document.COLUMN_DISPLAY_NAME, DocumentsContract.Document.COLUMN_LAST_MODIFIED), null, null, null)?.use { cursor ->
                        while(cursor.moveToNext()) {
                            val name = cursor.getString(1)
                            if (name.endsWith(".m4a") && name.startsWith("Sornaz_")) result.add(mapOf("uri" to DocumentsContract.buildDocumentUriUsingTree(tree, cursor.getString(0)).toString(), "name" to name, "modified" to cursor.getLong(2)))
                        }
                    }
                } catch (_: Exception) { }
            }
            return result
        }
    }
}
