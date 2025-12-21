/*
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

*/



import 'dart:io';
import 'package:flutter/material.dart';
import 'package:sornaz/audio/scan/audio_file.dart';
import 'package:sornaz/helpers/app_logger.dart';
import 'package:sornaz/helpers/app_strings.dart';

class FolderNavigatorProvider extends ChangeNotifier {
  Directory? rootDir;
  Directory? currentDir;
  List<Directory> subFolders = [];
  List<AudioFile> audioFiles = [];
  Map<String, List<AudioFile>> fakeRoots = {}; // برای حالت fake (FolderListView) نگه دار
  Map<String, int> folderAudioCount = {};

  bool showOnlyFoldersWithAudio = true;
  
  void toggleShowOnlyAudioFolders() {
    showOnlyFoldersWithAudio = !showOnlyFoldersWithAudio;
    _loadRealFolder();  // دوباره لود کن تا فیلتر اعمال بشه
  }

  // برای حالت واقعی
  List<Directory> pathHistory = [];

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

  // برای حالت fake (FolderListView) — دست نخورده می‌مونه
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

  // برای حالت واقعی (FolderView) — جدید
  Future<void> startRealNavigation(Directory startDir) async {
    if (!await startDir.exists()) return;

    rootDir = startDir;
    currentDir = startDir;
    pathHistory = [startDir];
    await _loadRealFolder();
  }

  Future<void> enterRealFolder(Directory folder) async {
    if (!await folder.exists()) return;

    currentDir = folder;
    pathHistory.add(folder);
    await _loadRealFolder();
  }

  void goBackReal() {
    if (pathHistory.length <= 1) return;

    pathHistory.removeLast();
    currentDir = pathHistory.last;
    _loadRealFolder();
  }

  Future<void> _loadRealFolder() async {
    if (currentDir == null) return;

    subFolders.clear();
    audioFiles.clear();

    try {
      final entities = currentDir!.listSync();

      // اول همه فولدرها و فایل‌های صوتی رو جمع کن
      List<Directory> allSubFolders = [];
      List<AudioFile> tempAudioFiles = [];

      var fileTypeList = [
        AppStrings.file_type_mp3, 
        AppStrings.file_type_wav, 
        AppStrings.file_type_aac, 
        AppStrings.file_type_m4a, 
        AppStrings.file_type_flac, 
        AppStrings.file_type_ogg
      ];
      
      for (var entity in entities) {
        if (entity is Directory) {
          allSubFolders.add(entity);
        } else if (entity is File) {
          final ext = entity.path.split('.').last.toLowerCase();
          if (fileTypeList.contains(ext)) {
            tempAudioFiles.add(AudioFile(
              file: entity,
              fileName: entity.path.split('/').last,
              folderName: currentDir!.path,
              duration: Duration.zero,
            ));
          }
        }
      }

      // فایل‌های صوتی فعلی فولدر
      audioFiles = tempAudioFiles;
      audioFiles.sort((a, b) => a.fileName.compareTo(b.fileName));
      
      // زیرفولدرها
      if (showOnlyFoldersWithAudio) {
        // فقط فولدرهایی که داخلشون حداقل یک فایل صوتی هست
        subFolders = allSubFolders.where((dir) {
          try {
            return dir.listSync().any((e) =>
                e is File &&
                fileTypeList.contains(e.path.split('.').last.toLowerCase()));
          } catch (e) {
            return false;
          }
        }).toList();
      } else {
        // همه فولدرها
        subFolders = allSubFolders;
      }

      subFolders.sort((a, b) => a.path.compareTo(b.path));
      // audioFiles.sort((a, b) => a.fileName.compareTo(b.fileName));

      notifyListeners();
    } catch (e) {
      loggingSornaz("خطا در لود فولدر واقعی: $e");
    }
  }

  // برای حالت fake (قدیمی) — دست نخورده
  // void enterFolder(Directory folder) {
  //   currentDir = folder;
  //   audioFiles = fakeRoots[folder.path] ?? [];
  //   updateFolderAudioCount();
  //   notifyListeners();
  // }

  // void goBack() {
  //   if (currentDir == rootDir) return;
  //   currentDir = rootDir;
  //   audioFiles = fakeRoots[rootDir!.path] ?? [];
  //   updateFolderAudioCount();
  //   notifyListeners();
  // }
}