import 'dart:async';
import 'dart:io';
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
  );
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
  List<File> files = [];
  List<double> amplitudes = [];
  Timer? _timer;

  Future<void> init() => _initialization ??= _initialize();
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
    amplitudes.add(value);
    if (amplitudes.length > 400) amplitudes.removeAt(0);
    _notify();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!isRecording || _disposed) return;
      timer = formatSeconds(++seconds);
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
      final path = fileService.newPath();
      await recordingService.start(path: path, onAmplitude: _onAmplitude);
      currentFilePath = path;
      amplitudes.clear();
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
      isRecording = true;
      isPaused = false;
      _startTimer();
    });
  }

  Future<void> stopRecording() async {
    if (!isRecording && !isPaused) return;
    await _run(() async {
      await recordingService.stop();
      _timer?.cancel();
      isRecording = false;
      isPaused = false;
      seconds = 0;
      timer = AppConstants.TIMER_00_00;
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
