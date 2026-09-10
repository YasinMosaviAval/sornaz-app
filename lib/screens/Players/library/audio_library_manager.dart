import 'dart:io';
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

  Future<void> setRoots(List<Directory> directories) async {
    roots = directories;
    notifyListeners();
  }

  Future<void> loadOrScan() async {
    if (roots.isEmpty) return;

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
        await hydrateDurations();
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
          await hydrateDurations();
        }
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

  List<AudioFile> filter(String query) => allFiles.where((audio) => audio.fileName.toLowerCase().contains(query.toLowerCase())).toList();

  Future<void> hydrateDurations() async {
    final probe = AudioPlayer();
    try {
      for (final file in allFiles.where((f) => f.duration == Duration.zero)) {
        try {
          try { file.metadata = await MetadataService.extract(file.file.path); } catch (_) { /* Fall back to the audio decoder. */ }
          final value = file.metadata?.duration;
          if (value != null && value > Duration.zero) file.duration = value;
          if (file.duration == Duration.zero) {
            await probe.setSource(DeviceFileSource(file.file.path));
            file.duration = await probe.getDuration() ?? Duration.zero;
          }
          notifyListeners();
        } catch (_) { /* Unreadable files remain available for retry. */ }
      }
      await (await AudioCacheFactory.getCache()).saveFiles(allFiles);
    } finally { await probe.dispose(); }
  }

  Future<void> clearCache() async {
    final cache = await AudioCacheFactory.getCache();
    await cache.clearCache();
    allFiles = [];
    notifyListeners();
  }
}
