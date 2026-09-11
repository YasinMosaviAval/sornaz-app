import 'dart:io';
import 'dart:async';
import 'package:sornaz/screens/Players/metadata/metadata_service.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:sornaz/screens/Players/cache/audio_cache_factory.dart';
import 'package:sornaz/screens/Players/scan/audio_file.dart';
import 'package:sornaz/screens/Players/scan/audio_file_loader.dart';
import 'package:sornaz/screens/Players/scan/scan_progress.dart';

class AudioLibraryManager extends ChangeNotifier {
  List<Directory> roots = [];
  List<AudioFile> allFiles = [];
  bool isScanning = false;
  bool isLoadingFromCache = false;
  double progress = 0.0;
  String currentPath = '';
  int scannedFiles = 0;
  int totalFiles = 0;
  bool _hydrating = false, _disposed = false;

  Future<void> setRoots(List<Directory> directories) async {
    roots = directories;
    notifyListeners();
  }

  Future<void> loadOrScan() async {
    if (roots.isEmpty || isScanning) return;

    isLoadingFromCache = false;
    isScanning = true;
    progress = 0.0;
    currentPath = 'در حال آماده‌سازی...';
    // currentPath = AppStrings.audio_library_manager_preparing.translate(context);
    notifyListeners();

    try {
      final cache = await AudioCacheFactory.getCache();
      final cachedFiles = await cache.loadCachedFiles();

      if (cachedFiles.isNotEmpty) {
        allFiles = cachedFiles;
        isScanning = false;
        progress = 1.0;
        // if(!context.mounted) return;
        currentPath = 'بارگذاری از حافظه تکمیل شد';
        // currentPath = AppStrings.audio_library_manager_fininshed_loading_from_memory.translate(context);
        notifyListeners();
        unawaited(hydrateDurations());
        return;
      }

      progress = 0.0;
      scannedFiles = 0;
      totalFiles = 0;
      // if(!context.mounted) return;
      currentPath = 'در حال شمارش فایل‌ها...';
      // currentPath = AppStrings.audio_library_manager_calculating_audio_files.translate(context);
      notifyListeners();
      await AudioFileLoader.scanWithIsolate(
        roots: roots,
        // context: context,
        onProgress: (ScanStatus status) {
          scannedFiles = status.scanned;
          totalFiles = status.total;
          currentPath = status.currentPath;
          progress = totalFiles == 0 ? 0.0 : scannedFiles / totalFiles;
          notifyListeners();
        },
        onDone: (List<AudioFile> files) async {
          allFiles = files;
          isScanning = false;
          progress = 1.0;
          await cache.saveFiles(files);
          notifyListeners();
          unawaited(hydrateDurations());
        },
      );
    } catch (e) {
      isScanning = false;
      progress = 0.0;
      // if(!context.mounted) return;
      currentPath = 'خطا در بارگذاری';
      // currentPath = AppStrings.audio_library_manager_error_in_loading.translate(context);
      notifyListeners();
    }
  }

  List<AudioFile> filter(String query) => allFiles
      .where(
        (audio) => audio.fileName.toLowerCase().contains(query.toLowerCase()),
      )
      .toList();

  Future<void> hydrateDurations() async {
    if (_hydrating || _disposed) return;
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
      await (await AudioCacheFactory.getCache()).saveFiles(allFiles);
    } catch (_) {
      /* Metadata can be retried on the next library load. */
    } finally {
      _hydrating = false;
      await probe.dispose();
      if (!_disposed) notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<void> clearCache() async {
    final cache = await AudioCacheFactory.getCache();
    await cache.clearCache();
    allFiles = [];
    notifyListeners();
  }
}
