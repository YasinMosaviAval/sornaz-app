import 'dart:io';
import 'dart:typed_data';

class AudioFile {
  File file;
  final Duration duration;

  AudioFile(this.file, this.duration);

  String get fileName => file.path.split('/').last;
  String get folderName => file.parent.path;
}

class AudioMetadata {
  final String? title;
  final String? artist;
  final String? album;
  final String? genre;
  final int? year;
  final Duration? duration;
  final int? bitrate;
  final Uint8List? artwork;

  AudioMetadata({
    this.title,
    this.artist,
    this.album,
    this.genre,
    this.year,
    this.duration,
    this.bitrate,
    this.artwork,
  });
}