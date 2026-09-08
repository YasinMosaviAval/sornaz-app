package com.example.sornaz

import android.content.ClipData
import android.content.Intent
import androidx.core.content.FileProvider
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : AudioServiceActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "sornaz/app_share")
            .setMethodCallHandler { call, result ->
                if (call.method == "shareNotation") {
                    try {
                        val file = File(call.argument<String>("path") ?: "").canonicalFile
                        val root = File(cacheDir, "notation-exports").canonicalFile
                        require(file.path.startsWith(root.path + File.separator) && file.isFile && file.extension == "json" && file.length() <= 300000)
                        val uri = FileProvider.getUriForFile(this, "$packageName.apkprovider", file)
                        val intent = Intent(Intent.ACTION_SEND).apply {
                            type = "application/json"
                            putExtra(Intent.EXTRA_STREAM, uri)
                            clipData = ClipData.newRawUri("Sornaz notation", uri)
                            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                        }
                        startActivity(Intent.createChooser(intent, "Sornaz"))
                        result.success(null)
                    } catch (error: Exception) { result.error("SHARE_FAILED", error.message, null) }
                } else if (call.method == "openCourseResource") {
                    try {
                        val file = File(call.argument<String>("path") ?: "").canonicalFile
                        val root = File(cacheDir, "course-resources").canonicalFile
                        require(file.path.startsWith(root.path + File.separator) && file.isFile)
                        val uri = FileProvider.getUriForFile(this, "$packageName.apkprovider", file)
                        val mime = call.argument<String>("mime") ?: "application/pdf"
                        require(mime in listOf("application/pdf", "application/vnd.openxmlformats-officedocument.wordprocessingml.document"))
                        val intent = Intent(Intent.ACTION_VIEW).setDataAndType(uri, mime).addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                        startActivity(Intent.createChooser(intent, "Sornaz"))
                        result.success(null)
                    } catch (error: Exception) { result.error("OPEN_FAILED", error.message, null) }
                } else if (call.method != "shareApk") {
                    result.notImplemented()
                } else if (!applicationInfo.splitSourceDirs.isNullOrEmpty()) {
                    result.error("SPLIT_INSTALL", "This installation requires multiple APK files.", null)
                } else {
                    Thread {
                        try {
                            val directory = File(cacheDir, "shared-apk").apply { mkdirs() }
                            val apk = File(directory, "sornaz.apk")
                            File(applicationInfo.sourceDir).copyTo(apk, overwrite = true)
                            val uri = FileProvider.getUriForFile(this, "$packageName.apkprovider", apk)
                            val intent = Intent(Intent.ACTION_SEND).apply {
                                type = "application/vnd.android.package-archive"
                                putExtra(Intent.EXTRA_STREAM, uri)
                                clipData = ClipData.newRawUri("Sornaz APK", uri)
                                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                            }
                            runOnUiThread {
                                try {
                                    startActivity(Intent.createChooser(intent, "ارسال فایل نصب سرناز"))
                                    result.success(null)
                                } catch (error: Exception) {
                                    result.error("SHARE_FAILED", error.message, null)
                                }
                            }
                        } catch (error: Exception) {
                            runOnUiThread { result.error("SHARE_FAILED", error.message, null) }
                        }
                    }.start()
                }
            }
    }
}
