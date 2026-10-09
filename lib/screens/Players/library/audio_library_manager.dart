import 'dart:io';
import 'dart:async';
import 'package:sornaz/screens/Players/metadata/metadata_service.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:sornaz/screens/Players/cache/audio_cache_factory.dart';
import 'package:sornaz/screens/Players/cache/audio_cache_service.dart';
import 'package:sornaz/screens/Players/scan/audio_file.dart';
import 'package:sornaz/screens/Players/scan/audio_file_loader.dart';
import 'package:sornaz/screens/Players/scan/scan_progress.dart';

class AudioLibraryManager extends ChangeNotifier {
  AudioLibraryManager({AudioCacheService? cache, bool hydrateMetadata = true})
    : _cacheOverride = cache,
      _hydrateMetadata = hydrateMetadata;

  final AudioCacheService? _cacheOverride;
  final bool _hydrateMetadata;
  Future<AudioCacheService> _cache() async =>
      _cacheOverride ?? await AudioCacheFactory.getCache();

  List<Directory> roots = [];
  List<AudioFile> allFiles = [];
  bool isScanning = false;
  bool isLoadingFromCache = false;
  double progress = 0.0;
  String currentPath = '';
  int scannedFiles = 0;
  int totalFiles = 0;
  bool _hydrating = false, _disposed = false;
  bool _hydrateAgain = false;
  Future<void>? _scanFuture;

  Future<void> setRoots(List<Directory> directories) async {
    roots = directories;
    notifyListeners();
  }

  Future<void> loadOrScan() async {
    if (roots.isEmpty || _disposed) return;
    isLoadingFromCache = false;
    try {
      final cache = await _cache();
      final cachedFiles = await cache.loadCachedFiles();
      if (cachedFiles.isNotEmpty) {
        allFiles = cachedFiles;
        currentPath = 'بارگذاری از حافظه تکمیل شد';
        notifyListeners();
        if (_hydrateMetadata) unawaited(hydrateDurations());
      }
    } catch (_) {
      // A damaged cache must not prevent a fresh device scan.
    }
    await rescan();
  }

  Future<void> rescan() {
    if (roots.isEmpty || _disposed) return Future.value();
    return _scanFuture ??= _scanDevice().whenComplete(() => _scanFuture = null);
  }

  Future<void> _scanDevice() async {
    isScanning = true;
    progress = 0.0;
    scannedFiles = 0;
    totalFiles = 0;
    currentPath = 'در حال شمارش فایل‌ها...';
    notifyListeners();
    try {
      final cache = await _cache();
      await AudioFileLoader.scanWithIsolate(
        roots: List.of(roots),
        onProgress: (ScanStatus status) {
          if (_disposed) return;
          scannedFiles = status.scanned;
          totalFiles = status.total;
          currentPath = status.currentPath;
          progress = totalFiles == 0 ? 0.0 : scannedFiles / totalFiles;
          notifyListeners();
        },
        onDone: (List<AudioFile> files) async {
          if (_disposed) return;
          final previous = {for (final file in allFiles) file.file.path: file};
          for (var i = 0; i < files.length; i++) {
            final old = previous[files[i].file.path];
            if (old != null) files[i] = old;
          }
          allFiles = files;
          progress = 1.0;
          await cache.saveFiles(files);
          notifyListeners();
          if (_hydrateMetadata) unawaited(hydrateDurations());
        },
      );
    } catch (_) {
      progress = 0.0;
      currentPath = 'خطا در بارگذاری';
    } finally {
      isScanning = false;
      if (!_disposed) notifyListeners();
    }
  }

  List<AudioFile> filter(String query) => allFiles
      .where(
        (audio) => audio.fileName.toLowerCase().contains(query.toLowerCase()),
      )
      .toList();

  Future<void> hydrateDurations() async {
    if (_disposed) return;
    if (_hydrating) {
      _hydrateAgain = true;
      return;
    }
    _hydrating = true;
    final probe = AudioPlayer();
    var lastUpdate = DateTime.now();
    try {
      for (final file
          in allFiles.where((f) => f.duration == Duration.zero).toList()) {
        if (_disposed) return;
        try {
          try {
            file.metadata = await MetadataService.extract(
              file.file.path,
            ).timeout(const Duration(seconds: 4));
          } catch (_) {
            /* Fall back to the audio decoder. */
          }
          final value = file.metadata?.duration;
          if (value != null && value > Duration.zero) file.duration = value;
          if (file.duration == Duration.zero) {
            await probe
                .setSource(DeviceFileSource(file.file.path))
                .timeout(const Duration(seconds: 4));
            file.duration =
                await probe.getDuration().timeout(const Duration(seconds: 2)) ??
                Duration.zero;
          }
          if (!_disposed &&
              DateTime.now().difference(lastUpdate).inMilliseconds >= 500) {
            lastUpdate = DateTime.now();
            notifyListeners();
          }
        } catch (_) {
          /* Unreadable files remain available for retry. */
        }
      }
      await (await _cache()).saveFiles(allFiles);
    } catch (_) {
      /* Metadata can be retried on the next library load. */
    } finally {
      _hydrating = false;
      await probe.dispose();
      if (!_disposed) notifyListeners();
      if (_hydrateAgain && !_disposed) {
        _hydrateAgain = false;
        unawaited(hydrateDurations());
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<void> clearCache() async {
    final cache = await _cache();
    await cache.clearCache();
    allFiles = [];
    notifyListeners();
  }
}
