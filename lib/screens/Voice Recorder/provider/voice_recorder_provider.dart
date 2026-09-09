import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sornaz/helpers/app_constants.dart';
import 'package:sornaz/helpers/app_functions.dart';
import '../services/file_service.dart';
import '../services/recording_service.dart';
import '../services/playback_service.dart';

class MicrophonePermissionDenied implements Exception {}

class VoiceRecorderProvider extends ChangeNotifier {
  final FileService fileService;
  final RecordingService recordingService;
  final PlaybackService playbackService;
  VoiceRecorderProvider(
    this.fileService,
    this.recordingService,
    this.playbackService,
  ) {
    playbackService.onChanged = () {
      isPlaying = playbackService.isPlaying;
      _notify();
    };
  }
  bool isRecording = false,
      isPaused = false,
      isPlaying = false,
      isFavorite = false;
  bool isBusy = false;
  bool _disposed = false;
  Future<void>? _initialization;
  String? currentFilePath;
  int seconds = 0;
  String timer = AppConstants.TIMER_00_00;
  List<SavedRecording> files = [];
  List<double> amplitudes = [];
  int totalSamples = 0;
  int bookmarkRevision = 0;
  final Stopwatch _recordingClock = Stopwatch();
  Timer? _timer;

  Future<void> init() => _initialization ??= _initialize();
  Future<void> refreshFiles() async {
    await init();
    files = await fileService.loadFiles();
    _notify();
  }

  Future<void> addRecordingBookmark() async {
    final path = currentFilePath;
    if (path == null || (!isRecording && !isPaused) || isBusy) return;
    await fileService.bookmarks.add(path, _recordingClock.elapsedMilliseconds);
    bookmarkRevision++;
    _notify();
  }

  Future<void> addPlaybackBookmark(SavedRecording file) async {
    if (playbackService.currentPath != file.uri) return;
    await fileService.bookmarks.add(
      file.uri,
      playbackService.position.inMilliseconds,
    );
    bookmarkRevision++;
    _notify();
  }

  Future<void> removeBookmark(String uri, int milliseconds) async {
    await fileService.bookmarks.remove(uri, milliseconds);
    bookmarkRevision++;
    _notify();
  }

  Future<void> seekBookmark(SavedRecording file, int milliseconds) async {
    if (isRecording || isPaused) return;
    if (playbackService.currentPath != file.uri) {
      await playbackService.play(file.uri);
    }
    await playbackService.seek(Duration(milliseconds: milliseconds));
  }

  Future<void> playSaved(SavedRecording file) async {
    if (isRecording || isPaused) return;
    await playbackService.play(file.uri);
  }

  Future<void> _initialize() async {
    try {
      await fileService.init();
      files = await fileService.loadFiles();
      _notify();
    } catch (_) {
      _initialization = null;
      rethrow;
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  void _onAmplitude(double value) {
    if (!isRecording || _disposed) return;
    totalSamples++;
    amplitudes.add(value);
    if (amplitudes.length > 400) amplitudes.removeAt(0);
    _notify();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!isRecording || _disposed) return;
      seconds = _recordingClock.elapsed.inSeconds;
      timer = formatSeconds(seconds);
      _notify();
    });
  }

  Future<void> _run(Future<void> Function() operation) async {
    if (isBusy || _disposed) return;
    isBusy = true;
    _notify();
    try {
      await operation();
    } finally {
      isBusy = false;
      _notify();
    }
  }

  Future<void> startRecording() async {
    if (isRecording || isPaused) return;
    await _run(() async {
      // Recordings use app-private documents; no shared-storage permission is needed.
      if (!await recordingService.hasPermission()) {
        throw MicrophonePermissionDenied();
      }
      await init();
      if (_disposed) return;
      await fileService.preparePublicStorage();
      await playbackService.stop();
      final path = fileService.newPath();
      await recordingService.start(path: path, onAmplitude: _onAmplitude);
      currentFilePath = path;
      amplitudes.clear();
      totalSamples = 0;
      _recordingClock
        ..reset()
        ..start();
      seconds = 0;
      timer = AppConstants.TIMER_00_00;
      isRecording = true;
      isPaused = false;
      _startTimer();
    });
  }

  Future<void> pauseRecording() async {
    if (!isRecording) return;
    await _run(() async {
      await recordingService.pause();
      _recordingClock.stop();
      isRecording = false;
      isPaused = true;
      _timer?.cancel();
    });
  }

  Future<void> resumeRecording() async {
    if (!isPaused) {
      if (!isRecording) await startRecording();
      return;
    }
    await _run(() async {
      await playbackService.stop();
      await recordingService.resume();
      _recordingClock.start();
      isRecording = true;
      isPaused = false;
      _startTimer();
    });
  }

  Future<void> stopRecording() async {
    if (!isRecording && !isPaused) return;
    await _run(() async {
      await recordingService.stop();
      _recordingClock.stop();
      _timer?.cancel();
      isRecording = false;
      isPaused = false;
      seconds = 0;
      timer = AppConstants.TIMER_00_00;
      final savedPath = currentFilePath;
      if (savedPath != null) await fileService.publish(savedPath);
      currentFilePath = null;
      files = await fileService.loadFiles();
    });
  }

  Future<void> start() => startRecording();
  Future<void> stop() => stopRecording();
  Future<void> pause() => pauseRecording();
  Future<void> resume() => resumeRecording();
  Future<void> playCurrent() async {
    if (currentFilePath == null || isRecording || isBusy) return;
    await playbackService.play(currentFilePath!);
  }

  void toggleFavorite() {
    isFavorite = !isFavorite;
    _notify();
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    unawaited(recordingService.dispose());
    playbackService.dispose();
    super.dispose();
  }
}
