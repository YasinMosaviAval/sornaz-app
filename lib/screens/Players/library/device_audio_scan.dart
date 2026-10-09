import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sornaz/helpers/app_constants.dart';
import 'package:sornaz/screens/Players/providers/folder_navigator_provider.dart';

import 'audio_library_manager.dart';

Future<bool> hasAudioStoragePermission({bool request = false}) async {
  if (kIsWeb || !Platform.isAndroid) return false;
  try {
    final permissions = [
      Permission.audio,
      Permission.storage,
      Permission.manageExternalStorage,
    ];
    for (final permission in permissions) {
      if (await permission.isGranted) return true;
    }
    if (!request) return false;
    for (final permission in permissions) {
      if ((await permission.request()).isGranted) return true;
    }
  } catch (_) {
    // The player can show its permission guidance when opened.
  }
  return false;
}

Future<List<Directory>> discoverAudioRoots() async {
  final roots = <Directory>[];
  final internal = Directory(AppConstants.STORAGE_EMULATED_0);
  if (await internal.exists()) roots.add(internal);

  try {
    await for (final entity in Directory(
      AppConstants.STORAGE,
    ).list(followLinks: false)) {
      if (entity is! Directory) continue;
      final path = entity.path;
      if (path == AppConstants.STORAGE_EMULATED ||
          path == AppConstants.STORAGE_SELF ||
          path.startsWith(AppConstants.STORAGE_0000_0000) ||
          !RegExp(AppConstants.MUSIC_PLAYER_REGEX).hasMatch(path)) {
        continue;
      }
      if (await entity.exists()) roots.add(entity);
    }
  } on FileSystemException {
    // Removable storage may be unavailable or inaccessible.
  }
  return roots;
}

Future<bool> refreshDeviceAudioLibrary({
  required AudioLibraryManager library,
  required FolderNavigatorProvider folders,
  bool requestPermission = false,
}) async {
  if (!await hasAudioStoragePermission(request: requestPermission)) {
    return false;
  }
  final roots = await discoverAudioRoots();
  await library.setRoots(roots);
  if (roots.isNotEmpty && folders.rootDir == null) {
    await folders.startRealNavigation(roots.first);
  }
  await library.rescan();
  await folders.indexFiles(library.allFiles);
  return true;
}
