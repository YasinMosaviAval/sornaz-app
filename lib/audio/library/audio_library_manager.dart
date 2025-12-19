import 'dart:io';
import 'package:flutter/material.dart';
import 'package:sornaz/audio/cache/audio_cache_factory.dart';
import 'package:sornaz/audio/cache/audio_cache_service.dart';
import 'package:sornaz/audio/scan/audio_file.dart';
import 'package:sornaz/audio/scan/scan_progress.dart';
import 'package:sornaz/audio/scan/audio_file_loader.dart';

class AudioLibraryManager extends ChangeNotifier {
  List<Directory> roots = [];
  List<AudioFile> allFiles = [];
  bool isScanning = false;
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

    isScanning = true;
    notifyListeners();

    final cache = await AudioCacheFactory.getCache();

    final cachedFiles = await cache.loadCachedFiles();

    if (cachedFiles.isNotEmpty) {
      allFiles = cachedFiles;
      isScanning = false;
      progress = 1.0;
      notifyListeners();
      return;
    }

    await _performFullScan(cache);
  }


  Future<void> _performFullScan(AudioCacheService cache) async {
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

        await cache.saveFiles(files);

        notifyListeners();
      },
    );
  }

  List<AudioFile> filter(String query) {
    return allFiles
        .where((audio) => audio.fileName.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  Future<void> clearCache() async {
    final cache = await AudioCacheFactory.getCache();
    await cache.clearCache();
    allFiles = [];
    notifyListeners();
  }
}
