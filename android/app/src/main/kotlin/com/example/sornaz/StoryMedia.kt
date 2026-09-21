package com.example.sornaz

import android.Manifest
import android.app.Activity
import android.content.ContentUris
import android.content.ContentValues
import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.media.MediaMetadataRetriever
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import android.provider.DocumentsContract
import android.media.MediaScannerConnection
import androidx.core.content.FileProvider
import androidx.media3.common.MediaItem
import androidx.media3.common.MimeTypes
import androidx.media3.effect.BitmapOverlay
import androidx.media3.effect.OverlayEffect
import androidx.media3.effect.TextureOverlay
import androidx.media3.effect.Presentation
import androidx.media3.transformer.*
import com.google.common.collect.ImmutableList
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.io.File
import java.util.UUID
import java.util.concurrent.Executors

/** Drafts remain private; explicit saves go to Sornaz/Media/Stories. */
@androidx.annotation.OptIn(androidx.media3.common.util.UnstableApi::class)
class StoryMedia(private val activity: Activity, messenger: BinaryMessenger) {
    private val root = File(activity.cacheDir, "story-drafts").apply { mkdirs() }
    private val worker = Executors.newFixedThreadPool(2)
    private var pending: MethodChannel.Result? = null
    private var cameraFile: File? = null
    private var transformer: Transformer? = null
    private var exportResult: MethodChannel.Result? = null
    private var exportFile: File? = null
    init {
        root.listFiles()?.filter { it.isFile }?.forEach { it.delete() }
        MethodChannel(messenger, "sornaz/story_media").setMethodCallHandler { call, result ->
            when(call.method) {
                "permission" -> permission(result)
                "savePermission" -> savePermission(result)
                "camera" -> camera(result)
                "exportVideo" -> exportVideo(call,result)
                else -> worker.execute {
                    try {
                        val value: Any? = when(call.method) {
                            "gallery" -> gallery(call.argument<Int>("offset") ?: 0)
                            "thumbnail" -> thumbnail(Uri.parse(call.argument<String>("uri")), call.argument<Boolean>("video") == true, call.argument<Int>("timeMs") ?: 0, call.argument<Int>("size") ?: 240)
                            "select" -> select(Uri.parse(call.argument<String>("uri")), call.argument<Boolean>("video") == true)
                            "writeImage" -> draft("png").also { it.writeBytes(call.argument<ByteArray>("bytes")!!) }.let { info(it,false) }
                            "save" -> save(privateFile(call.argument<String>("path")!!),call.argument<Boolean>("video")==true)
                            "delete" -> { (call.argument<List<String>>("paths") ?: emptyList()).forEach { privateFile(it).delete() }; null }
                            else -> throw IllegalArgumentException("Unsupported operation")
                        }
                        activity.runOnUiThread { result.success(value) }
                    } catch (_: Exception) { activity.runOnUiThread { result.error("STORY_MEDIA", "Media operation failed", null) } }
                }
            }
        }
    }
    private fun draft(extension: String) = File(root,"${UUID.randomUUID()}.$extension")
    private fun privateFile(path: String): File {
        val f=File(path).canonicalFile
        require(f.parentFile == root.canonicalFile && f.isFile)
        return f
    }
    private fun info(f:File,video:Boolean): Map<String,Any> = mapOf("path" to f.path,"uri" to FileProvider.getUriForFile(activity,"${activity.packageName}.apkprovider",f).toString(),"video" to video,"size" to f.length(),"name" to f.name)
    private fun permission(result: MethodChannel.Result) {
        if(pending!=null){result.error("BUSY","An operation is pending",null);return}
        val permissions=if(Build.VERSION.SDK_INT>=33) arrayOf(Manifest.permission.READ_MEDIA_IMAGES,Manifest.permission.READ_MEDIA_VIDEO) else arrayOf(Manifest.permission.READ_EXTERNAL_STORAGE)
        if(permissions.all { activity.checkSelfPermission(it)==PackageManager.PERMISSION_GRANTED }) {result.success("full");return}
        pending=result
        activity.requestPermissions(if(Build.VERSION.SDK_INT>=34) permissions+Manifest.permission.READ_MEDIA_VISUAL_USER_SELECTED else permissions,7421)
    }
    fun permissions(code:Int):Boolean {
        if(code!=7421 && code!=7422 && code!=7424)return false
        val r=pending ?: return true;pending=null
        if(code==7424){r.success(activity.checkSelfPermission(Manifest.permission.WRITE_EXTERNAL_STORAGE)==PackageManager.PERMISSION_GRANTED);return true}
        if(code==7422) { if(activity.checkSelfPermission(Manifest.permission.CAMERA)==PackageManager.PERMISSION_GRANTED)camera(r) else r.success(null);return true }
        val full=if(Build.VERSION.SDK_INT>=33) activity.checkSelfPermission(Manifest.permission.READ_MEDIA_IMAGES)==PackageManager.PERMISSION_GRANTED && activity.checkSelfPermission(Manifest.permission.READ_MEDIA_VIDEO)==PackageManager.PERMISSION_GRANTED else activity.checkSelfPermission(Manifest.permission.READ_EXTERNAL_STORAGE)==PackageManager.PERMISSION_GRANTED
        val partial=Build.VERSION.SDK_INT>=34 && activity.checkSelfPermission(Manifest.permission.READ_MEDIA_VISUAL_USER_SELECTED)==PackageManager.PERMISSION_GRANTED
        r.success(if(full)"full" else if(partial)"limited" else "denied");return true
    }
    private fun gallery(offset:Int):List<Map<String,Any>> {
        val rows=mutableListOf<Map<String,Any>>()
        val base=MediaStore.Files.getContentUri("external")
        val cols=arrayOf("_id","media_type","duration")
        activity.contentResolver.query(base,cols,"media_type IN (1,3)",null,"date_added DESC, _id DESC")?.use { c ->
            if(c.moveToPosition(offset.coerceAtLeast(0))) do {
                val video=c.getInt(1)==3
                val uri=ContentUris.withAppendedId(if(video) MediaStore.Video.Media.EXTERNAL_CONTENT_URI else MediaStore.Images.Media.EXTERNAL_CONTENT_URI,c.getLong(0))
                rows.add(mapOf("uri" to uri.toString(),"video" to video,"duration" to c.getLong(2)))
            } while(rows.size<60 && c.moveToNext())
        };return rows
    }
    private fun thumbnail(uri:Uri,video:Boolean,timeMs:Int,size:Int):ByteArray {
        val edge=size.coerceIn(96,1440)
        val bitmap:Bitmap = if(video) MediaMetadataRetriever().let { r ->
            try { r.setDataSource(activity,uri); r.getFrameAtTime(timeMs.toLong()*1000,MediaMetadataRetriever.OPTION_CLOSEST) ?: error("No frame") } finally {r.release()}
        } else if(Build.VERSION.SDK_INT>=28) {
            android.graphics.ImageDecoder.decodeBitmap(android.graphics.ImageDecoder.createSource(activity.contentResolver,uri)) { d,i,_ ->
                val scale=edge.toFloat()/maxOf(i.size.width,i.size.height)
                if(scale<1)d.setTargetSize((i.size.width*scale).toInt().coerceAtLeast(1),(i.size.height*scale).toInt().coerceAtLeast(1))
                d.allocator=android.graphics.ImageDecoder.ALLOCATOR_SOFTWARE
            }
        } else {
            val options=BitmapFactory.Options().apply { inJustDecodeBounds=true }
            activity.contentResolver.openInputStream(uri)?.use { BitmapFactory.decodeStream(it,null,options) }
            options.inSampleSize=1;while(maxOf(options.outWidth,options.outHeight)/options.inSampleSize>edge*2)options.inSampleSize*=2
            options.inJustDecodeBounds=false
            activity.contentResolver.openInputStream(uri)?.use { BitmapFactory.decodeStream(it,null,options) } ?: error("No image")
        }
        val scale=minOf(1f,edge.toFloat()/maxOf(bitmap.width,bitmap.height))
        val small=if(scale<1)Bitmap.createScaledBitmap(bitmap,(bitmap.width*scale).toInt().coerceAtLeast(1),(bitmap.height*scale).toInt().coerceAtLeast(1),true) else bitmap
        return ByteArrayOutputStream().use { out -> small.compress(Bitmap.CompressFormat.PNG,100,out);val bytes=out.toByteArray();if(small!==bitmap)small.recycle();bitmap.recycle();bytes }
    }
    private fun select(uri:Uri,video:Boolean):Map<String,Any> {
        val file=draft(if(video)"mp4" else "image")
        try {
            activity.contentResolver.openInputStream(uri)!!.use { input -> file.outputStream().use { out ->
                val buffer=ByteArray(65536);var total=0L
                while(true){val n=input.read(buffer);if(n<0)break;total+=n;require(total<=100L*1024*1024);out.write(buffer,0,n)}
            } }
            return info(file,video)
        } catch(e:Exception){file.delete();throw e}
    }
    private fun camera(result:MethodChannel.Result) {
        if(pending!=null){result.error("BUSY","An operation is pending",null);return}
        if(activity.checkSelfPermission(Manifest.permission.CAMERA)!=PackageManager.PERMISSION_GRANTED){pending=result;activity.requestPermissions(arrayOf(Manifest.permission.CAMERA),7422);return}
        val file=draft("jpg");cameraFile=file;pending=result
        try {
            val uri=FileProvider.getUriForFile(activity,"${activity.packageName}.apkprovider",file)
            val intent=Intent(MediaStore.ACTION_IMAGE_CAPTURE).putExtra(MediaStore.EXTRA_OUTPUT,uri).addFlags(Intent.FLAG_GRANT_WRITE_URI_PERMISSION or Intent.FLAG_GRANT_READ_URI_PERMISSION)
            intent.clipData=android.content.ClipData.newRawUri("Story camera",uri)
            activity.startActivityForResult(intent,7423)
        }catch(_:Exception){pending=null;cameraFile=null;file.delete();result.error("CAMERA","Camera unavailable",null)}
    }
    fun onResult(code:Int,resultCode:Int,data:Intent? = null):Boolean {
        if (code == 7425) {
            val result = pending; pending = null
            val uri = data?.data
            if (resultCode != Activity.RESULT_OK || uri == null) { result?.success(false); return true }
            try {
                require(DocumentsContract.getTreeDocumentId(uri) == "primary:Sornaz") { "Select the Sornaz folder in internal storage" }
                activity.contentResolver.takePersistableUriPermission(uri, Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION)
                activity.getSharedPreferences("story_storage", 0).edit().putString("tree", uri.toString()).apply()
                result?.success(true)
            } catch (e: Exception) { result?.error("STORY_FOLDER", e.message, null) }
            return true
        }
        if(code!=7423)return false
        val f=cameraFile;val r=pending;pending=null;cameraFile=null
        if(resultCode==Activity.RESULT_OK && f!=null && f.length()>0)r?.success(info(f,false)) else {f?.delete();r?.success(null)}
        return true
    }
    private fun directStorage(): Boolean = if (Build.VERSION.SDK_INT >= 30) Environment.isExternalStorageManager()
        else if (Build.VERSION.SDK_INT == 29) Environment.isExternalStorageLegacy() && activity.checkSelfPermission(Manifest.permission.WRITE_EXTERNAL_STORAGE) == PackageManager.PERMISSION_GRANTED
        else activity.checkSelfPermission(Manifest.permission.WRITE_EXTERNAL_STORAGE) == PackageManager.PERMISSION_GRANTED

    private fun savedTree(): Uri? {
        val value = activity.getSharedPreferences("story_storage", 0).getString("tree", null) ?: return null
        val uri = Uri.parse(value)
        return if (activity.contentResolver.persistedUriPermissions.any { it.uri == uri && it.isWritePermission }) uri else null
    }
    private fun savePermission(result: MethodChannel.Result) {
        if (directStorage() || savedTree() != null) { result.success(true); return }
        if (pending != null) { result.error("BUSY", "An operation is pending", null); return }
        pending = result
        if (Build.VERSION.SDK_INT < 29) {
            activity.requestPermissions(arrayOf(Manifest.permission.WRITE_EXTERNAL_STORAGE), 7424)
        } else {
            try {
                val intent = Intent(Intent.ACTION_OPEN_DOCUMENT_TREE).apply {
                    addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION or Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION or Intent.FLAG_GRANT_PREFIX_URI_PERMISSION)
                    putExtra(DocumentsContract.EXTRA_INITIAL_URI, Uri.parse("content://com.android.externalstorage.documents/document/primary%3ASornaz"))
                }
                activity.startActivityForResult(intent, 7425)
            } catch (e: Exception) { pending = null; result.error("STORY_FOLDER", e.message, null) }
        }
    }
    private fun directory(tree: Uri, parent: Uri, name: String): Uri {
        val resolver = activity.contentResolver
        val children = DocumentsContract.buildChildDocumentsUriUsingTree(tree, DocumentsContract.getDocumentId(parent))
        resolver.query(children, arrayOf(DocumentsContract.Document.COLUMN_DOCUMENT_ID, DocumentsContract.Document.COLUMN_DISPLAY_NAME, DocumentsContract.Document.COLUMN_MIME_TYPE), null, null, null)?.use { cursor ->
            while (cursor.moveToNext()) if (cursor.getString(1) == name && cursor.getString(2) == DocumentsContract.Document.MIME_TYPE_DIR) {
                return DocumentsContract.buildDocumentUriUsingTree(tree, cursor.getString(0))
            }
        }
        return DocumentsContract.createDocument(resolver, parent, DocumentsContract.Document.MIME_TYPE_DIR, name) ?: error("Cannot create story folder")
    }
    private fun save(file: File, video: Boolean): String {
        val extension = if (video) "mp4" else "png"
        val mime = if (video) "video/mp4" else "image/png"
        val name = "Sornaz-" + UUID.randomUUID().toString() + "." + extension
        if (directStorage()) {
            val folder = File(Environment.getExternalStorageDirectory(), "Sornaz/Media/Stories")
            check(folder.isDirectory || folder.mkdirs()) { "Cannot create story folder" }
            val output = File(folder, name)
            try { file.inputStream().use { input -> output.outputStream().use { input.copyTo(it) } } }
            catch (e: Exception) { output.delete(); throw e }
            MediaScannerConnection.scanFile(activity, arrayOf(output.absolutePath), arrayOf(mime), null)
            return Uri.fromFile(output).toString()
        }
        val tree = savedTree() ?: error("Choose the Sornaz folder before saving")
        val parent = DocumentsContract.buildDocumentUriUsingTree(tree, DocumentsContract.getTreeDocumentId(tree))
        val folder = directory(tree, directory(tree, parent, "Media"), "Stories")
        val resolver = activity.contentResolver
        val uri = DocumentsContract.createDocument(resolver, folder, mime, name) ?: error("Cannot save story")
        try { resolver.openOutputStream(uri, "w")!!.use { out -> file.inputStream().use { it.copyTo(out) } } }
        catch (e: Exception) { DocumentsContract.deleteDocument(resolver, uri); throw e }
        return uri.toString()
    }
    private fun exportVideo(call:MethodCall,result:MethodChannel.Result) {
        if(transformer!=null){result.error("BUSY","Export in progress",null);return}
        var output:File?=null
        try {
            val source=privateFile(call.argument<String>("path")!!)
            val bytes=call.argument<ByteArray>("overlay")!!
            val raw=BitmapFactory.decodeByteArray(bytes,0,bytes.size) ?: error("Overlay missing")
            val bitmap=if(raw.width%2==0 && raw.height%2==0)raw else Bitmap.createScaledBitmap(raw,raw.width/2*2,raw.height/2*2,true).also{raw.recycle()}
            val out=draft("mp4");output=out;exportFile=out
            val effects=listOf(Presentation.createForWidthAndHeight(bitmap.width,bitmap.height,if(call.argument<Boolean>("cover")==true)Presentation.LAYOUT_SCALE_TO_FIT_WITH_CROP else Presentation.LAYOUT_SCALE_TO_FIT),OverlayEffect(ImmutableList.of<TextureOverlay>(BitmapOverlay.createStaticBitmapOverlay(bitmap))))
            val item=EditedMediaItem.Builder(MediaItem.fromUri(Uri.fromFile(source))).setEffects(Effects(emptyList(),effects)).build()
            exportResult=result
            transformer=Transformer.Builder(activity).setVideoMimeType(MimeTypes.VIDEO_H264).setAudioMimeType(MimeTypes.AUDIO_AAC).addListener(object:Transformer.Listener {
                override fun onCompleted(composition:Composition,export:ExportResult){exportFile=null;transformer=null;exportResult=null;bitmap.recycle();result.success(info(out,true))}
                override fun onError(composition:Composition,export:ExportResult,error:ExportException){exportFile=null;transformer=null;exportResult=null;bitmap.recycle();out.delete();result.error("EXPORT","Video export failed",null)}
            }).build()
            transformer!!.start(item,out.path)
        }catch(_:Exception){output?.delete();exportFile=null;transformer=null;exportResult=null;result.error("EXPORT","Video export failed",null)}
    }
    fun dispose(){transformer?.cancel();exportFile?.delete();exportFile=null;transformer=null;exportResult?.error("CANCELLED","Editor closed",null);exportResult=null;worker.shutdown()}
}
