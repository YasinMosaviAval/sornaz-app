import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sornaz/helpers/app_functions.dart';
import 'package:sornaz/helpers/app_strings.dart';
import 'package:sornaz/helpers/app_translations.dart';
import '../services/file_service.dart';
import '../services/recording_service.dart';

class VoiceRecorderProvider extends ChangeNotifier {
  final FileService fileService;
  final RecordingService recordingService;

  VoiceRecorderProvider(this.fileService, this.recordingService);

  bool isRecording = false;
  bool isPaused = false;

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

  void _onAmplitude(double v) {
    if (isPaused || !isRecording) return;

    amplitudes.add(v);
    if (amplitudes.length > 400) {
      amplitudes.removeAt(0);
    }
    notifyListeners();
  }

  Future<void> start() async {
    isRecording = true;
    isPaused = false;
    amplitudes.clear();
    seconds = 0;
    timer = '00:00';
    _startTimer();

    await recordingService.start(
      path: fileService.newPath(),
      onAmplitude: _onAmplitude,
    );

    notifyListeners();
  }

  Future<void> stop() async {
    await recordingService.stop();
    _timer?.cancel();

    isRecording = false;
    isPaused = false;
    seconds = 0;
    timer = '00:00';
    files = await fileService.loadFiles();

    notifyListeners();
  }

  Future<void> pause() async {
    if (!isRecording) return;
    await recordingService.pause();
    isPaused = true;
    notifyListeners();
  }

  Future<void> resume() async {
    if (!isRecording) return;
    await recordingService.resume();
    isPaused = false;
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


  Future<void> requestPermissions(BuildContext context) async {
  final mic = await Permission.microphone.request();
  final storage = await Permission.storage.request();

  if(!context.mounted) return;
  if (!mic.isGranted || !storage.isGranted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppStrings.voice_recorder_microphone_and_storage_access_permissions.translate(context),
        ),
      ),
    );
  }
}


}
