import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:metadata_god/metadata_god.dart';
import 'audio_metadata.dart';

class MetadataService {
  static Future<void>? _initialization;
  static Future<AudioMetadata> extract(String path) async {
    Metadata meta = const Metadata();
    try {
      await (_initialization ??= MetadataGod.initialize());
      meta = await MetadataGod.readMetadata(file: path);
    } catch (_) {}

    final details = <String, String>{
      if (meta.albumArtist != null) 'albumArtist': meta.albumArtist!,
      if (meta.trackNumber != null)
        'track':
            '${meta.trackNumber}${meta.trackTotal != null ? '/${meta.trackTotal}' : ''}',
      if (meta.discNumber != null)
        'disc':
            '${meta.discNumber}${meta.discTotal != null ? '/${meta.discTotal}' : ''}',
    };
    if (defaultTargetPlatform == TargetPlatform.android) {
      try {
        final native = await const MethodChannel(
          'sornaz/music_metadata',
        ).invokeMapMethod<String, String>('read', {'path': path});
        if (native != null) details.addAll(native);
      } catch (_) {}
    }
    try {
      final stat = await File(path).stat();
      details['fileSize'] = '${stat.size}';
      details['modified'] = stat.modified.toLocal().toString().split('.').first;
    } catch (_) {}
    details['path'] = path;
    return AudioMetadata(
      title: meta.title,
      artist: meta.artist,
      album: meta.album,
      genre: meta.genre,
      year: meta.year,
      duration: meta.duration,
      artwork: meta.picture?.data,
      bitrate: int.tryParse(details['bitrate'] ?? '') == null
          ? null
          : (int.parse(details['bitrate']!) / 1000).round(),
      details: details,
    );
  }
}
