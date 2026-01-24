import 'dart:typed_data';

class AudioMetadata {
  final String? title;
  final String? artist;
  final String? album;
  final String? genre;
  final int? year;
  final Duration? duration;
  final Uint8List? artwork;
  final int? bitrate;

  AudioMetadata({
    this.title,
    this.artist,
    this.album,
    this.genre,
    this.year,
    this.duration,
    this.artwork,
    this.bitrate,
  });
}
