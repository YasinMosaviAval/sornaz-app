import 'dart:async';
import 'package:flutter/material.dart';
import 'package:metadata_god/metadata_god.dart';
import 'package:sornaz/audio/library/audio_library_manager.dart';
import 'package:sornaz/audio/metadata/audio_metadata.dart';
import 'package:sornaz/audio/metadata/metadata_service.dart';
import 'package:sornaz/audio/playback/playback_history.dart';
import 'package:sornaz/audio/playback/playback_queue_manager.dart';
import 'package:sornaz/audio/scan/audio_file.dart';
import 'package:sornaz/classes/playback_undo.dart';
import 'package:sornaz/main.dart';
import 'package:sornaz/audio/controller/audio_player_controller.dart';

class AudioPlayerProvider extends ChangeNotifier {
  
  late final AudioPlayerController _controller;
  late final PlaybackHistoryManager _history;
  late final PlaybackQueueManager _queue;
  late final AudioLibraryManager libraryManager;

  List<AudioFile> allFiles = [];
  List<AudioFile> filteredFiles = [];
  Map<String, List<AudioFile>> folderTree = {};
  bool isLoading = false;
  bool isHiveLoading = true;
  bool isUndoMode = false;
  bool folderMode = false;
  bool showRemaining = false;

  bool get isPlaying => _controller.isPlaying;
  Duration get duration => _controller.duration;
  Duration get position => _controller.position;

  int currentIndex = -1;

  List<Duration> history = [];
  Timer? undoTimer;
  final List<PlaybackUndo> _undoStack = [];

  bool get isShuffle => _queue.isShuffle;
  RepeatMode get repeatMode => _queue.repeatMode;

  double playbackSpeed = 1.0;
  final List<double> speedOptions = [0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0, 3.0, 4.0];
  
  AudioMetadata? _currentMetadata;
  AudioMetadata? get currentMetadata => _currentMetadata;

  Future<void> loadCurrentMetadata() async {
    final audio = currentAudio;
    if (audio == null) return;

    try {
      audio.metadata = await MetadataService.extract(audio.file.path);
      _currentMetadata = audio.metadata;
    } catch (e) {
      audio.metadata = null;
      _currentMetadata = null;
    }
    notifyListeners();
  }

  Future<void> play(int index) async {
    try {
      isLoading = true;
      notifyListeners();

      currentIndex = index;
      
      _queue.setQueue(filteredFiles.length);
      _queue.setCurrentIndex(index);

      await _controller.playFile(filteredFiles[index].file.path);
      loadCurrentMetadata();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  AudioPlayerProvider({required this.libraryManager}) {
    _controller = AudioPlayerController();
    _history = PlaybackHistoryManager();
    _queue = PlaybackQueueManager();

    isHiveLoading = true;

    libraryManager.addListener(() {
      filteredFiles = libraryManager.allFiles;
      _buildFolderTree();
      notifyListeners();
    });

    _controller.onComplete.listen((_) {
      final nextIndex = _queue.next();
      if (nextIndex != null) play(nextIndex);
    });

    _controller.onStateChanged.listen((_) {
      notifyListeners();
    });
  }

  void setLoading(bool value) {
    isLoading = value;
    notifyListeners();
  }

  Future<void> pause() async => await _controller.pause();
  Future<void> resume() async => await _controller.resume();
  Future<void> seek(Duration duration) async => await _controller.seek(duration);

  Future<void> setSpeed(double value) async {
    playbackSpeed = value;
    await _controller.setSpeed(value);
    notifyListeners();
  }

  void onTrackComplete() {
    if (repeatMode == RepeatMode.one) {
      seek(Duration.zero);
      resume();
    } else {
      playNext();
    }
  }

  Future<void> previousOrUndo() async {
    final undo = _history.pop();
    if (undo != null) {
      currentIndex = undo.index;
      await _controller.playFile(
        filteredFiles[undo.index].file.path,
      );
      await _controller.seek(undo.position);
      notifyListeners();
      return;
    }

    if (position > const Duration(seconds: 3)) {
      await _controller.seek(Duration.zero);
    } else if (currentIndex > 0) {
      play(currentIndex - 1);
    }
  }

  void playNext() {
    final nextIndex = _queue.next();
    if (nextIndex != null) play(nextIndex);
  }

  void toggleShuffle() {
    _queue.toggleShuffle();
    _queue.rebuildOrder(queueLength: filteredFiles.length);
    notifyListeners();
  }

  void toggleRepeatMode() {
    _queue.toggleRepeat();
    notifyListeners();
  }

  void toggleFolderMode() {
    folderMode = !folderMode;
    notifyListeners();
  }

  void toggleTimeMode() {
    showRemaining = !showRemaining;
    notifyListeners();
  }

  void setFileList(List<AudioFile> files) {
    allFiles = files;
    filteredFiles = files;
    _buildFolderTree();
    _queue.setQueue(files.length);
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

  AudioFile? get currentAudio {
    if (currentIndex < 0 || currentIndex >= filteredFiles.length) return null;
    return filteredFiles[currentIndex];
  }

  Future<void> playFromFolder(List<AudioFile> files, int index) async {
    filteredFiles = files;
    _queue.setQueue(files.length);
    if (index < files.length) {
      _queue.setCurrentIndex(index);
    }
    await play(index);
  }

  Future<void> seekForward10() async {
    final newPos = position + const Duration(seconds: 10);
    await _controller.seek(newPos < duration ? newPos : duration);
    notifyListeners();
  }

  Future<void> seekBackward10() async {
    final newPos = position - const Duration(seconds: 10);
    await _controller.seek(newPos > Duration.zero ? newPos : Duration.zero);
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
    filteredFiles = allFiles.where((audio) => audio.fileName.toLowerCase().contains(query.toLowerCase())).toList();
    _queue.rebuildOrder(queueLength: filteredFiles.length);
    if (currentIndex >= filteredFiles.length) {
      currentIndex = filteredFiles.isEmpty ? -1 : 0;
      _queue.setCurrentIndex(currentIndex);
    }
    notifyListeners();
  }

  Future<bool> renameFile(AudioFile file, String newName, String message) async {
    final dir = file.file.parent.path;
    final newPath = "$dir/$newName";
    final newFile = await file.file.rename(newPath);
    file.file = newFile;
    notifyListeners();
    _showSnackBar(message);
    return true;
  }

  bool removeFromList(AudioFile file, String message) {
    allFiles.remove(file);
    filteredFiles.remove(file);
    notifyListeners();
    _showSnackBar(message);
    return true;
  }

  Future<bool> deleteFromDevice(AudioFile file, String message) async {
    await file.file.delete();
    allFiles.remove(file);
    filteredFiles.remove(file);
    notifyListeners();
    _showSnackBar(message);
    return true;
  }

  void _showSnackBar(String message) {
    final context = navigatorKey.currentContext;
    if (context == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
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

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

}


