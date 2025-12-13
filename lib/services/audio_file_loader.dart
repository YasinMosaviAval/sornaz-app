import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:sornaz/classes/audio_file.dart';

class AudioFileLoader {
  // انتخاب پوشه
  static Future<String?> pickDirectory() async {
    return await FilePicker.platform.getDirectoryPath();
  }

  // لود فایل‌ها با duration واقعی و async
  static Future<List<AudioFile>> loadFromDirectory(Directory dir) async {
    List<AudioFile> list = [];

    await for (final entity in dir.list(recursive: true, followLinks: false)) {
      if (entity is File && _isAudio(entity.path)) {
        try {
          final temp = AudioPlayer();
          await temp.setSource(DeviceFileSource(entity.path));
          final dur = await temp.getDuration() ?? Duration.zero;
          await temp.dispose();

          list.add(AudioFile(entity, dur));
        } catch (_) {
          // اگر خطایی در گرفتن duration بود، فایل را با Duration.zero اضافه کن
          list.add(AudioFile(entity, Duration.zero));
        }
      }
    }

    return list;
  }

  // بررسی پسوند
  static bool _isAudio(String p) {
    final x = p.toLowerCase();
    return x.endsWith('.mp3') || x.endsWith('.wav') || x.endsWith('.m4a');
  }
}
