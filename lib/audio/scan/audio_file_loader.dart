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

  static void _scanIsolate(List args) async {
    SendPort sendPort = args[0];
    List<Directory> roots = args[1];

    List<AudioFile> files = [];
    int scanned = 0;
    int total = 0;

    Future<void> scanDirectory(Directory dir, Function(File) onFile) async {
      try {
        await for (var entity in dir.list(recursive: false)) {
          if (entity is Directory) {
            await scanDirectory(entity, onFile);
          } else if (entity is File && _isAudioFile(entity)) {
            onFile(entity);
          }
        }
      } catch (e) {
        // Catch Error
      }
    }

    sendPort.send(ScanStatus(scanned: 0, total: 0, currentPath: 'در حال شمارش...'));
    for (var root in roots) {
      if (root.existsSync()) {
        await scanDirectory(root, (file) {
          total++;
          if (total % 50 == 0) {
            sendPort.send(ScanStatus(scanned: 0, total: total, currentPath: file.path));
          }
        });
      }
    }

    sendPort.send(ScanStatus(scanned: 0, total: total, currentPath: 'شمارش تمام شد'));
    if (total == 0) {
      sendPort.send(files);
      return;
    }

    for (var root in roots) {
      if (root.existsSync()) {
        await scanDirectory(root, (file) {
          scanned++;
          files.add(AudioFile(
            file: file,
            fileName: file.path.split('/').last,
            folderName: file.parent.path,
            duration: Duration.zero,
          ));
          if (scanned % 20 == 0 || scanned == total) {
            sendPort.send(ScanStatus(scanned: scanned, total: total, currentPath: file.path));
          }
        });
      }
    }

    sendPort.send(files);
  }
}
