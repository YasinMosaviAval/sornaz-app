class PlaybackUndo {
  final int index;
  final Duration position;
  final DateTime createdAt;

  PlaybackUndo({
    required this.index,
    required this.position,
    required this.createdAt,
  });
}