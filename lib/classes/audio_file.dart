import 'dart:io';

class AudioFile {
  File file;
  final Duration duration;

  AudioFile(this.file, this.duration);

  String get fileName => file.path.split('/').last;
  String get folderName => file.parent.path;
}
