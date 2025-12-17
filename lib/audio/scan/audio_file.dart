import 'dart:io';

import 'package:sornaz/audio/metadata/audio_metadata.dart';

class AudioFile {
  File file;
  String fileName;
  String folderName;
  Duration duration;
  AudioMetadata? metadata;

  AudioFile({
    required this.file,
    required this.fileName,
    required this.folderName,
    required this.duration,
    this.metadata,
  });
}
