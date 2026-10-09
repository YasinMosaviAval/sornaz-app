import 'audio_metadata.dart';

class MetadataService {
  static Future<void> ensureInitialized() async {}
  static Future<AudioMetadata> extract(String path) async => AudioMetadata();
}
