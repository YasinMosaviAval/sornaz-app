import 'package:sornaz/helpers/app_platform.dart';
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
  String? _segmentPath;
  int _offsetMilliseconds = 0;
  SavedRecording? overwriteTarget;
  int overwriteAt = 0;
  Future<void> startOverwrite(SavedRecording file) async {
    overwriteTarget = file;
    overwriteAt = playbackService.position.inMilliseconds;
    try {
      await startRecording();
    } catch (_) {
      overwriteTarget = null;
      rethrow;
    }
  }

  int seconds = 0;
  String timer = AppConstants.TIMER_00_00;
  List<SavedRecording> files = [];
  List<double> amplitudes = [];
  int totalSamples = 0;
  int bookmarkRevision = 0;
  List<int> recordingBookmarks = [], playbackBookmarks = [];
  bool _bookmarkBusy = false;
  int get recordingMilliseconds =>
      _offsetMilliseconds + _recordingClock.elapsedMilliseconds;
  int get bookmarkPosition =>
      isPaused && playbackService.currentPath == currentFilePath
      ? playbackService.position.inMilliseconds
      : recordingMilliseconds;
  bool get canBookmarkRecording =>
      !_bookmarkBusy &&
      !isBusy &&
      (isRecording || isPaused) &&
      recordingBookmarks.every((t) => (t - bookmarkPosition).abs() >= 1000);
  bool get canBookmarkPlayback =>
      !_bookmarkBusy &&
      playbackBookmarks.every(
        (t) => (t - playbackService.position.inMilliseconds).abs() >= 1000,
      );
  final Stopwatch _recordingClock = Stopwatch();
  Timer? _timer;

  Future<void> init() => _initialization ??= _initialize();
  Future<void> refreshFiles() async {
    if (isRecording || isPaused) return;
    await init();
    files = await fileService.loadFiles();
    _notify();
  }

  Future<void> addRecordingBookmark() async {
    final path = currentFilePath;
    if (path == null || !canBookmarkRecording) return;
    _bookmarkBusy = true;
    try {
      await fileService.bookmarks.add(path, bookmarkPosition);
      recordingBookmarks = await fileService.bookmarks.load(path);
      bookmarkRevision++;
    } finally {
      _bookmarkBusy = false;
    }
    _notify();
  }

  Future<void> addPlaybackBookmark(SavedRecording file) async {
    if (playbackService.currentPath != file.uri || !canBookmarkPlayback) return;
    _bookmarkBusy = true;
    try {
      await fileService.bookmarks.add(
        file.uri,
        playbackService.position.inMilliseconds,
      );
      bookmarkRevision++;
      playbackBookmarks = await fileService.bookmarks.load(file.uri);
    } finally {
      _bookmarkBusy = false;
    }
    _notify();
  }

  Future<void> removeBookmark(String uri, int milliseconds) async {
    await fileService.bookmarks.remove(uri, milliseconds);
    if (uri == playbackService.currentPath)
      playbackBookmarks = await fileService.bookmarks.load(uri);
    if (uri == currentFilePath)
      recordingBookmarks = await fileService.bookmarks.load(uri);
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
    playbackBookmarks = await fileService.bookmarks.load(file.uri);
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

    _notify();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!isRecording || _disposed) return;
      seconds = recordingMilliseconds ~/ 1000;
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
      _segmentPath = null;
      _offsetMilliseconds = 0;
      amplitudes.clear();
      recordingBookmarks = [];
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
      _recordingClock.stop();
      if (AppPlatform.isAndroid) {
        await recordingService.stop();
        isRecording = false;
        isPaused = true;
        if (_segmentPath != null) {
          await fileService.spliceDraft(
            currentFilePath!,
            _segmentPath!,
            _offsetMilliseconds,
          );
          _segmentPath = null;
        }
      } else {
        await recordingService.pause();
      }
      _recordingClock.stop();
      isRecording = false;
      isPaused = true;
      _timer?.cancel();
      if (AppPlatform.isAndroid) {
        await playbackService.stop();
        await playbackService.play(currentFilePath!, autoplay: false);
        await playbackService.seek(
          Duration(milliseconds: recordingMilliseconds),
        );
      }
    });
  }

  Future<void> resumeRecording() async {
    if (!isPaused) {
      if (!isRecording) await startRecording();
      return;
    }
    await _run(() async {
      if (AppPlatform.isAndroid) {
        if (_segmentPath != null) {
          await fileService.spliceDraft(
            currentFilePath!,
            _segmentPath!,
            _offsetMilliseconds,
          );
          _segmentPath = null;
        }
        final at = playbackService.currentPath == currentFilePath
            ? playbackService.position.inMilliseconds
            : recordingMilliseconds;
        await playbackService.stop();
        final segment = fileService.newPath();
        await recordingService.start(path: segment, onAmplitude: _onAmplitude);
        _segmentPath = segment;
        _offsetMilliseconds = at;
        _recordingClock.reset();
        final keep = (at / 100).floor().clamp(0, amplitudes.length);
        amplitudes = amplitudes.take(keep).toList();
        totalSamples = keep;
        for (final t in recordingBookmarks.where((t) => t >= at).toList()) {
          await fileService.bookmarks.remove(currentFilePath!, t);
        }
        recordingBookmarks = recordingBookmarks.where((t) => t < at).toList();
      } else {
        await playbackService.stop();
        await recordingService.resume();
      }
      _recordingClock.start();
      isRecording = true;
      isPaused = false;
      _startTimer();
    });
  }

  Future<void> stopRecording() async {
    if (!isRecording && !isPaused) return;
    await _run(() async {
      final outputUri = AppPlatform.isAndroid && isPaused
          ? null
          : await recordingService.stop();
      await playbackService.stop();
      if (_segmentPath != null) {
        await fileService.spliceDraft(
          currentFilePath!,
          _segmentPath!,
          _offsetMilliseconds,
        );
        _segmentPath = null;
      }
      _recordingClock.stop();
      _timer?.cancel();
      isRecording = false;
      isPaused = false;
      seconds = 0;
      timer = AppConstants.TIMER_00_00;
      final savedPath = currentFilePath;
      if (savedPath != null) {
        if (overwriteTarget != null) {
          await fileService.overwrite(overwriteTarget!, savedPath, overwriteAt);
          overwriteTarget = null;
        } else {
          await fileService.publish(savedPath, sourceUri: outputUri);
        }
      }
      currentFilePath = null;
      _offsetMilliseconds = 0;
      _recordingClock.reset();
      amplitudes.clear();
      totalSamples = 0;
      recordingBookmarks = [];
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
