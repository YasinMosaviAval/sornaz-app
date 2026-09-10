package com.example.sornaz
import android.content.Context
import android.graphics.Bitmap
import android.graphics.Color
import android.graphics.pdf.PdfRenderer
import android.os.ParcelFileDescriptor
import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.ByteArrayOutputStream
import java.util.concurrent.Executors

class PrivatePdf(context: Context, messenger: BinaryMessenger) {
    private val worker = Executors.newSingleThreadExecutor()
    init {
        MethodChannel(messenger, "sornaz/private_pdf").setMethodCallHandler { call, result ->
            worker.execute {
                try {
                    require(call.method == "render")
                    val file = File(call.argument<String>("path") ?: "").canonicalFile
                    require(file.path.startsWith(context.cacheDir.canonicalPath + File.separator) && file.parentFile?.name?.startsWith("sornaz-playback-") == true)
                    PdfRenderer(ParcelFileDescriptor.open(file, ParcelFileDescriptor.MODE_READ_ONLY)).use { renderer ->
                        renderer.openPage(call.argument<Int>("page") ?: 0).use { page ->
                            val width = 1200
                            val bitmap = Bitmap.createBitmap(width, (page.height.toDouble() * width / page.width).toInt().coerceIn(1, 2400), Bitmap.Config.ARGB_8888)
                            bitmap.eraseColor(Color.WHITE)
                            page.render(bitmap, null, null, PdfRenderer.Page.RENDER_MODE_FOR_DISPLAY)
                            val bytes = ByteArrayOutputStream(); bitmap.compress(Bitmap.CompressFormat.PNG, 100, bytes); bitmap.recycle()
                            val output = mapOf("bytes" to bytes.toByteArray(), "count" to renderer.pageCount)
                            Handler(Looper.getMainLooper()).post { result.success(output) }
                        }
                    }
                } catch (_: Exception) { Handler(Looper.getMainLooper()).post { result.error("PDF", "Could not display document", null) } }
            }
        }
    }
}
