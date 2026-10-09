import 'dart:io';
import 'dart:async';
import 'dart:isolate';
import 'package:path/path.dart' as p;
import 'package:sornaz/helpers/app_constants.dart';
import 'scan_progress.dart';
import 'audio_file.dart';

class AudioFileLoader {
  static Future<void> scanWithIsolate({
    // required BuildContext context,
    required List<Directory> roots,
    required Function(ScanStatus) onProgress,
    required FutureOr<void> Function(List<AudioFile>) onDone,
  }) async {
    final receivePort = ReceivePort();

    // await Isolate.spawn(_scanIsolate as void Function(List<Object> message), [receivePort.sendPort, roots]);
    try {
      await Isolate.spawn(_scanIsolate, [receivePort.sendPort, roots]);
      await for (final message in receivePort) {
        if (message is ScanStatus) {
          onProgress(message);
        } else if (message is List<AudioFile>) {
          await onDone(message);
          break;
        }
      }
    } finally {
      receivePort.close();
    }
  }

  static bool _isAudioFile(FileSystemEntity file) {
    final ext = file.path.split('.').last.toLowerCase();
    return [
      AppConstants.MP3,
      AppConstants.WAV,
      AppConstants.AAC,
      AppConstants.M4A,
      AppConstants.FLAC,
      AppConstants.OGG,
    ].contains(ext);
  }

  static void _scanIsolate(List args) async {
    SendPort sendPort = args[0];
    List<Directory> roots = args[1];

    List<AudioFile> files = [];
    int scanned = 0;

    Future<void> scanDirectory(Directory dir, Function(File) onFile) async {
      try {
        await for (var entity in dir.list(
          recursive: false,
          followLinks: false,
        )) {
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

    sendPort.send(
      ScanStatus(scanned: 0, total: 0, currentPath: 'در حال اسکن...'),
    );
    for (var root in roots) {
      if (root.existsSync()) {
        await scanDirectory(root, (file) {
          scanned++;
          files.add(
            AudioFile(
              file: file,
              fileName: p.basename(file.path),
              folderName: file.parent.path,
              duration: Duration.zero,
            ),
          );
          if (scanned % 20 == 0) {
            sendPort.send(
              ScanStatus(scanned: scanned, total: 0, currentPath: file.path),
            );
          }
        });
      }
    }

    sendPort.send(
      ScanStatus(scanned: scanned, total: scanned, currentPath: 'اسکن تمام شد'),
    );
    sendPort.send(files);
  }
}
