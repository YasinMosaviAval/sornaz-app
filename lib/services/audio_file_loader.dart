import 'dart:io';
import 'dart:isolate';
import 'package:sornaz/classes/audio_file.dart';
import 'package:sornaz/classes/scan_progress.dart';
import 'package:sornaz/services/audio_scan_cache_service.dart';
import 'package:sornaz/services/audio_scan_isolate.dart';

typedef ScanProgress = void Function(int scanned, int total);
class AudioFileLoader {

  static Future<void> scanWithIsolate({
    required List<Directory> roots,
    required Function(ScanStatus) onProgress,
    required Function(List<AudioFile>) onDone,
  }) async {

    final receivePort = ReceivePort();
    final isolate = await Isolate.spawn(
      scanAudioIsolate,
      {
        'sendPort': receivePort.sendPort,
        'roots': roots.map((e) => e.path).toList(),
      },
    );

    final cache = await ScanCacheService.loadCache();
    final List<AudioFile> results = [];

    receivePort.listen((msg) async {
      if (msg['done'] == true) {
        await ScanCacheService.saveCache({
          for (var f in results)
            f.file.path: f.file.lastModifiedSync().millisecondsSinceEpoch,
        });

        isolate.kill();
        onDone(results);
        return;
      }

      final scanned = msg['scanned'];
      final total = msg['total'];
      final path = msg['path'];

      onProgress(ScanStatus(
        scanned: scanned,
        total: total,
        currentPath: path,
      ));

      final modified = File(path).lastModifiedSync().millisecondsSinceEpoch;
      if (cache[path] == modified) return;

      results.add(AudioFile(File(path), Duration.zero));
    });
  }
}
