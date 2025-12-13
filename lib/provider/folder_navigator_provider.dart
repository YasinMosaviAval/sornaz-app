import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:sornaz/classes/audio_file.dart';

class FolderNavigatorProvider extends ChangeNotifier {
  Directory? rootDir;
  Directory? currentDir;

  List<Directory> subFolders = [];
  List<AudioFile> audioFiles = [];
  List<FileSystemEntity> items = [];

  Map<String, int> folderAudioCount = {};

  Timer? _scanTimer;

  FolderNavigatorProvider() {
    _scanTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      // اگر یک root مشخص شده است، اسکن کن
      if (rootDir != null) {
        _scanEntireRoot(); // آپدیت کلی در background
      }
    });
  }

    // حتما در dispose تایمر را کنسل کن
  @override
  void dispose() {
    _scanTimer?.cancel();
    super.dispose();
  }

  // تنظیم مسیر اولیه
  Future<void> setRoot(Directory dir) async {
    rootDir = dir;
    currentDir = dir;
    await _scanCurrentDir();
    // همچنین یک اسکن کلی سریع از root انجام بده
    await _scanEntireRoot();
  }

  // رفتن داخل پوشه
  Future<void> enterFolder(Directory folder) async {
    currentDir = folder;
    await _scanCurrentDir();
  }

  // برگشت به پوشه قبلی
  Future<void> goBack() async {
    if (currentDir == null || rootDir == null) return;
    if (currentDir!.path == rootDir!.path) return;
    currentDir = currentDir!.parent;
    await _scanCurrentDir();
  }

  // اسکن محتویات پوشهٔ فعلی (فوری، بدون کش)
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

      // تبدیل File -> AudioFile (اینجا duration را صفر می‌گذاریم،
      // اگر می‌خواهی مدت را محاسبه کنی باید یک بار audio player بسازی و آن را بگیری)
      audioFiles = list
          .whereType<File>()
          .where((f) => _isAudio(f.path))
          .map((f) => AudioFile(f, Duration.zero))
          .toList();

      notifyListeners();
    } catch (e) {
      // خطا را می‌توان لاگ کرد ولی نباید کرش کند
      // if (kDebugMode) print('Error scanning current dir: $e');
    }
  }

    // اسکن کلی ریشه (برای background scan و به‌روزرسانی پوشه‌ها / آمار)
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
      // لیست بازگشتی ممکن است سنگین باشد، اینجا sync استفاده نکنیم:
      final walker = rootDir!.list(recursive: true, followLinks: false);
      List<File> found = [];
      await for (final e in walker) {
        if (e is File && _isAudio(e.path)) {
          found.add(e);
        }
      }

      // می‌توانیم آمار یا cache بسازیم؛ در ساده‌ترین حالت همین را نگه می‌داریم:
      // اگر خواستی می‌توانیم folderTree بسازیم یا notify کنیم
      // برای حالا فقط notify می‌کنیم که ممکن است تغییراتی رخ داده باشد
      notifyListeners();
    } catch (e) {
      // if (kDebugMode) print('Error scanning entire root: $e');
    }
  }

  bool _isAudio(String p) {
    final x = p.toLowerCase();
    return x.endsWith('.mp3') || x.endsWith('.wav') || x.endsWith('.m4a');
  }

  // breadcrumb
  List<String> get breadcrumbParts {
    if (rootDir == null || currentDir == null) return [];
    final root = rootDir!.path;
    final current = currentDir!.path;
    if (current == root) return [];
    var relative = current.replaceFirst(root, '');
    final parts = relative.split('/')..removeWhere((e) => e.isEmpty);
    return parts;
  }
}
