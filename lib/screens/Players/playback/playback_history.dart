import 'dart:async';
import '../scan/audio_file.dart';

import 'package:sornaz/screens/Players/playback/playback_undo.dart';

class PlaybackHistoryManager {
  PlaybackHistoryManager({DateTime Function()? now})
    : _now = now ?? DateTime.now;
  final DateTime Function() _now;
  final List<PlaybackUndo> _stack = [];
  Timer? _timer;

  bool get hasUndo {
    _cleanup();
    return _stack.isNotEmpty;
  }

  void push({
    required int index,
    required Duration position,
    List<AudioFile>? files,
    String? listKey,
    List<MapEntry<String, List<AudioFile>>>? lists,
  }) {
    _stack.add(
      PlaybackUndo(
        index: index,
        position: position,
        createdAt: _now(),
        files: files == null ? null : List.of(files),
        listKey: listKey,
        lists: lists,
      ),
    );
    _restartTimer();
  }

  PlaybackUndo? pop() {
    _cleanup();
    if (_stack.isEmpty) return null;
    return _stack.removeLast();
  }

  void _restartTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _cleanup());
  }

  void _cleanup() {
    final now = _now();
    _stack.removeWhere(
      (u) => now.difference(u.createdAt) >= const Duration(seconds: 10),
    );

    if (_stack.isEmpty) {
      _timer?.cancel();
      _timer = null;
    }
  }

  void dispose() {
    _timer?.cancel();
  }
}
