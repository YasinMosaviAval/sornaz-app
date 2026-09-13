package com.example.sornaz
import android.media.MediaMetadataRetriever
import android.media.MediaExtractor
import android.media.MediaFormat
import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.util.concurrent.Executors

class MusicMetadata(messenger:BinaryMessenger) {
 private val worker=Executors.newSingleThreadExecutor()
 private val main=Handler(Looper.getMainLooper())
 init { MethodChannel(messenger,"sornaz/music_metadata").setMethodCallHandler { call,result ->
  if(call.method!="read"){result.notImplemented();return@setMethodCallHandler}
  worker.execute {
   try {
    val path=call.argument<String>("path")?:error("Missing file")
    require(File(path).isFile)
    val details=linkedMapOf<String,String>()
    val retriever=MediaMetadataRetriever()
    try { retriever.setDataSource(path)
     val keys=mapOf("title" to 7,"artist" to 2,"album" to 1,"albumArtist" to 13,"author" to 3,"composer" to 4,"date" to 5,"genre" to 6,"year" to 8,"track" to 0,"disc" to 14,"writer" to 11,"compilation" to 15,"bitrate" to 20,"mime" to 12,"durationMs" to 9,"tracks" to 10,"sampleRate" to 38,"bitsPerSample" to 39)
     for((name,key)in keys){try{retriever.extractMetadata(key)?.takeIf{it.isNotBlank()}?.let{details[name]=it}}catch(_:Exception){}}
    }finally{retriever.release()}
    val extractor=MediaExtractor()
    try { extractor.setDataSource(path)
     for(i in 0 until extractor.trackCount){val format=extractor.getTrackFormat(i);if(format.getString(MediaFormat.KEY_MIME)?.startsWith("audio/")==true){
      for((name,key)in mapOf("codec" to MediaFormat.KEY_MIME,"channels" to MediaFormat.KEY_CHANNEL_COUNT,"sampleRate" to MediaFormat.KEY_SAMPLE_RATE,"bitrate" to MediaFormat.KEY_BIT_RATE)){if(format.containsKey(key))details[name]=if(key==MediaFormat.KEY_MIME)format.getString(key)!! else format.getInteger(key).toString()}
      break
     }}
    }catch(_:Exception){}finally{extractor.release()}
    main.post{result.success(details)}
   }catch(_:Exception){main.post{result.success(emptyMap<String,String>())}}
  }
 }}
}
