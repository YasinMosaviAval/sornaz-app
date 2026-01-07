import 'package:metadata_god/metadata_god.dart';
import 'audio_metadata.dart';

class MetadataService {
  static Future<AudioMetadata> extract(String path) async {
    final meta = await MetadataGod.readMetadata(file: path);

    return AudioMetadata(
      title: meta.title,
      artist: meta.artist,
      album: meta.album,
      genre: meta.genre,
      year: meta.year,
      duration: meta.duration,
      artwork: meta.picture?.data,
      // bitrate: meta.bitrate,
    );
  }
}
