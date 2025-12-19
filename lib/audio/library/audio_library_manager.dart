import 'dart:io';
import 'package:flutter/material.dart';
import 'package:sornaz/audio/cache/audio_cache_factory.dart';
import 'package:sornaz/audio/scan/audio_file.dart';
import 'package:sornaz/audio/scan/audio_file_loader.dart';
import 'package:sornaz/audio/scan/scan_progress.dart';

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

    isLoadingFromCache = true;
    isScanning = false;
    notifyListeners();

    try {
      final cache = await AudioCacheFactory.getCache();

      final cachedFiles = await cache.loadCachedFiles();

      if (cachedFiles.isNotEmpty) {
        allFiles = cachedFiles;
        progress = 1.0;
        notifyListeners();
        return;
      }

      isScanning = true;
      progress = 0.0;
      scannedFiles = 0;
      totalFiles = 0;
      currentPath = 'در حال شمارش فایل‌ها...';
      notifyListeners();

      // await _performFullScan(cache);
      await AudioFileLoader.scanWithIsolate(
        roots: roots,
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
          await cache.saveFiles(files);  // ذخیره در Hive برای دفعه بعد
          notifyListeners();
        }
      );
    } catch (e) {
      isScanning = false;
      notifyListeners();
    }
  }


  // Future<void> _performFullScan(AudioCacheService cache) async {
  //   await AudioFileLoader.scanWithIsolate(
  //     roots: roots,
  //     onProgress: (ScanStatus status) {
  //       scannedFiles = status.scanned;
  //       totalFiles = status.total;
  //       currentPath = status.currentPath;
  //       progress = totalFiles == 0 ? 0.0 : scannedFiles / totalFiles;
  //       notifyListeners();
  //     },
  //     onDone: (List<AudioFile> files) async {
  //       allFiles = files;
  //       isScanning = false;
  //       progress = 1.0;
  //       await cache.saveFiles(files);
  //       notifyListeners();
  //     },
  //   );
  // }

  List<AudioFile> filter(String query) => allFiles.where((audio) => audio.fileName.toLowerCase().contains(query.toLowerCase())).toList();

  Future<void> clearCache() async {
    final cache = await AudioCacheFactory.getCache();
    await cache.clearCache();
    allFiles = [];
    notifyListeners();
  }
}
