import 'dart:io';
import 'dart:isolate';
import 'package:sornaz/classes/audio_file.dart';
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
