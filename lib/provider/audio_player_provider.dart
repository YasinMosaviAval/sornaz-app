
import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:sornaz/classes/audio_file.dart';
import 'package:sornaz/services/audio_file_loader.dart';

class AudioPlayerProvider extends ChangeNotifier {
  final AudioPlayer _player = AudioPlayer();

  List<AudioFile> allFiles = [];
  List<AudioFile> filteredFiles = [];

  bool isLoading = false;
  bool isPlaying = false;
  bool isUndoMode = false;

  int currentIndex = -1;
  Duration duration = Duration.zero;
  Duration position = Duration.zero;

  List<Duration> history = [];
  Timer? undoTimer;

// =================================================================================
// =================================================================================
// =================================================================================
  
  bool showRemaining = false;

  void toggleTimeMode() {
    showRemaining = !showRemaining;
    notifyListeners();
  }

// =================================================================================
// =================================================================================

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

  void setSpeed(double value) async {
    playbackSpeed = value;
    await _player.setPlaybackRate(playbackSpeed);
    notifyListeners();
  }


// =================================================================================
// =================================================================================
// =================================================================================


  AudioPlayerProvider() {
    _initListeners();
  }

  void _initListeners() {
    _player.onPlayerStateChanged.listen((state) {
      isPlaying = state == PlayerState.playing;
      notifyListeners();

      if (state == PlayerState.completed) playNext();
    });

    _player.onDurationChanged.listen((d) {
      duration = d;
      notifyListeners();
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
  }

  Future<void> loadFiles() async {
    isLoading = true;
    notifyListeners();

    allFiles = await AudioFileLoader.loadFromPicker();
    filteredFiles = allFiles;

    isLoading = false;
    notifyListeners();
  }

  void filter(String q) {
    filteredFiles = allFiles
        .where((audio) => audio.fileName.toLowerCase().contains(q.toLowerCase()))
        .toList();
    notifyListeners();
  }

  Future<void> play(int index) async {
    currentIndex = index;
    await _player.play(DeviceFileSource(filteredFiles[index].file.path));

    history.clear();
    isUndoMode = false;
    undoTimer?.cancel();

    notifyListeners();
  }

  Future<void> pause() async {
    await _player.pause();
    notifyListeners();
  }

  void playNext() {
    if (currentIndex < filteredFiles.length - 1) play(currentIndex + 1);
  }

  void previousOrUndo() {
    if (isUndoMode && history.isNotEmpty) {
      final p = history.removeLast();
      _player.seek(p);

      if (history.isEmpty) {
        isUndoMode = false;
        undoTimer?.cancel();
      } else {
        _restartUndoTimer();
      }
      notifyListeners();
    } else {
      if (position > const Duration(seconds: 3)) {
        _player.seek(Duration.zero);
      } else if (currentIndex > 0) {
        play(currentIndex - 1);
      }
    }
  }

  void startSliding() {
    if (history.isEmpty || history.last != position) history.add(position);
    isUndoMode = true;
    _restartUndoTimer();
    notifyListeners();
  }

  Future<void> seekTo(double sec) async {
    final d = Duration(seconds: sec.toInt());
    await _player.seek(d);
    _restartUndoTimer();
  }

  void _restartUndoTimer() {
    undoTimer?.cancel();
    undoTimer = Timer(const Duration(seconds: 10), () {
      isUndoMode = false;
      history.clear();
      notifyListeners();
    });
  }
}
