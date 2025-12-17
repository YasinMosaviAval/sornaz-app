// ignore_for_file: empty_catches
/*
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:sornaz/classes/audio_file.dart';

class FolderNavigatorProvider extends ChangeNotifier {
  Directory? rootDir;
  Directory? currentDir;

  List<Directory> subFolders = [];
  List<AudioFile> audioFiles = [];
  Map<String, List<AudioFile>> fakeRoots = {};

  // Future<void> setRoots(List<Directory> roots, Map<String, List<AudioFile>> filesMap) async {
  //   rootDir = Directory("/");
  //   currentDir = rootDir;

  //   fakeRoots.clear();
  //   for (var r in roots) {
  //     fakeRoots[r.path] = filesMap[r.path] ?? [];
  //   }

  //   subFolders = roots;
  //   notifyListeners();
  // }

  Future<void> setRoots(List<Directory> roots, Map<String, List<AudioFile>> filesMap) async {
    if (roots.isEmpty) return;

    rootDir = roots.first;
    currentDir = rootDir;

    fakeRoots.clear();
    for (var r in roots) {
      fakeRoots[r.path] = filesMap[r.path] ?? [];
    }

    subFolders = roots;
    audioFiles = fakeRoots[currentDir!.path] ?? [];

    notifyListeners();
  }



  void enterFolder(Directory folder) {
    currentDir = folder;
    audioFiles = fakeRoots[folder.path] ?? [];
    notifyListeners();
  }

  void goBack() {
    if (currentDir == rootDir) return;
    currentDir = rootDir;
    audioFiles = [];
    notifyListeners();
  }

  List<String> get breadcrumbParts {
    if (currentDir == rootDir || currentDir == null) return [];
    return [currentDir!.path.split('/').last];
  }

  List<Directory> roots = [];

  void setFakeRoot(List<Directory> storageRoots) {
    rootDir = Directory('/');
    roots = storageRoots;
    notifyListeners();
  }


  List<FileSystemEntity> items = [];

  Map<String, int> folderAudioCount = {};

  Timer? _scanTimer;

  FolderNavigatorProvider() {
    _scanTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (rootDir != null) {
        _scanEntireRoot();
      }
    });
  }

  @override
  void dispose() {
    _scanTimer?.cancel();
    super.dispose();
  }

  Future<void> setRoot(Directory dir) async {
    rootDir = dir;
    currentDir = dir;
    await _scanCurrentDir();
    await _scanEntireRoot();
  }

  Future<void> _scanCurrentDir() async {
    if (currentDir == null) return;

  folderAudioCount.clear();

  for (var dir in subFolders) {
    try {
      final count = dir
          .listSync()
          .whereType<File>()
          .where((f) => _isAudio(f.path))
          .length;

      folderAudioCount[dir.path] = count;
    } catch (_) {
      folderAudioCount[dir.path] = 0;
    }
  }

    try {
      if (currentDir == null) return;
      final list = currentDir!.listSync();
      items = list;
      subFolders = list.whereType<Directory>().toList();
      
      audioFiles = list
          .whereType<File>()
          .where((f) => _isAudio(f.path))
          .map((f) => AudioFile(f, Duration.zero))
          .toList();

      notifyListeners();
    } catch (e) {}
  }

  Future<void> _scanEntireRoot() async {
    if (rootDir == null) return;

    folderAudioCount.clear();

    for (var dir in subFolders) {
      try {
        final count = dir
            .listSync()
            .whereType<File>()
            .where((f) => _isAudio(f.path))
            .length;

        folderAudioCount[dir.path] = count;
      } catch (_) {
        folderAudioCount[dir.path] = 0;
      }
    }

    try {
      final walker = rootDir!.list(recursive: true, followLinks: false);
      List<File> found = [];
      await for (final e in walker) {
        if (e is File && _isAudio(e.path)) {
          found.add(e);
        }
      }

      notifyListeners();
    } catch (e) {}
  }

  bool _isAudio(String p) {
    final x = p.toLowerCase();
    return x.endsWith('.mp3') || x.endsWith('.wav') || x.endsWith('.m4a') || x.endsWith('.ogg');
  }
}
*/

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:sornaz/classes/audio_file.dart';

class FolderNavigatorProvider extends ChangeNotifier {
  Directory? rootDir;
  Directory? currentDir;

  List<Directory> subFolders = [];
  List<AudioFile> audioFiles = [];
  Map<String, List<AudioFile>> fakeRoots = {};
  Map<String, int> folderAudioCount = {};

  List<String> get breadcrumbParts {
    if (currentDir == null || rootDir == null) return [];
    final rootPath = rootDir!.path;
    final currentPath = currentDir!.path;

    if (currentPath == rootPath) return [];

    final relativePath = currentPath.replaceFirst(rootPath, '');
    final parts = relativePath.split('/')..removeWhere((p) => p.isEmpty);
    return parts;
  }

  void updateFolderAudioCount() {
    folderAudioCount.clear();
    for (var folder in subFolders) {
      folderAudioCount[folder.path] = fakeRoots[folder.path]?.length ?? 0;
    }
  }

  Future<void> setRoots(List<Directory> roots, Map<String, List<AudioFile>> filesMap) async {
    if (roots.isEmpty) return;

    rootDir = roots.first;
    currentDir = rootDir;

    fakeRoots.clear();
    for (var r in roots) {
      fakeRoots[r.path] = filesMap[r.path] ?? [];
    }

    subFolders = roots;
    audioFiles = fakeRoots[currentDir!.path] ?? [];
    updateFolderAudioCount();
    notifyListeners();
  }

  void enterFolder(Directory folder) {
    currentDir = folder;
    audioFiles = fakeRoots[folder.path] ?? [];
    updateFolderAudioCount();
    notifyListeners();
  }

  void goBack() {
    if (currentDir == rootDir) return;
    currentDir = rootDir;
    audioFiles = fakeRoots[rootDir!.path] ?? [];
    updateFolderAudioCount();
    notifyListeners();
  }
}
