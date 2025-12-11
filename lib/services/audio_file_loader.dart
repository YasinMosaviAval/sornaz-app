import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:sornaz/classes/audio_file.dart';

class AudioFileLoader {
  static Future<List<AudioFile>> loadFromPicker() async {
    final result = await FilePicker.platform.getDirectoryPath();
    if (result == null) return [];

    final dir = Directory(result);
    final entities = await dir.list(recursive: true).toList();

    List<AudioFile> list = [];

    for (var e in entities) {
      if (e is File && _isAudio(e.path)) {
        final temp = AudioPlayer();
        await temp.setSource(DeviceFileSource(e.path));
        final dur = await temp.getDuration() ?? Duration.zero;
        await temp.dispose();

        list.add(AudioFile(e, dur));
      }
    }
    return list;
  }

  static bool _isAudio(String p) {
    final x = p.toLowerCase();
    return x.endsWith('.mp3') || x.endsWith('.wav') || x.endsWith('.m4a');
  }
}
