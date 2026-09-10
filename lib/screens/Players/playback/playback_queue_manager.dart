class PlaybackQueueManager {
  List<int> _order = [];
  int _currentIndex = -1;

  bool isShuffle = false;
  RepeatMode repeatMode = RepeatMode.off;

  void setQueue(int length) {
    _order = List.generate(length, (i) => i);
    if (isShuffle) _shuffle();
  }

  void setCurrentIndex(int index) => _currentIndex = index;

  int? next() {
    if (_currentIndex == -1) return null;

    if (repeatMode == RepeatMode.one) {
      return _currentIndex;
    }

    final pos = _order.indexOf(_currentIndex);

    if (pos < _order.length - 1) {
      return _order[pos + 1];
    }

    if (repeatMode == RepeatMode.all && _order.isNotEmpty) {
      return _order.first;
    }

    return null;
  }

  int? previous() {
    final pos = _order.indexOf(_currentIndex);
    if (pos > 0) return _order[pos - 1];
    return null;
  }

  void toggleShuffle() => isShuffle = !isShuffle;

  void toggleRepeat() {
    repeatMode = RepeatMode.values[
      (repeatMode.index + 1) % RepeatMode.values.length
    ];
  }

  void rebuildOrder({required int queueLength}) {
    final current = _currentIndex;

    _order = List.generate(queueLength, (i) => i);

    if (isShuffle) {
      _order.shuffle();
      if (current != -1 && _order.contains(current)) {
        _currentIndex = current;
      } else {
        _currentIndex = queueLength > 0 ? 0 : -1;
      }
    } else {
      _currentIndex = queueLength == 0 ? -1 : current.clamp(-1, queueLength - 1);
    }
  }

  void _shuffle() => _order.shuffle();
}


enum RepeatMode {
  off,
  one,
  all,
}
