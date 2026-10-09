import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sornaz/screens/Players/cache/audio_cache_service.dart';
import 'package:sornaz/screens/Players/library/audio_library_manager.dart';
import 'package:sornaz/screens/Players/scan/audio_file.dart';

class _MemoryAudioCache implements AudioCacheService {
  List<AudioFile> files = [];

  @override
  Future<void> init() async {}

  @override
  Future<List<AudioFile>> loadCachedFiles() async => List.of(files);

  @override
  Future<void> saveFiles(List<AudioFile> value) async {
    files = List.of(value);
  }

  @override
  Future<void> clearCache() async => files.clear();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('rescan finds audio added after the initial cached scan', () async {
    final root = await Directory.systemTemp.createTemp('sornaz-audio-rescan-');
    final cache = _MemoryAudioCache();
    final library = AudioLibraryManager(cache: cache, hydrateMetadata: false);
    addTearDown(() async {
      library.dispose();
      await root.delete(recursive: true);
    });

    await File('${root.path}/first.mp3').writeAsBytes([0]);
    await library.setRoots([root]);
    await library.loadOrScan();
    expect(library.allFiles.map((file) => file.fileName), ['first.mp3']);

    await File('${root.path}/second.flac').writeAsBytes([0]);
    await library.loadOrScan();
    expect(library.allFiles.map((file) => file.fileName).toSet(), {
      'first.mp3',
      'second.flac',
    });
    expect(cache.files.length, 2);
  });
}
