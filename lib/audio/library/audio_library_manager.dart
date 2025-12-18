import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:sornaz/audio/scan/audio_file.dart';
import 'package:sornaz/audio/scan/audio_file_loader.dart';
import 'package:sornaz/audio/scan/scan_progress.dart';

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

  Future<void> scanLibrary() async {
    if (roots.isEmpty) return;

    isScanning = true;
    progress = 0.0;
    scannedFiles = 0;
    totalFiles = 0;
    currentPath = '';
    notifyListeners();

    await AudioFileLoader.scanWithIsolate(
      roots: roots,
      onProgress: (ScanStatus status) {
        scannedFiles = status.scanned;
        totalFiles = status.total;
        currentPath = status.currentPath;
        progress = totalFiles == 0 ? 0.0 : scannedFiles / totalFiles;
        notifyListeners();
      },
      onDone: (List<AudioFile> files) {
        allFiles = files;
        isScanning = false;
        progress = 1.0;
        notifyListeners();
      },
    );
  }

  List<AudioFile> filter(String query) {
    return allFiles
        .where((audio) => audio.fileName.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }
}
