import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import '../services/file_service.dart';
import '../services/recording_service.dart';
import '../utils/timer_formatter.dart';

class VoiceRecorderProvider extends ChangeNotifier {
  final FileService fileService;
  final RecordingService recordingService;

  VoiceRecorderProvider(this.fileService, this.recordingService);

  bool isRecording = false;
  int seconds = 0;
  String timer = '00:00';

  List<File> files = [];
  List<double> amplitudes = [];
  Timer? _timer;

  Future<void> init() async {
    await fileService.init();
    files = await fileService.loadFiles();
    notifyListeners();
  }

  Future<void> start() async {
    isRecording = true;
    amplitudes.clear();
    _startTimer();

    await recordingService.start(
      path: fileService.newPath(),
      onAmplitude: (v) {
        amplitudes.add(v);
        if (amplitudes.length > 400) amplitudes.removeAt(0);
        notifyListeners();
      },
    );
    notifyListeners();
  }

  Future<void> stop() async {
    await recordingService.stop();
    _timer?.cancel();
    isRecording = false;
    seconds = 0;
    timer = '00:00';
    files = await fileService.loadFiles();
    notifyListeners();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      seconds++;
      timer = formatSeconds(seconds);
      notifyListeners();
    });
  }
}
