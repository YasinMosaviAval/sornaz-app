import 'package:sornaz/screens/Players/services/music_audio_handler.dart';
import 'dart:async';
import 'package:flutter/material.dart' hide RepeatMode;
import 'package:metadata_god/metadata_god.dart';
import 'package:sornaz/main.dart';
import 'package:sornaz/screens/Players/controller/audio_player_controller.dart';
import 'package:sornaz/screens/Players/library/audio_library_manager.dart';
import 'package:sornaz/screens/Players/metadata/audio_metadata.dart';
import 'package:sornaz/screens/Players/metadata/metadata_service.dart';
import 'package:sornaz/screens/Players/playback/playback_history.dart';
import 'package:sornaz/screens/Players/playback/playback_queue_manager.dart';
import 'package:sornaz/screens/Players/playback/playback_undo.dart';
import 'package:sornaz/screens/Players/scan/audio_file.dart';

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
  AudioFile? _playingAudio;
  bool _mediaActive = false;
  StreamSubscription<void>? _stateSubscription, _completeSubscription;
  late final VoidCallback _libraryListener;
  void _publishMedia() {
    final audio = _playingAudio;
    if (!_mediaActive || audio == null) return;
    final metadata = audio.metadata;
    musicAudioHandler?.publish(id: audio.file.path,
      title: metadata?.title?.trim().isNotEmpty == true ? metadata!.title! : audio.fileName,
      artist: metadata?.artist,
      duration: duration, position: position, playing: isPlaying,
      loading: isLoading, speed: playbackSpeed);
  }
  Future<void> stop() async {
    _mediaActive = false;
    await _controller.stop();
    musicAudioHandler?.clear();
    notifyListeners();
  }
  Future<void> skipPrevious() async {
    final index = _queue.previous();
    if (index != null) { await play(index); } else { await seek(Duration.zero); }
  }

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
    final audio = _playingAudio;
    if (audio == null) return;

    try {
      audio.metadata = await MetadataService.extract(audio.file.path);
      if (!identical(audio, _playingAudio)) return;
      _currentMetadata = audio.metadata;
    } catch (e) {
      audio.metadata = null;
      if (!identical(audio, _playingAudio)) return;
      _currentMetadata = null;
    }
    _publishMedia();
    notifyListeners();
  }

  Future<void> play(int index) async {
    if (index < 0 || index >= filteredFiles.length || isLoading) return;
    if (currentIndex != -1 && currentIndex != index) {
      _history.push(
        index: currentIndex,
        position: position,
      );
      isUndoMode = true;
      _restartUndoTimer();
      notifyListeners();
    }

    try {
      isLoading = true;
      notifyListeners();

      currentIndex = index;
      _playingAudio = filteredFiles[index];
      _currentMetadata = _playingAudio?.metadata;
      _mediaActive = true;
      
      _queue.setQueue(filteredFiles.length);
      _queue.setCurrentIndex(index);

      await _controller.playFile(filteredFiles[index].file.path);
      loadCurrentMetadata();
    } catch (_) {
      await stop();
      rethrow;
    } finally {
      isLoading = false;
      _publishMedia();
      notifyListeners();
    }
  }

  AudioPlayerProvider({required this.libraryManager}) {
    _controller = AudioPlayerController();
    _history = PlaybackHistoryManager();
    _queue = PlaybackQueueManager();

    isHiveLoading = true;
    final handler = musicAudioHandler;
    if (handler != null) {
      handler.onPlay = resume;
      handler.onPause = pause;
      handler.onStop = stop;
      handler.onSeek = seek;
      handler.onNext = playNext;
      handler.onPrevious = skipPrevious;
      handler.onRewind = seekBackward10;
      handler.onForward = seekForward10;
    }

    _libraryListener = () {
      allFiles = libraryManager.allFiles;
      filteredFiles = libraryManager.allFiles;
      _buildFolderTree();
      notifyListeners();
    };
    libraryManager.addListener(_libraryListener);

    _completeSubscription = _controller.onComplete.listen((_) {
      final nextIndex = _queue.next();
      if (nextIndex != null) { play(nextIndex); } else { stop(); }
    });

    _stateSubscription = _controller.onStateChanged.listen((_) {
      _publishMedia();
      notifyListeners();
    });
  }

  void setLoading(bool value) {
    isLoading = value;
    notifyListeners();
  }

  Future<void> pause() async => await _controller.pause();
  Future<void> resume() async {
    if (_playingAudio == null) return;
    _mediaActive = true;
    await _controller.resume();
    _publishMedia();
  }
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
      if (currentIndex != undo.index) {
        currentIndex = undo.index;
        _playingAudio = filteredFiles[undo.index];
        _mediaActive = true;
        _queue.setCurrentIndex(undo.index);
        unawaited(loadCurrentMetadata());
        await _controller.playFile(filteredFiles[undo.index].file.path);
        await Future.delayed(const Duration(milliseconds: 100));
        await _controller.seek(undo.position);
      } else {
        await _controller.seek(undo.position);
      }
      if (_history.hasUndo == false) {
        isUndoMode = false;
        undoTimer?.cancel();
      } else {
        _restartUndoTimer();
      }

      notifyListeners();
      return;
    }

    if (position > const Duration(seconds: 3)) {
      await _controller.seek(Duration.zero);
    } else if (currentIndex > 0) {
      play(currentIndex - 1);
    }
  }

  Future<void> playNext() async {
    final nextIndex = _queue.next();
    if (nextIndex != null) await play(nextIndex);
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
    // if (history.isEmpty || history.last != position) history.add(position);
    _history.push(
      index: currentIndex,
      position: position,
    );
    isUndoMode = true;
    _restartUndoTimer();
    notifyListeners();
  }

  void _restartUndoTimer() {
    undoTimer?.cancel();
    undoTimer = Timer(const Duration(seconds: 10), () {
      _cleanupUndoStack();
      notifyListeners();
    });
  }

  void restartUndoTimer() => _restartUndoTimer();

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
    undoTimer?.cancel();
    _stateSubscription?.cancel();
    _completeSubscription?.cancel();
    libraryManager.removeListener(_libraryListener);
    final handler = musicAudioHandler;
    if (handler != null) {
      handler.onPlay = null; handler.onPause = null; handler.onStop = null;
      handler.onSeek = null; handler.onNext = null; handler.onPrevious = null;
      handler.onRewind = null; handler.onForward = null;
      handler.clear();
    }
    _controller.dispose();
    super.dispose();
  }

}


