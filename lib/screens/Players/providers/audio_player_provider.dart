import '../services/music_playlists.dart';
import '../services/sleep_timer_status.dart';
import '../../Voice Recorder/services/recording_text.dart';
import '../services/equalizer_settings.dart';
import 'package:sornaz/screens/Players/services/music_audio_handler.dart';
import 'dart:async';
import 'dart:io';

import 'package:sornaz/screens/Players/cache/audio_cache_factory.dart';
import 'package:sornaz/components/ab_repeat.dart';
import 'package:flutter/material.dart' hide RepeatMode;
import 'package:sornaz/main.dart';
import 'package:sornaz/screens/Players/controller/audio_player_controller.dart';
import 'package:sornaz/screens/Players/library/audio_library_manager.dart';
import 'package:sornaz/screens/Players/metadata/audio_metadata.dart';
import 'package:sornaz/screens/Players/metadata/metadata_service.dart';
import 'package:sornaz/screens/Players/playback/playback_history.dart';
import 'package:sornaz/screens/Players/playback/playback_queue_manager.dart';
import '../services/player_settings.dart';
import 'package:sornaz/screens/Players/scan/audio_file.dart';

class AudioPlayerProvider extends ChangeNotifier with WidgetsBindingObserver {
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
  String searchQuery = '';
  bool showRemaining = false;
  final abRepeat = AbRepeat();
  bool _loopSeeking = false;
  void cycleAbRepeat() {
    abRepeat.cycle(position);
    notifyListeners();
  }

  EqualizerSettings get equalizer => _controller.equalizer;
  bool get isPlaying => _controller.isPlaying;
  Duration get duration => _controller.duration;
  Duration get position => _controller.position;

  int currentIndex = -1;
  AudioFile? _playingAudio;
  bool _mediaActive = false;
  StreamSubscription<void>? _stateSubscription, _completeSubscription;
  late final VoidCallback _libraryListener;
  void _publishMedia() {
    if (sleepAtTrackEnd)
      SleepTimerStatus.instance.update(trackRemaining: duration - position);
    final audio = _playingAudio;
    if (!_mediaActive ||
        audio == null ||
        (musicAudioHandler != null &&
            !identical(musicAudioHandler!.owner, this)))
      return;
    final metadata = audio.metadata;
    musicAudioHandler?.publish(
      id: audio.file.path,
      title: metadata?.title?.trim().isNotEmpty == true
          ? metadata!.title!
          : audio.fileName,
      artist: metadata?.artist,
      duration: duration,
      position: position,
      playing: isPlaying,
      loading: isLoading,
      speed: playbackSpeed,
      undo: isUndoMode,
    );
  }

  Future<void> stop() async {
    setSleepTimer();
    _mediaActive = false;
    await _controller.stop();
    musicAudioHandler?.release(this);
    notifyListeners();
  }

  Future<void> skipPrevious() async {
    final index = _queue.previous();
    if (index != null) {
      await play(index);
    } else {
      await seek(Duration.zero);
    }
  }

  List<Duration> history = [];
  Timer? undoTimer;
  final PlayerSettings settings;
  Timer? _sleepTimer;
  DateTime? sleepDeadline;
  Duration? sleepDuration;
  bool sleepAtTrackEnd = false;
  String? _listKey;
  List<MapEntry<String, List<AudioFile>>>? _lists;

  Future<void> interrupt(PlaybackInterruption reason) async {
    await settings.load();
    if (settings.stopsFor(reason)) await stop();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached)
      interrupt(PlaybackInterruption.exitApp);
  }

  void setSleepTimer({Duration? duration, bool atTrackEnd = false}) {
    _sleepTimer?.cancel();
    sleepAtTrackEnd = atTrackEnd;
    sleepDuration = duration;
    sleepDeadline = duration == null ? null : DateTime.now().add(duration);
    SleepTimerStatus.instance.update(
      deadline: sleepDeadline,
      trackRemaining: atTrackEnd ? this.duration - position : null,
    );
    if (duration != null)
      _sleepTimer = Timer(duration, () {
        stop();
      });
    notifyListeners();
  }

  void _remember() {
    if (_playingAudio == null || currentIndex < 0) return;
    _history.push(
      index: currentIndex,
      position: position,
      files: filteredFiles,
      listKey: _listKey,
      lists: _lists,
    );
    isUndoMode = true;
    _restartUndoTimer();
    _publishMedia();
  }

  Future<void> _completed() async {
    if (sleepAtTrackEnd) {
      await stop();
      return;
    }
    if (abRepeat.active) {
      await seek(abRepeat.start!);
      await resume();
      return;
    }
    final next = _queue.next();
    if (next != null) {
      await play(next, remember: false);
      return;
    }
    switch (settings.listEnd) {
      case ListEndAction.restart:
        if (filteredFiles.isNotEmpty)
          await play(0, remember: false);
        else
          await stop();
      case ListEndAction.nextList:
        final lists = _lists;
        final at = lists?.indexWhere((e) => e.key == _listKey) ?? -1;
        if (lists != null && at >= 0) {
          for (var i = at + 1; i < lists.length; i++) {
            if (lists[i].value.isEmpty) continue;
            await playFromFolder(
              lists[i].value,
              0,
              listKey: lists[i].key,
              lists: lists,
              remember: false,
            );
            return;
          }
        }
        await stop();
      case ListEndAction.stop:
        await stop();
    }
  }

  bool get isShuffle => _queue.isShuffle;
  RepeatMode get repeatMode => _queue.repeatMode;

  double playbackSpeed = 1.0;
  final List<double> speedOptions = [
    0.25,
    0.5,
    0.75,
    1.0,
    1.25,
    1.5,
    1.75,
    2.0,
    3.0,
    4.0,
  ];

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

  Future<void> play(int index, {bool remember = true}) async {
    if (index < 0 || index >= filteredFiles.length || isLoading) return;
    if (remember && _playingAudio?.file.path != filteredFiles[index].file.path)
      _remember();

    try {
      isLoading = true;
      notifyListeners();

      currentIndex = index;
      if (_playingAudio?.file.path != filteredFiles[index].file.path)
        abRepeat.clear();
      _playingAudio = filteredFiles[index];
      _currentMetadata = _playingAudio?.metadata;
      _mediaActive = true;

      _queue.setCurrentIndex(index);

      await _activateMedia();
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

  AudioPlayerProvider({
    required this.libraryManager,
    AudioPlayerController? controller,
    PlayerSettings? playbackSettings,
  }) : settings = playbackSettings ?? PlayerSettings.instance {
    WidgetsBinding.instance.addObserver(this);
    _controller = controller ?? AudioPlayerController();
    _history = PlaybackHistoryManager();
    settings.load();
    _queue = PlaybackQueueManager();

    isHiveLoading = true;
    _libraryListener = () {
      final replaced = !identical(allFiles, libraryManager.allFiles);
      allFiles = libraryManager.allFiles;
      if (replaced) {
        filteredFiles = allFiles
            .where((f) => f.fileName.toLowerCase().contains(searchQuery))
            .toList();
        currentIndex = filteredFiles.indexWhere(
          (f) => f.file.path == _playingAudio?.file.path,
        );
        _queue.setQueue(filteredFiles.length);
        _queue.setCurrentIndex(currentIndex);
      }
      if (replaced) _buildFolderTree();
      notifyListeners();
    };
    libraryManager.addListener(_libraryListener);
    _libraryListener();

    _completeSubscription = _controller.onComplete.listen((_) {
      _completed();
    });

    _stateSubscription = _controller.onStateChanged.listen((_) {
      if (duration > Duration.zero && _playingAudio != null)
        _playingAudio!.duration = duration;
      if (!_loopSeeking && abRepeat.shouldLoop(position)) {
        _loopSeeking = true;
        _controller
            .seek(abRepeat.start!)
            .whenComplete(() => _loopSeeking = false);
      }
      _publishMedia();
      notifyListeners();
    });
  }

  void setLoading(bool value) {
    isLoading = value;
    notifyListeners();
  }

  Future<void> _activateMedia() async {
    await musicAudioHandler?.activate(
      this,
      play: resume,
      pause: pause,
      stop: stop,
      previous: previousOrUndo,
      next: playNext,
      seek: (at) async {
        startSliding();
        await seek(at);
      },
    );
  }

  Future<void> pause() async => await _controller.pause();
  Future<void> resume() async {
    if (_playingAudio == null) return;
    _mediaActive = true;
    await _activateMedia();
    await _controller.resume();
    _publishMedia();
  }

  Future<void> seek(Duration duration) async =>
      await _controller.seek(duration);

  Future<void> setSpeed(double value) async {
    playbackSpeed = value;
    await _controller.setSpeed(value);
    notifyListeners();
  }

  Future<void> onTrackComplete() => _completed();

  Future<void> previousOrUndo() async {
    final undo = _history.pop();
    if (undo != null) {
      final restored = undo.files;
      if (restored == null || undo.index < 0 || undo.index >= restored.length)
        return;
      final track = restored[undo.index];
      final changed = _playingAudio?.file.path != track.file.path;
      filteredFiles = List.of(restored);
      _lists = undo.lists;
      _listKey = undo.listKey;
      currentIndex = undo.index;
      _queue.setQueue(filteredFiles.length);
      _queue.setCurrentIndex(currentIndex);
      _playingAudio = track;
      if (changed) {
        abRepeat.clear();
        _mediaActive = true;
        await _activateMedia();
        await _controller.playFile(track.file.path);
        unawaited(loadCurrentMetadata());
      }
      await _controller.seek(undo.position);
      if (_history.hasUndo == false) {
        isUndoMode = false;
        undoTimer?.cancel();
      } else {
        _restartUndoTimer();
      }

      _publishMedia();
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
    return _playingAudio;
  }

  Future<void> playFromFolder(
    List<AudioFile> files,
    int index, {
    String? listKey,
    List<MapEntry<String, List<AudioFile>>>? lists,
    bool remember = true,
  }) async {
    if (isLoading || index < 0 || index >= files.length) return;
    if (remember) _remember();
    filteredFiles = List.of(files);
    _listKey = listKey;
    _lists = lists;
    _queue.setQueue(files.length);
    await play(index, remember: false);
  }

  Future<void> seekForward10() async {
    _remember();
    final newPos = position + const Duration(seconds: 10);
    await _controller.seek(newPos < duration ? newPos : duration);
    notifyListeners();
  }

  Future<void> seekBackward10() async {
    _remember();
    final newPos = position - const Duration(seconds: 10);
    await _controller.seek(newPos > Duration.zero ? newPos : Duration.zero);
    notifyListeners();
  }

  void startSliding() {
    _remember();
    notifyListeners();
  }

  void _restartUndoTimer() {
    undoTimer?.cancel();
    undoTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      final active = _history.hasUndo;
      if (active != isUndoMode) {
        isUndoMode = active;
        _publishMedia();
        notifyListeners();
      }
      if (!active) undoTimer?.cancel();
    });
  }

  void restartUndoTimer() => _restartUndoTimer();
  void filter(String query) {
    searchQuery = query.toLowerCase();
    notifyListeners();
  }

  Future<bool> renameFile(
    AudioFile file,
    String newName,
    String message,
  ) async {
    if (newName.isEmpty ||
        newName.contains(RegExp(r'[/\\\x00]')) ||
        newName == '.' ||
        newName == '..')
      throw const FormatException('Invalid filename');
    final dir = file.file.parent.path;
    final newPath = "$dir/$newName";
    final oldPath = file.file.path;
    final newFile = await file.file.rename(newPath);
    file.file = newFile;
    file.fileName = newName;
    await MusicPlaylists.instance.replacePath(oldPath, newFile.path);
    await moveRecordingText(oldPath, newFile.path);
    await (await AudioCacheFactory.getCache()).saveFiles(allFiles);
    _buildFolderTree();
    notifyListeners();
    _showSnackBar(message);
    return true;
  }

  Future<void> registerCroppedAudio(
    AudioFile original,
    String path,
    Duration length,
    bool replace,
  ) async {
    final previousPath = original.file.path;
    if (replace) {
      original.file = File(path);
      original.fileName = File(path).uri.pathSegments.last;
      original.duration = length;
      original.metadata = null;
      if (_playingAudio == original) {
        _playingAudio = null;
        currentIndex = -1;
        _queue.setCurrentIndex(-1);
      }
      await MusicPlaylists.instance.replacePath(previousPath, path);
      await moveRecordingText(previousPath, path);
    } else {
      allFiles.add(
        AudioFile(
          file: File(path),
          fileName: File(path).uri.pathSegments.last,
          folderName: original.folderName,
          duration: length,
        ),
      );
    }
    await (await AudioCacheFactory.getCache()).saveFiles(allFiles);
    _buildFolderTree();
    notifyListeners();
  }

  bool removeFromList(AudioFile file, String message) {
    allFiles.remove(file);
    filteredFiles.remove(file);
    notifyListeners();
    _showSnackBar(message);
    return true;
  }

  Future<bool> deleteFromDevice(AudioFile file, String message) async {
    if (identical(currentAudio, file)) {
      await stop();
      _playingAudio = null;
    }
    await file.file.delete();
    allFiles.remove(file);
    filteredFiles.remove(file);
    _queue.setQueue(filteredFiles.length);
    currentIndex = currentAudio == null
        ? -1
        : filteredFiles.indexOf(currentAudio!);
    _queue.setCurrentIndex(currentIndex);
    await (await AudioCacheFactory.getCache()).saveFiles(allFiles);
    await MusicPlaylists.instance.replacePath(file.file.path, null);
    await moveRecordingText(file.file.path, null);
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

  Future<AudioMetadata> extractMetadata(String path) =>
      MetadataService.extract(path);

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    undoTimer?.cancel();
    _history.dispose();
    _sleepTimer?.cancel();
    _stateSubscription?.cancel();
    _completeSubscription?.cancel();
    libraryManager.removeListener(_libraryListener);
    musicAudioHandler?.release(this);
    _controller.dispose();
    super.dispose();
  }
}
