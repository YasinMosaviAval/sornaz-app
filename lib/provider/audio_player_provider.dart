import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:metadata_god/metadata_god.dart';
import 'package:sornaz/classes/audio_file.dart';
import 'package:sornaz/classes/playback_undo.dart';
import 'package:sornaz/classes/scan_progress.dart';
import 'package:sornaz/main.dart';

class AudioPlayerProvider extends ChangeNotifier {
  List<AudioFile> allFiles = [];
  List<AudioFile> filteredFiles = [];
  Map<String, List<AudioFile>> folderTree = {};
  bool isLoading = false;
  bool isScanning = false;
  double progress = 0.0;

  final AudioPlayer _player = AudioPlayer();
  bool isPlaying = false;
  bool isUndoMode = false;

  int currentIndex = -1;
  Duration duration = Duration.zero;
  Duration position = Duration.zero;

  List<Duration> history = [];
  Timer? undoTimer;
  final List<PlaybackUndo> _undoStack = [];

  String currentPath = '';
  int scannedFiles = 0;
  int totalFiles = 0;
  String currentFileName = '';

  // ==========================
  // Shuffle
  // ==========================
  bool isShuffle = false;
  void toggleShuffle() {
    isShuffle = !isShuffle;
    notifyListeners();
  }

  // ==========================
  // Folder Mode
  // ==========================
  bool folderMode = false;
  void toggleFolderMode() {
    folderMode = !folderMode;
    notifyListeners();
  }

  // ==========================
  // Repeat Mode (0=off, 1=one, 2=all)
  // ==========================
  int repeatMode = 0;
  void toggleRepeatMode() {
    repeatMode = (repeatMode + 1) % 3;
    notifyListeners();
  }

  // ==========================
  // Playback speed
  // ==========================
  double playbackSpeed = 1.0;
  final List<double> speedOptions = [
    0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0, 3.0, 4.0
  ];
  void setSpeed(double value) async {
    playbackSpeed = value;
    await _player.setPlaybackRate(playbackSpeed);
    notifyListeners();
  }

  // ==========================
  // Time Mode
  // ==========================
  bool showRemaining = false;
  void toggleTimeMode() {
    showRemaining = !showRemaining;
    notifyListeners();
  }

  // ==========================
  // Constructor
  // ==========================
  AudioPlayerProvider() {
    _initListeners();
  }

  void _initListeners() {
    _player.onPlayerStateChanged.listen((state) {
      isPlaying = state == PlayerState.playing;
      notifyListeners();
    });

    _player.onDurationChanged.listen((d) {
      duration = d;
      notifyListeners();
    });

    _player.onPlayerComplete.listen((_) {
      if (repeatMode == 1) {
        _player.seek(Duration.zero);
        _player.resume();
      } else {
        playNext();
      }
    });

    Timer.periodic(const Duration(milliseconds: 500), (_) async {
      if (isPlaying) {
        final pos = await _player.getCurrentPosition();
        if (pos != null) {
          position = pos;
          notifyListeners();
        }
      }
    });

    _player.setReleaseMode(ReleaseMode.stop);
  }

  // ==========================
  // File Loading
  // ==========================
  void start() {
    isLoading = true;
    progress = 0.0;
    scannedFiles = 0;
    totalFiles = 0;
    currentPath = '';
    currentFileName = '';
    notifyListeners();
  }

  void update(ScanStatus status) {
    scannedFiles = status.scanned;
    totalFiles = status.total;
    currentPath = status.currentPath;
    currentFileName = status.currentPath.split('/').last;
    progress = totalFiles == 0 ? 0 : scannedFiles / totalFiles;
    notifyListeners();
  }

  void finish(List<AudioFile> files) {
    allFiles = files;
    filteredFiles = files;
    _buildFolderTree();
    isLoading = false;
    notifyListeners();
  }

  void setFileList(List<AudioFile> files) {
    allFiles = files;
    filteredFiles = files;
    _buildFolderTree();
    isLoading = false;
    notifyListeners();
  }

  void _buildFolderTree() {
    folderTree.clear();
    for (var file in allFiles) {
      final folder = file.file.parent.path;
      folderTree.putIfAbsent(folder, () => []);
      folderTree[folder]!.add(file);
    }
  }

  // ==========================
  // Audio Playback
  // ==========================
  AudioFile? get currentAudio {
    if (currentIndex < 0 || currentIndex >= filteredFiles.length) return null;
    return filteredFiles[currentIndex];
  }


  Future<void> play(int index) async {
    try {
      isLoading = true;
      notifyListeners();
      if (currentIndex != -1 && currentIndex != index) {
        _undoStack.add(
          PlaybackUndo(
            index: currentIndex,
            position: position,
            createdAt: DateTime.now(),
          ),
        );
        isUndoMode = true;
        _restartUndoTimer();
      }
      currentIndex = index;
      await _player.stop();
      await _player.setSource(DeviceFileSource(filteredFiles[index].file.path));
      await _player.resume();
      loadCurrentMetadata();  // بدون await، background
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> playFromFolder(List<AudioFile> files, int index) async {
    filteredFiles = files;
    await play(index);
  }

  void playNext() {
    if (filteredFiles.isEmpty) return;

    if (isShuffle) {
      int nextIndex = _getRandomIndex();
      play(nextIndex);
    } else {
      if (currentIndex < filteredFiles.length - 1) {
        play(currentIndex + 1);
      } else if (repeatMode == 2) {
        play(0);
      }
    }
  }

  int _getRandomIndex() {
    if (filteredFiles.length <= 1) return currentIndex;
    int nextIndex = currentIndex;
    while (nextIndex == currentIndex) {
      nextIndex = DateTime.now().millisecondsSinceEpoch % filteredFiles.length;
    }
    return nextIndex;
  }

  Future<void> previousOrUndo() async {
    _cleanupUndoStack();

    if (_undoStack.isNotEmpty) {
      final undo = _undoStack.removeLast();
      await _player.stop();
      currentIndex = undo.index;
      await _player.setSource(DeviceFileSource(filteredFiles[undo.index].file.path));
      await _player.seek(undo.position);
      await _player.resume();
      notifyListeners();
      return;
    }

    if (position > const Duration(seconds: 3)) {
      await _player.seek(Duration.zero);
    } else if (currentIndex > 0) {
      play(currentIndex - 1);
    }
  }

  Future<void> pause() async {
    await _player.pause();
    notifyListeners();
  }

  Future<void> seekForward10() async {
    final newPos = position + const Duration(seconds: 10);
    await _player.seek(newPos < duration ? newPos : duration);
    notifyListeners();
  }

  Future<void> seekBackward10() async {
    final newPos = position - const Duration(seconds: 10);
    await _player.seek(newPos > Duration.zero ? newPos : Duration.zero);
    notifyListeners();
  }

  void startSliding() {
    if (history.isEmpty || history.last != position) history.add(position);
    isUndoMode = true;
    _restartUndoTimer();
    notifyListeners();
  }

  void _restartUndoTimer() {
    undoTimer?.cancel();
    undoTimer = Timer(const Duration(seconds: 1), () {
      _cleanupUndoStack();
      notifyListeners();
    });
  }

  void _cleanupUndoStack() {
    final now = DateTime.now();
    _undoStack.removeWhere((u) => now.difference(u.createdAt).inSeconds > 10);

    if (_undoStack.isEmpty) {
      isUndoMode = false;
      undoTimer?.cancel();
    }
  }

  void filter(String query) {
    filteredFiles = allFiles
        .where((audio) => audio.fileName.toLowerCase().contains(query.toLowerCase()))
        .toList();
    notifyListeners();
  }

  // ==========================
  // File operations
  // ==========================
  Future<bool> renameFile(AudioFile file, String newName) async {
    final dir = file.file.parent.path;
    final newPath = "$dir/$newName";
    final newFile = await file.file.rename(newPath);
    file.file = newFile;
    notifyListeners();
    _showSnackBar("نام فایل تغییر کرد");
    return true;
  }

  bool removeFromList(AudioFile file) {
    allFiles.remove(file);
    filteredFiles.remove(file);
    notifyListeners();
    _showSnackBar("از لیست حذف شد");
    return true;
  }

  Future<bool> deleteFromDevice(AudioFile file) async {
    await file.file.delete();
    allFiles.remove(file);
    filteredFiles.remove(file);
    notifyListeners();
    _showSnackBar("فایل از حافظه حذف شد");
    return true;
  }

  void _showSnackBar(String message) {
    final context = navigatorKey.currentContext;
    if (context == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  // ==========================
  // Metadata
  // ==========================
  AudioMetadata? _currentMetadata;
  AudioMetadata? get currentMetadata => _currentMetadata;

  Future<void> loadCurrentMetadata() async {
    final audio = currentAudio;
    if (audio == null) return;
    try {
      _currentMetadata = await extractMetadata(audio.file.path);
    } catch (e) {
      _currentMetadata = null;
    }
    notifyListeners();
  }

  Future<AudioMetadata> extractMetadata(String path) async {
    final meta = await MetadataGod.readMetadata(file: path);
    return AudioMetadata(
      title: meta.title,
      artist: meta.artist,
      album: meta.album,
      genre: meta.genre,
      year: meta.year,
      duration: meta.duration,
      artwork: meta.picture?.data,
    );
  }
}
