package com.example.sornaz
import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.os.Handler
import android.os.Looper
import android.provider.DocumentsContract
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import org.json.JSONObject
import java.io.File
import java.util.concurrent.Executors

/** A user-selected tree, or the shared root Sornaz/Music Sheets folder. */
class NotationStorage(private val activity:Activity,messenger:BinaryMessenger) {
 private val worker=Executors.newSingleThreadExecutor()
 private val main=Handler(Looper.getMainLooper())
 private val prefs=activity.getSharedPreferences("notation_workspace",0)
 private val defaultFolder get()=File(Environment.getExternalStorageDirectory(),"Sornaz/Music Sheets")
 private var pending:((Boolean)->Unit)?=null
 private var defaultSelection=false
 init { MethodChannel(messenger,"sornaz/notation_storage").setMethodCallHandler { call,result ->
  when(call.method){
   "sdk"->result.success(Build.VERSION.SDK_INT)
   "location"->result.success(location())
   "choose"->choose(false){ok->if(ok)result.success(location())else result.success(null)}
   "save","pdf"->{
    val name=call.argument<String>("name")?:"score"
    val content=call.argument<String>(if(call.method=="pdf")"html" else "content")?:""
    if(content.toByteArray().size>(if(call.method=="pdf")8000000 else 300000)){result.error("NOTATION_STORAGE","File is too large.",null);return@setMethodCallHandler}
    if(call.method=="save"&&runCatching{JSONObject(content).optString("format")}.getOrNull()!="sornaz-notation"){result.error("NOTATION_STORAGE","Invalid music sheet.",null);return@setMethodCallHandler}
    if(call.method=="pdf"){
     NotationPdf(activity).open(content,name,{result.success("print-dialog")},{result.error("NOTATION_STORAGE","Could not open PDF export.",null)})
     return@setMethodCallHandler
    }
    ensure { ok ->
     if(!ok){result.error("NOTATION_STORAGE","No folder was selected.",null)}
     else write(name,content.toByteArray(Charsets.UTF_8),"application/json",result)
    }
   }
   else->result.notImplemented()
  }
 }}
 private fun location():String {val tree=prefs.getString("directory",null)?:return "Sornaz/Music Sheets";return runCatching{DocumentsContract.getDocumentId(Uri.parse(tree)).replaceFirst("primary:","")}.getOrDefault(tree)}
 private fun ensure(done:(Boolean)->Unit){
  val tree=prefs.getString("tree",null)
  if(tree!=null){done(true);return}
  val direct=Build.VERSION.SDK_INT<30||Environment.isExternalStorageManager()
  if(direct&&runCatching{defaultFolder.mkdirs();defaultFolder.isDirectory&&defaultFolder.canWrite()}.getOrDefault(false)){done(true);return}
  choose(true,done)
 }
 private fun choose(forDefault:Boolean,done:(Boolean)->Unit){
  if(pending!=null){done(false);return};pending=done;defaultSelection=forDefault
  val intent=Intent(Intent.ACTION_OPEN_DOCUMENT_TREE).addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION or Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION)
  if(Build.VERSION.SDK_INT>=26)intent.putExtra(DocumentsContract.EXTRA_INITIAL_URI,Uri.parse("content://com.android.externalstorage.documents/document/primary%3ASornaz%2FMusic%20Sheets"))
  try{activity.startActivityForResult(intent,8217)}catch(_:Exception){pending=null;done(false)}
 }
 fun onResult(request:Int,code:Int,data:Intent?):Boolean{
  if(request!=8217)return false
  val callback=pending;pending=null;val selected=data?.data
  if(code!=Activity.RESULT_OK||selected==null){callback?.invoke(false);return true}
  try{
   activity.contentResolver.takePersistableUriPermission(selected,data.flags and (Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION))
   var directory=DocumentsContract.buildDocumentUriUsingTree(selected,DocumentsContract.getTreeDocumentId(selected))
   if(defaultSelection&&DocumentsContract.getTreeDocumentId(selected).substringAfterLast('/').substringAfterLast(':')=="Sornaz"){
    val children=DocumentsContract.buildChildDocumentsUriUsingTree(selected,DocumentsContract.getTreeDocumentId(selected));var existing:Uri?=null
    activity.contentResolver.query(children,arrayOf(DocumentsContract.Document.COLUMN_DOCUMENT_ID,DocumentsContract.Document.COLUMN_DISPLAY_NAME),null,null,null)?.use{c->while(c.moveToNext())if(c.getString(1)=="Music Sheets")existing=DocumentsContract.buildDocumentUriUsingTree(selected,c.getString(0))}
    directory=existing?:DocumentsContract.createDocument(activity.contentResolver,directory,DocumentsContract.Document.MIME_TYPE_DIR,"Music Sheets")?:error("Folder")
   }
   prefs.edit().putString("tree",selected.toString()).putString("directory",directory.toString()).apply();callback?.invoke(true)
  }catch(_:Exception){callback?.invoke(false)}
  return true
 }
 private fun write(rawName:String,bytes:ByteArray,mime:String,result:MethodChannel.Result){worker.execute{
  try{
   val extension=if(mime=="application/pdf")"pdf" else "json"
   val name=rawName.substringBeforeLast('.',rawName).replace(Regex("[^\\p{L}\\p{N} _-]"),"").take(80).ifBlank{"score"}+"."+extension
   val directory=prefs.getString("directory",null)
   val saved=if(directory!=null){
    val uri=DocumentsContract.createDocument(activity.contentResolver,Uri.parse(directory),mime,name)?:error("File")
    try{activity.contentResolver.openOutputStream(uri,"w")!!.use{it.write(bytes)}}catch(e:Exception){DocumentsContract.deleteDocument(activity.contentResolver,uri);throw e};uri.toString()
   }else{
    val folder=defaultFolder.canonicalFile;require(folder.isDirectory)
    var file=File(folder,name).canonicalFile;require(file.parentFile==folder)
    if(file.exists())file=File(folder,name.substringBeforeLast('.')+"-"+System.currentTimeMillis()+"."+extension)
    file.writeBytes(bytes);file.absolutePath
   }
   main.post{result.success(saved)}
  }catch(_:Exception){main.post{result.error("NOTATION_STORAGE","Could not save the music sheet.",null)}}
 }}
}
