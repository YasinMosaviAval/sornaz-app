import 'dart:io';
import 'package:flutter/material.dart';
import 'package:sornaz/screens/Players/audio/scan/audio_file.dart';
import 'package:sornaz/helpers/app_functions.dart';
import 'package:sornaz/helpers/app_strings.dart';

class FolderNavigatorProvider extends ChangeNotifier {
  Directory? rootDir;
  Directory? currentDir;
  List<Directory> subFolders = [];
  List<AudioFile> audioFiles = [];
  Map<String, List<AudioFile>> fakeRoots = {};
  Map<String, int> folderAudioCount = {};

  bool showOnlyFoldersWithAudio = true;
  
  /*
  void toggleShowOnlyAudioFolders() {
    showOnlyFoldersWithAudio = !showOnlyFoldersWithAudio;
    _loadRealFolder();  // دوباره لود کن تا فیلتر اعمال بشه
  }
  */

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

/*
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
*/

  // void goBack() {
  //   if (currentDir == rootDir) return;
  //   currentDir = rootDir;
  //   audioFiles = fakeRoots[rootDir!.path] ?? [];
  //   updateFolderAudioCount();
  //   notifyListeners();
  // }



void toggleShowOnlyAudioFolders() {
  showOnlyFoldersWithAudio = !showOnlyFoldersWithAudio;
  _filterSubFolders();
  notifyListeners();
}

void _filterSubFolders() async {
  if (currentDir == null) return;

  subFolders.clear();

  try {
    final entities = currentDir!.listSync();

    List<Directory> allSubFolders = [];

    for (var entity in entities) {
      if (entity is Directory) {
        allSubFolders.add(entity);
      }
    }

    if (showOnlyFoldersWithAudio) {
      subFolders = allSubFolders.where((dir) {
        try {
          return dir.listSync().any((e) =>
              e is File &&
              [AppStrings.file_type_mp3, AppStrings.file_type_wav, AppStrings.file_type_aac, AppStrings.file_type_m4a, AppStrings.file_type_flac, AppStrings.file_type_ogg].contains(e.path.split('.').last.toLowerCase()));
        } catch (e) {
          return false;
        }
      }).toList();
    } else {
      subFolders = allSubFolders;
    }

    subFolders.sort((a, b) => a.path.compareTo(b.path));
  } catch (e) {
    loggingSornaz("خطا در فیلتر فولدرها: $e");
  }
}

Future<void> _loadRealFolder() async {
  if (currentDir == null) return;

  audioFiles.clear();

  try {
    final entities = currentDir!.listSync();

    for (var entity in entities) {
      if (entity is File) {
        final ext = entity.path.split('.').last.toLowerCase();
        if (['mp3', 'wav', 'aac', 'm4a', 'flac', 'ogg'].contains(ext)) {
          audioFiles.add(AudioFile(
            file: entity,
            fileName: entity.path.split('/').last,
            folderName: currentDir!.path,
            duration: Duration.zero,
          ));
        }
      }
    }

    audioFiles.sort((a, b) => a.fileName.compareTo(b.fileName));

    _filterSubFolders();
    notifyListeners();
  } catch (e) {
    loggingSornaz("خطا در لود فولدر واقعی: $e");
  }
}
}