import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import '../scan/audio_file.dart';

class FolderNavigatorProvider extends ChangeNotifier {
  Directory? rootDir, currentDir;
  List<Directory> subFolders = [], pathHistory = [];
  List<AudioFile> audioFiles = [];
  Map<String, List<AudioFile>> fakeRoots = {};
  Map<String, int> folderAudioCount = {};
  bool showOnlyFoldersWithAudio = true, isLoading = false;
  String? error;
  int _generation = 0;
  bool _disposed = false;
  Map<String, AudioFile> _files = {};
  final Set<String> _audioAncestors = {};
  bool _indexed = false;
  static const _extensions = {'.mp3', '.wav', '.aac', '.m4a', '.flac', '.ogg'};

  List<String> get breadcrumbParts =>
      currentDir == null || rootDir == null || currentDir!.path == rootDir!.path
      ? []
      : p.split(p.relative(currentDir!.path, from: rootDir!.path));

  Future<void> indexFiles(List<AudioFile> files) async {
    _files = {for (final file in files) p.normalize(file.file.path): file};
    _audioAncestors.clear();
    for (final file in files) {
      var parent = p.dirname(p.normalize(file.file.path));
      while (_audioAncestors.add(parent)) {
        final next = p.dirname(parent);
        if (next == parent) break;
        parent = next;
      }
    }
    _indexed = true;
    await _loadRealFolder();
  }

  Future<void> startRealNavigation(Directory root) async {
    rootDir = root;
    currentDir = root;
    pathHistory = [root];
    await _loadRealFolder();
  }

  Future<void> enterRealFolder(Directory folder) async {
    currentDir = folder;
    pathHistory.add(folder);
    await _loadRealFolder();
  }

  Future<void> goBackReal() async {
    if (pathHistory.length <= 1) return;
    pathHistory.removeLast();
    currentDir = pathHistory.last;
    await _loadRealFolder();
  }

  Future<void> toggleShowOnlyAudioFolders() async {
    showOnlyFoldersWithAudio = !showOnlyFoldersWithAudio;
    await _loadRealFolder();
  }

  Future<void> _loadRealFolder() async {
    final dir = currentDir;
    if (dir == null || _disposed) return;
    final request = ++_generation;
    isLoading = true;
    error = null;
    notifyListeners();
    final folders = <Directory>[], files = <AudioFile>[];
    try {
      await for (final entity in dir.list(followLinks: false)) {
        if (_disposed || request != _generation) return;
        if (entity is Directory) {
          // Until the library index is ready, keep folders accessible. Once
          // indexed, include ancestors too so deeply nested songs are reachable.
          if (!showOnlyFoldersWithAudio ||
              !_indexed ||
              _audioAncestors.contains(p.normalize(entity.path)))
            folders.add(entity);
        } else if (entity is File &&
            _extensions.contains(p.extension(entity.path).toLowerCase())) {
          files.add(
            _files[p.normalize(entity.path)] ??
                AudioFile(
                  file: entity,
                  fileName: p.basename(entity.path),
                  folderName: dir.path,
                  duration: Duration.zero,
                ),
          );
        }
      }
      folders.sort((a, b) => a.path.compareTo(b.path));
      files.sort((a, b) => a.fileName.compareTo(b.fileName));
      if (!_disposed && request == _generation) {
        subFolders = folders;
        audioFiles = files;
      }
    } on FileSystemException {
      if (!_disposed && request == _generation) {
        error = 'دسترسی به این پوشه ممکن نیست.';
        subFolders = [];
        audioFiles = [];
      }
    } finally {
      if (!_disposed && request == _generation) {
        isLoading = false;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    super.dispose();
  }
}
