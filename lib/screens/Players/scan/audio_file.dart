import 'dart:io';

import 'package:sornaz/screens/Players/metadata/audio_metadata.dart';

class AudioFile {
  File file;
  String fileName;
  String folderName;
  Duration duration;
  late final DateTime addedAt;
  AudioMetadata? metadata;

  AudioFile({
    required this.file,
    required this.fileName,
    required this.folderName,
    required this.duration,
    this.metadata,
    DateTime? addedAt,
  }) {
    // Files copied onto a device get a new filesystem change time.
    // Cached entries reconstruct this value from their current file.
    try {
      this.addedAt = addedAt ?? file.statSync().changed;
    } on FileSystemException {
      this.addedAt = DateTime.fromMillisecondsSinceEpoch(0);
    }
  }
}
