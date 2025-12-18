import 'dart:io';

class RecordingFile {
  final File file;
  final DateTime modified;

  RecordingFile(this.file, this.modified);

  String get name =>
      file.path.split('/').last.replaceAll('.m4a', '');
}
