import 'package:hive_flutter/hive_flutter.dart';
import 'package:sornaz/helpers/app_constants.dart';
import 'package:sornaz/screens/Players/cache/audio_cache_service.dart';
import 'package:sornaz/screens/Players/scan/audio_file.dart';
import 'package:sornaz/screens/Players/scan/audio_file_hive.dart';

class HiveAudioCache implements AudioCacheService {
  Box<AudioFileHive>? _box;

  @override
  Future<void> init() async {
    _box = await Hive.openBox<AudioFileHive>(AppConstants.AUDIO_FILES_HIVE);
  }

  @override
  Future<List<AudioFile>> loadCachedFiles() async {
    if (_box == null) return [];
    final loaded = _box!.values.map((e) => e.toAudioFile()).toList();
    return loaded;
  }

  @override
  Future<void> saveFiles(List<AudioFile> files) async {
    if (_box == null) await init();
    await _box!.clear();
    final hiveFiles = files.map(AudioFileHive.fromAudioFile).toList();
    await _box!.addAll(hiveFiles);
  }

  @override
  Future<void> clearCache() async {
    if (_box == null) await init();
    await _box!.clear();
  }
}