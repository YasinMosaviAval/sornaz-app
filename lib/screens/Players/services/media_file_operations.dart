import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MediaFileOperations {
  static const channel = MethodChannel('sornaz/media_files');

  static Future<String?> chooseFolder() =>
      FilePicker.platform.getDirectoryPath();

  static Future<void> retainDestination(
    String folder, {
    bool video = false,
  }) async {
    if (!Platform.isWindows) return;
    final prefs = await SharedPreferences.getInstance();
    final key = video ? 'desktop.videoFolders' : 'desktop.audioFolders';
    final folders = prefs.getStringList(key) ?? [];
    if (!folders.contains(folder))
      await prefs.setStringList(key, [...folders, folder]);
  }

  static Future<String> relocate(String source, String destination) async {
    if (p.equals(source, destination)) return source;
    if (await File(destination).exists()) {
      throw const FileSystemException('A file with this name already exists.');
    }
    if (Platform.isAndroid) {
      return await channel.invokeMethod<String>('relocate', {
            'source': source,
            'destination': destination,
          }) ??
          (throw StateError('Media file was not moved'));
    }
    // A failed rename leaves the source intact, including cross-volume moves.
    return (await File(source).rename(destination)).path;
  }
}
