import 'dart:async';

import 'package:sornaz/screens/Players/audio/playback/playback_undo.dart';

class PlaybackHistoryManager {
  final List<PlaybackUndo> _stack = [];
  Timer? _timer;

  bool get hasUndo => _stack.isNotEmpty;

  void push({
    required int index,
    required Duration position,
  }) {
    _stack.add(
      PlaybackUndo(
        index: index,
        position: position,
        createdAt: DateTime.now(),
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
    _timer = Timer(const Duration(seconds: 1), _cleanup);
  }

  void _cleanup() {
    final now = DateTime.now();
    _stack.removeWhere(
      (u) => now.difference(u.createdAt).inSeconds > 10,
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
