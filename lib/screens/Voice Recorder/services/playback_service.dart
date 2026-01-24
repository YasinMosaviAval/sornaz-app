import 'dart:io';
import 'package:audioplayers/audioplayers.dart';

class PlaybackService {
  final AudioPlayer _player = AudioPlayer();

  String? _currentPath;
  bool _isPlaying = false;

  bool get isPlaying => _isPlaying;

  /// ▶️ پخش فایل با path
  Future<void> play(String path) async {
    if (_currentPath == path && _isPlaying) return;

    _currentPath = path;
    _isPlaying = true;

    await _player.stop();
    await _player.play(DeviceFileSource(path));

    _player.onPlayerComplete.listen((_) {
      _isPlaying = false;
      _currentPath = null;
    });
  }

  /// ⏹️ توقف پخش
  Future<void> stop() async {
    await _player.stop();
    _isPlaying = false;
    _currentPath = null;
  }

  /// 🔁 toggle (اختیاری – برای لیست فایل‌ها)
  Future<void> toggle(File file) async {
    if (_currentPath == file.path && _isPlaying) {
      await stop();
    } else {
      await play(file.path);
    }
  }

  /// 🧹 آزادسازی منابع
  void dispose() {
    _player.dispose();
  }
}
