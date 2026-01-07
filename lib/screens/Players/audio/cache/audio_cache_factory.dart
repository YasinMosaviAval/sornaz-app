import 'package:sornaz/screens/Players/audio/cache/audio_cache_service.dart';
import 'hive_audio_cache.dart';

class AudioCacheFactory {
  static AudioCacheService? _cache;

  static Future<AudioCacheService> getCache() async {
    _cache ??= HiveAudioCache();
    await _cache!.init();
    return _cache!;
  }

  static Future<void> clearCache() async {
    await _cache?.clearCache();
  }
}