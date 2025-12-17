import 'dart:io';
import 'dart:isolate';
import 'scan_progress.dart';
import 'audio_file.dart';

class AudioFileLoader {
  static Future<void> scanWithIsolate({
    required List<Directory> roots,
    required Function(ScanStatus) onProgress,
    required Function(List<AudioFile>) onDone,
  }) async {
    final receivePort = ReceivePort();
    
    await Isolate.spawn(_scanIsolate, [receivePort.sendPort, roots]);
    
    receivePort.listen((message) {
      if (message is ScanStatus) {
        onProgress(message);
      } else if (message is List<AudioFile>) {
        onDone(message);
        receivePort.close();
      }
    });
  }

  static void _scanIsolate(List args) async {
    SendPort sendPort = args[0];
    List<Directory> roots = args[1];

    List<AudioFile> files = [];
    int scanned = 0;
    int total = 0;

    // شمارش اولیه
    for (var dir in roots) {
      total += dir.listSync(recursive: true).where((f) => f is File && _isAudioFile(f)).length;
    }

    for (var dir in roots) {
      final entities = dir.listSync(recursive: true);
      for (var entity in entities) {
        if (entity is File && _isAudioFile(entity)) {
          scanned++;
          files.add(AudioFile(
            file: entity,
            fileName: entity.path.split('/').last,
            folderName: entity.parent.path,
            duration: Duration.zero, // بعداً با metadata پر می‌شود
          ));

          sendPort.send(ScanStatus(scanned: scanned, total: total, currentPath: entity.path));
        }
      }
    }

    sendPort.send(files);
  }

  static bool _isAudioFile(FileSystemEntity file) {
    final ext = file.path.split('.').last.toLowerCase();
    return ['mp3','wav','aac','m4a','flac','ogg'].contains(ext);
  }
}


/*
import 'dart:io';
import 'dart:isolate';
import 'package:sornaz/audio/scan/audio_file.dart';
import 'package:sornaz/classes/scan_progress.dart';
import 'package:sornaz/services/audio_scan_cache_service.dart';
import 'package:sornaz/services/audio_scan_isolate.dart';

class AudioFileLoader {

  static Future<void> scanWithIsolate({
    required List<Directory> roots,
    required Function(ScanStatus) onProgress,
    required Function(List<AudioFile>) onDone,
  }) async {

    final receivePort = ReceivePort();

    // 1️⃣ راه‌اندازی isolate
    final isolate = await Isolate.spawn(
      scanAudioIsolate,
      {
        'sendPort': receivePort.sendPort,
        'roots': roots.map((e) => e.path).toList(),
      },
    );

    // 2️⃣ بارگذاری cache
    final cache = await ScanCacheService.loadCache();
    final List<AudioFile> results = [];

    // 3️⃣ دریافت پیام‌ها از isolate
    receivePort.listen((msg) async {
      if (msg['done'] == true) {
        // ذخیره cache
        await ScanCacheService.saveCache({
          for (var f in results)
            f.file.path: f.file.lastModifiedSync().millisecondsSinceEpoch,
        });

        isolate.kill();
        onDone(results);
        return;
      }

      // پیام progress
      final scanned = msg['scanned'] as int;
      final total = msg['total'] as int;
      final path = msg['path'] as String;

      // اطلاع‌رسانی به provider
      onProgress(ScanStatus(
        scanned: scanned,
        total: total,
        currentPath: path,
      ));

      // بررسی cache
      final modified = File(path).lastModifiedSync().millisecondsSinceEpoch;
      if (cache[path] == modified) return;

      results.add(AudioFile(File(path), Duration.zero));
    });
  }
}
*/
