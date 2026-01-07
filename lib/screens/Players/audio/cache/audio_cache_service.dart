import 'package:sornaz/screens/Players/audio/scan/audio_file.dart';

abstract class AudioCacheService {
  Future<void> init();

  Future<List<AudioFile>> loadCachedFiles();
  Future<void> saveFiles(List<AudioFile> files);
  Future<void> clearCache();
}