package com.example.sornaz

import android.app.Activity
import android.os.Bundle
import android.os.CancellationSignal
import android.os.Handler
import android.os.Looper
import android.os.ParcelFileDescriptor
import android.print.NotationLayoutCallback
import android.print.NotationWriteCallback
import android.print.PageRange
import android.print.PrintAttributes
import android.print.PrintDocumentAdapter
import android.print.PrintDocumentInfo
import android.view.View
import android.webkit.WebView
import android.webkit.WebViewClient
import java.io.File

/** Render the vector print document directly, without the system print/save dialog. */
class NotationPdf(private val activity: Activity) {
 fun write(html: String, name: String, success: (File) -> Unit, failure: () -> Unit) {
  val web = WebView(activity)
  val handler = Handler(Looper.getMainLooper())
  val signal = CancellationSignal()
  var adapter: PrintDocumentAdapter? = null
  var output: ParcelFileDescriptor? = null
  var file: File? = null
  var started = false
  var finished = false
  lateinit var timeout: Runnable
  fun finish(ok: Boolean) {
   if (finished) return
   finished = true
   handler.removeCallbacks(timeout)
   signal.cancel()
   runCatching { output?.close() }
   runCatching { adapter?.onFinish() }
   web.destroy()
   val rendered = file
   if (ok && rendered != null && rendered.length() > 0) success(rendered)
   else { rendered?.delete(); failure() }
  }
  timeout = Runnable { finish(false) }
  handler.postDelayed(timeout, 60000)
  fun render() {
   if (finished || activity.isFinishing || activity.isDestroyed) { finish(false); return }
   try {
    val target = File.createTempFile("notation-", ".pdf", activity.cacheDir)
    file = target
    val document = web.createPrintDocumentAdapter(name.removeSuffix(".pdf"))
    adapter = document
    val attributes = PrintAttributes.Builder().setMediaSize(PrintAttributes.MediaSize.ISO_A4)
     .setResolution(PrintAttributes.Resolution("pdf", "PDF", 300, 300))
     .setMinMargins(PrintAttributes.Margins.NO_MARGINS).build()
    document.onStart()
    document.onLayout(null, attributes, signal, object: NotationLayoutCallback() {
     override fun onLayoutFinished(info: PrintDocumentInfo, changed: Boolean) {
      if (finished) return
      try {
       val descriptor = ParcelFileDescriptor.open(target, ParcelFileDescriptor.MODE_READ_WRITE or ParcelFileDescriptor.MODE_TRUNCATE)
       output = descriptor
       document.onWrite(arrayOf(PageRange.ALL_PAGES), descriptor, signal, object: NotationWriteCallback() {
        override fun onWriteFinished(pages: Array<PageRange>) { finish(true) }
        override fun onWriteFailed(error: CharSequence?) { finish(false) }
        override fun onWriteCancelled() { finish(false) }
       })
      } catch (_: Exception) { finish(false) }
     }
     override fun onLayoutFailed(error: CharSequence?) { finish(false) }
     override fun onLayoutCancelled() { finish(false) }
    }, Bundle())
   } catch (_: Exception) { finish(false) }
  }
  fun waitForFonts() {
   if (finished) return
   web.evaluateJavascript("!document.fonts || document.fonts.status === 'loaded'") { ready ->
    if (finished) return@evaluateJavascript
    if (ready == "true") render() else handler.postDelayed({ waitForFonts() }, 50)
   }
  }
  web.settings.javaScriptEnabled = true
  web.settings.allowFileAccess = true
  web.settings.blockNetworkLoads = true
  web.webViewClient = object: WebViewClient() {
   override fun onPageFinished(view: WebView, url: String) {
    if (started || finished) return
    started = true
    handler.postDelayed({ waitForFonts() }, 16)
   }
  }
  val density = activity.resources.displayMetrics.density
  val width = (794 * density).toInt()
  val height = (1123 * density).toInt()
  web.measure(View.MeasureSpec.makeMeasureSpec(width, View.MeasureSpec.EXACTLY), View.MeasureSpec.makeMeasureSpec(height, View.MeasureSpec.EXACTLY))
  web.layout(0, 0, width, height)
  web.loadDataWithBaseURL("file:///android_asset/flutter_assets/assets/notation/", html, "text/html", "UTF-8", null)
 }
}
