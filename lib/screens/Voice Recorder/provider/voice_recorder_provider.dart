import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sornaz/helpers/app_constants.dart';
import 'package:sornaz/helpers/app_functions.dart';
import 'package:sornaz/helpers/app_strings.dart';
import 'package:sornaz/helpers/app_translations.dart';
import 'package:sornaz/screens/Voice%20Recorder/services/playback_service.dart';
import '../services/file_service.dart';
import '../services/recording_service.dart';

class VoiceRecorderProvider extends ChangeNotifier {
  final FileService fileService;
  final RecordingService recordingService;

  VoiceRecorderProvider(
    this.fileService, 
    this.recordingService,
    this.playbackService,
  );

  bool isRecording = false;
  bool isPaused = false;
  bool isPlaying = false;
  bool isFavorite = false;

  String? currentFilePath;

  int seconds = 0;
  String timer = AppConstants.TIMER_00_00;

  List<File> files = [];
  List<double> amplitudes = [];
  Timer? _timer;

@override
void dispose() {
  playbackService.dispose();
  super.dispose();
}

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
    timer = AppConstants.TIMER_00_00;
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
    timer = AppConstants.TIMER_00_00;
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


Future<void> startRecording() async {
  if (isRecording) return;

  currentFilePath ??= fileService.newPath();

  await recordingService.start(
    path: currentFilePath!,
    onAmplitude: _onAmplitude,
  );

  isRecording = true;
  isPaused = false;
  _startTimer();
  notifyListeners();
}


Future<void> pauseRecording() async {
  if (!isRecording) return;

  await recordingService.pause();
  isPaused = true;
  isRecording = false;
  _timer?.cancel();

  notifyListeners();
}


Future<void> resumeRecording() async {
  if (isRecording) return;

  await recordingService.resume();
  isRecording = true;
  isPaused = false;
  _startTimer();

  notifyListeners();
}


Future<void> stopRecording() async {
  await recordingService.stop();
  _timer?.cancel();

  isRecording = false;
  isPaused = false;
  seconds = 0;
  timer = AppConstants.TIMER_00_00;

  currentFilePath = null;
  files = await fileService.loadFiles();

  notifyListeners();
}

final PlaybackService playbackService;

// Future<void> playCurrent() async {
//   if (currentFilePath == null) return;

//   isPlaying = true;
//   notifyListeners();

//   await playbackService.play(currentFilePath!);
//
//   isPlaying = false;
//   notifyListeners();
// }

Future<void> playCurrent() async {
  if (currentFilePath == null || isRecording) return;

  await playbackService.play(currentFilePath!);
}



void toggleFavorite() {
  isFavorite = !isFavorite;
  notifyListeners();
}



// ------------------------------------------------------------
// ❌ Delete single file
// ------------------------------------------------------------
// Future<void> deleteFile(File file) async {
//   if (await file.exists()) {
//     await file.delete();
//   }

//   files.removeWhere((f) => f.path == file.path);
//   notifyListeners();
// }

// Future<void> renameFile(File file, String newName) async {
//   final directory = file.parent.path;
//   final newPath = '$directory/$newName.m4a';

//   final newFile = await file.rename(newPath);

//   final index = files.indexWhere((f) => f.path == file.path);
//   if (index != -1) {
//     files[index] = newFile;
//   }

//   notifyListeners();
// }



}
