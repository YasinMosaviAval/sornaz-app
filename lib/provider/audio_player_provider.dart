import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:sornaz/classes/audio_file.dart';
import 'package:sornaz/main.dart';
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

  // ==========================
  // Shuffle
  // ==========================
  bool isShuffle = false;

  void toggleShuffle() {
    isShuffle = !isShuffle;
    notifyListeners();
  }

  // ==========================
  // Remove file from List, from Device, Rename file
  // ==========================
  Future<bool> renameFile(AudioFile file, String newName) async {
    final dir = file.file.parent.path;

    final newPath = "$dir/$newName";

    final newFile = await file.file.rename(newPath);

    // بروزرسانی خود AudioFile
    file.file = newFile;

    notifyListeners();   // 👈 لیست فوراً رفرش می‌شود

    // Snackbar
    _showSnackBar("نام فایل تغییر کرد");
    return true;
  }

  bool removeFromList(AudioFile file) {
    allFiles.remove(file);
    filteredFiles.remove(file);

    notifyListeners();

    _showSnackBar("از لیست حذف شد");
    return true;
  }

  Future<bool> deleteFromDevice(AudioFile file) async {
    await file.file.delete();

    allFiles.remove(file);
    filteredFiles.remove(file);

    notifyListeners();

    _showSnackBar("فایل از حافظه حذف شد");
    return true;
  }

  void _showSnackBar(String message) {
    final context = navigatorKey.currentContext;
    if (context == null) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: Duration(seconds: 2),
      ),
    );
  }



  // ==========================
  // Repeat mode (0=off, 1=one, 2=all)
  // ==========================
  int repeatMode = 0;

  void toggleRepeatMode() {
    repeatMode = (repeatMode + 1) % 3;
    notifyListeners();
  }

  // ==========================
  // Time mode
  // ==========================
  bool showRemaining = false;

  void toggleTimeMode() {
    showRemaining = !showRemaining;
    notifyListeners();
  }

  // ==========================
  // Playback speed
  // ==========================
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

  // ==========================
  // Constructor
  // ==========================
  AudioPlayerProvider() {
    _initListeners();
  }

  void _initListeners() {
    // وضعیت پخش
    _player.onPlayerStateChanged.listen((state) {
      isPlaying = state == PlayerState.playing;
      notifyListeners();
    });

    // طول آهنگ
    _player.onDurationChanged.listen((d) {
      duration = d;
      notifyListeners();
    });

    // پایان آهنگ
    _player.onPlayerComplete.listen((event) async {
      if (repeatMode == 1) {
        // Repeat ONE
        await _player.seek(Duration.zero);
        await _player.resume();
      } else {
        playNext();
      }
    });

    // موقعیت پخش
    Timer.periodic(const Duration(milliseconds: 500), (_) async {
      if (isPlaying) {
        final pos = await _player.getCurrentPosition();
        if (pos != null) {
          position = pos;
          notifyListeners();
        }
      }
    });

    _player.setReleaseMode(ReleaseMode.stop);
  }

  // ==========================
  // Load files
  // ==========================
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

  // ==========================
  // Playback control
  // ==========================
  Future<void> play(int index) async {
    currentIndex = index;
    await _player.stop();

    await _player.setSource(
      DeviceFileSource(filteredFiles[index].file.path),
    );

    if (repeatMode == 1) {
      _player.setReleaseMode(ReleaseMode.loop);
    } else {
      _player.setReleaseMode(ReleaseMode.stop);
    }

    await _player.resume();

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
    if (filteredFiles.isEmpty) return;

    if (isShuffle) {
      int nextIndex = _getRandomIndex();
      play(nextIndex);
    } else {
      if (currentIndex < filteredFiles.length - 1) {
        play(currentIndex + 1);
      } else if (repeatMode == 2) {
        // Repeat ALL
        play(0);
      }
    }
  }

  int _getRandomIndex() {
    if (filteredFiles.length <= 1) return currentIndex;

    int nextIndex = currentIndex;
    while (nextIndex == currentIndex) {
      nextIndex = DateTime.now().millisecondsSinceEpoch % filteredFiles.length;
    }
    return nextIndex;
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

  // ==========================
  // Seek / Undo
  // ==========================
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

  Future<void> seekForward10() async {
    final newPos = position + const Duration(seconds: 10);
    await _player.seek(newPos < duration ? newPos : duration);
    notifyListeners();
  }

  Future<void> seekBackward10() async {
    final newPos = position - const Duration(seconds: 10);
    await _player.seek(newPos > Duration.zero ? newPos : Duration.zero);
    notifyListeners();
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
