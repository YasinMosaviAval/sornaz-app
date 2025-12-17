class PlaybackQueueManager {
  List<int> _order = [];
  int _currentIndex = -1;

  bool isShuffle = false;
  RepeatMode repeatMode = RepeatMode.off;

  void setQueue(int length) {
    _order = List.generate(length, (i) => i);
    if (isShuffle) _shuffle();
  }

  void setCurrentIndex(int index) {
    _currentIndex = index;
  }

  int? next() {
    if (_currentIndex == -1) return null;

    if (repeatMode == RepeatMode.one) {
      return _currentIndex;
    }

    final pos = _order.indexOf(_currentIndex);

    if (pos < _order.length - 1) {
      return _order[pos + 1];
    }

    if (repeatMode == RepeatMode.all) {
      return _order.first;
    }

    return null;
  }

  int? previous() {
    final pos = _order.indexOf(_currentIndex);
    if (pos > 0) return _order[pos - 1];
    return null;
  }

  void toggleShuffle() {
    isShuffle = !isShuffle;
    _rebuildOrder();
  }

  void toggleRepeat() {
    repeatMode = RepeatMode.values[
      (repeatMode.index + 1) % RepeatMode.values.length
    ];
  }

  void _rebuildOrder() {
    final current = _currentIndex;
    _order = List.generate(_order.length, (i) => i);

    if (isShuffle) _shuffle();

    _currentIndex = current;
  }

  void _shuffle() {
    _order.shuffle();
  }
}


enum RepeatMode {
  off,
  one,
  all,
}