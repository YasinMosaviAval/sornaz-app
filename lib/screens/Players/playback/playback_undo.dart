import '../scan/audio_file.dart';

class PlaybackUndo {
  final int index;
  final Duration position;
  final DateTime createdAt;
  final List<AudioFile>? files;
  final String? listKey;
  final List<MapEntry<String, List<AudioFile>>>? lists;

  PlaybackUndo({
    required this.index,
    required this.position,
    required this.createdAt,
    this.files,
    this.listKey,
    this.lists,
  });
}
