import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:sornaz/audio/scan/audio_file.dart';

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
