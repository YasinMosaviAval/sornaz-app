package com.example.sornaz
import android.app.Activity
import android.content.Context
import android.os.Bundle
import android.os.CancellationSignal
import android.os.ParcelFileDescriptor
import android.print.PageRange
import android.print.PrintAttributes
import android.print.PrintDocumentAdapter
import android.print.PrintManager
import android.webkit.WebView
import android.webkit.WebViewClient

/** Android's print framework preserves SVG vectors and offers Save as PDF. */
class NotationPdf(private val activity:Activity){
 fun open(html:String,name:String,success:()->Unit,failure:()->Unit){
  val web=WebView(activity);var started=false
  web.settings.allowFileAccess=true
  web.settings.blockNetworkLoads=true
  web.webViewClient=object:WebViewClient(){
   override fun onPageFinished(view:WebView,url:String){
    if(started)return;started=true
    try{
     val original=view.createPrintDocumentAdapter(name)
     val adapter=object:PrintDocumentAdapter(){
      override fun onStart(){original.onStart()}
      override fun onLayout(old:PrintAttributes?,new:PrintAttributes?,signal:CancellationSignal?,callback:LayoutResultCallback?,extras:Bundle?){original.onLayout(old,new,signal,callback,extras)}
      override fun onWrite(pages:Array<PageRange>?,output:ParcelFileDescriptor?,signal:CancellationSignal?,callback:WriteResultCallback?){original.onWrite(pages,output,signal,callback)}
      override fun onFinish(){try{original.onFinish()}finally{web.destroy()}}
     }
     val attributes=PrintAttributes.Builder().setMediaSize(PrintAttributes.MediaSize.ISO_A4).setResolution(PrintAttributes.Resolution("pdf","PDF",300,300)).setMinMargins(PrintAttributes.Margins.NO_MARGINS).build()
     (activity.getSystemService(Context.PRINT_SERVICE) as PrintManager).print(name.removeSuffix(".pdf"),adapter,attributes)
     success()
    }catch(_:Exception){web.destroy();failure()}
   }
  }
  web.loadDataWithBaseURL("file:///android_asset/flutter_assets/assets/notation/",html,"text/html","UTF-8",null)
 }
}
