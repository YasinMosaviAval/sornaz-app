import 'package:hive_flutter/hive_flutter.dart';
import 'package:sornaz/audio/cache/audio_cache_service.dart';
import 'package:sornaz/audio/scan/audio_file.dart';
import 'package:sornaz/audio/scan/audio_file_hive.dart';

class HiveAudioCache implements AudioCacheService {
  late Box<AudioFileHive> _box;

  @override
  Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(AudioFileHiveAdapter());
    _box = await Hive.openBox<AudioFileHive>('audio_files_hive');
  }

  @override
  Future<List<AudioFile>> loadCachedFiles() async {
    return _box.values.map((e) => e.toAudioFile()).toList();
  }

  @override
  Future<void> saveFiles(List<AudioFile> files) async {
    await _box.clear();
    final hiveFiles = files.map(AudioFileHive.fromAudioFile).toList();
    await _box.addAll(hiveFiles);
  }

  @override
  Future<void> clearCache() async {
    await _box.clear();
  }
}