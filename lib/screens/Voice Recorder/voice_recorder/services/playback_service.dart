import 'dart:io';
import 'package:audioplayers/audioplayers.dart';

class PlaybackService {
  final AudioPlayer _player = AudioPlayer();
  String? current;

  Future<void> toggle(File file) async {
    if (current == file.path) {
      await _player.stop();
      current = null;
    } else {
      current = file.path;
      await _player.play(DeviceFileSource(file.path));
    }
  }
}
