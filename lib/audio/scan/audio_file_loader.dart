import 'dart:io';
import 'dart:isolate';
import 'package:audioplayers/audioplayers.dart';
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

    // فانکشن helper برای اسکن async recursive
    Future<void> scanDirectory(Directory dir, Function(File) onFile) async {
      await for (var entity in dir.list(recursive: false)) {  // فقط لایه فعلی، recursive رو دستی هندل کن
        if (entity is File && _isAudioFile(entity)) {
          onFile(entity);
        } else if (entity is Directory) {
          await scanDirectory(entity, onFile);  // recursive call async
        }
      }
    }

    // مرحله ۱: شمارش total async (نرم و بدون بلاک)
    for (var root in roots) {
      await scanDirectory(root, (file) {
        total++;
        if (total % 50 == 0) {  // هر ۵۰ فایل آپدیت بفرست برای نرم بودن
          sendPort.send(ScanStatus(scanned: 0, total: total, currentPath: file.path));
        }
      });
    }
    // آپدیت نهایی total
    sendPort.send(ScanStatus(scanned: 0, total: total, currentPath: 'شمارش تکمیل شد'));

    // مرحله ۲: اسکن واقعی فایل‌ها async
    for (var root in roots) {
      await scanDirectory(root, (file) async {
        scanned++;
        Duration fileDuration = Duration.zero;
        try {
          final tempPlayer = AudioPlayer();
          await tempPlayer.setSource(DeviceFileSource(file.path));
          fileDuration = (await tempPlayer.getDuration()) ?? Duration.zero;
          await tempPlayer.dispose(); // مهم: حتما dispose کن تا حافظه نخوره
        } catch (e) {
          // اگر خطا داد (مثلاً فایل خراب)، صفر بذار
          fileDuration = Duration.zero;
        }

        files.add(AudioFile(
          file: file,
          fileName: file.path.split('/').last,
          folderName: file.parent.path,
          duration: fileDuration,
        ));
        if (scanned % 20 == 0 || scanned == total) {  // هر ۲۰ فایل آپدیت بفرست
          sendPort.send(ScanStatus(scanned: scanned, total: total, currentPath: file.path));
        }
      });
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
