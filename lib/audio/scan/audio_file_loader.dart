import 'dart:io';
import 'dart:isolate';
import 'package:sornaz/helpers/app_strings.dart';

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
            duration: Duration.zero,
          ));

          sendPort.send(ScanStatus(scanned: scanned, total: total, currentPath: entity.path));
        }
      }
    }

    sendPort.send(files);
  }

  static bool _isAudioFile(FileSystemEntity file) {
    final ext = file.path.split('.').last.toLowerCase();
    return [
      AppStrings.file_type_mp3,
      AppStrings.file_type_wav,
      AppStrings.file_type_aac,
      AppStrings.file_type_m4a,
      AppStrings.file_type_flac,
      AppStrings.file_type_ogg
    ].contains(ext);
  }
}
