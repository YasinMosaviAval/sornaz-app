import 'dart:async';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:sornaz/classes/audio_file.dart';
import 'package:sornaz/classes/playback_undo.dart';
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

  final List<PlaybackUndo> _undoStack = [];



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
  // Folder Mode & Flat Mode
  // ==========================
  bool folderMode = false; // false = flat, true = folder

  void toggleFolderMode() {
    folderMode = !folderMode;
    notifyListeners();
  }


  // void toggleFolderMode(BuildContext context) {
  //   if (!folderMode) {
  //     final folderProvider =
  //         Provider.of<FolderNavigatorProvider>(context, listen: false);

  //     if (folderProvider.rootDir == null) {
  //       // هنوز پوشه انتخاب نشده
  //       loadFiles(context); // یا باز کردن picker
  //       return;
  //     }
  //   }

  //   folderMode = !folderMode;
  //   notifyListeners();
  // }

  Map<String, List<AudioFile>> folderTree = {};

  void _buildFolderTree() {
    folderTree.clear();

    for (var file in allFiles) {
      final folder = file.file.parent.path;

      if (!folderTree.containsKey(folder)) {
        folderTree[folder] = [];
      }

      folderTree[folder]!.add(file);
    }
  }


  // ==========================
  // ==========================
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
/*
  Future<void> loadFiles() async {
    isLoading = true;
    notifyListeners();

    // allFiles = await AudioFileLoader.loadFromPicker();
    filteredFiles = allFiles;

    _buildFolderTree();

    isLoading = false;
    notifyListeners();
  }
*/
/*
Future<void> loadFiles(BuildContext context) async {
  isLoading = true;
  notifyListeners();


  // context امن قبل از await
  final safeContext = context;

  // انتخاب پوشه
  final path = await AudioFileLoader.pickDirectory();
  if (path == null) {
    isLoading = false;
    notifyListeners();
    return;
  }

  final dir = Directory(path);

  // ست کردن مسیر در FolderNavigatorProvider
  final folderProvider = Provider.of<FolderNavigatorProvider>(safeContext, listen: false);
  await folderProvider.setRoot(dir);

  // بارگذاری فایل‌ها
  allFiles = await AudioFileLoader.loadDirectory(dir);
  filteredFiles = allFiles;

  _buildFolderTree();

  isLoading = false;
  notifyListeners();
}
*/
Future<void> loadFilesFromDirectory(Directory dir) async {
  isLoading = true;
  notifyListeners();

  allFiles = await AudioFileLoader.loadFromDirectory(dir);
  filteredFiles = allFiles;
  _buildFolderTree();

  isLoading = false;
  notifyListeners();
}


void setFileList(List<AudioFile> files) {
  allFiles = files;
  filteredFiles = files;
  _buildFolderTree();
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
    // اگر آهنگ قبلی داریم و آهنگ جدید است
    if (currentIndex != -1 && currentIndex != index) {
      _undoStack.add(
        PlaybackUndo(
          index: currentIndex,
          position: position,
          createdAt: DateTime.now(),
        ),
      );

      isUndoMode = true;
      _restartUndoTimer();
    }

    currentIndex = index;

    await _player.stop();
    await _player.setSource(
      DeviceFileSource(filteredFiles[index].file.path),
    );

    await _player.resume();

    notifyListeners();
  }
    
  void _cleanupUndoStack() {
    final now = DateTime.now();

    _undoStack.removeWhere(
      (u) => now.difference(u.createdAt).inSeconds > 10,
    );

    if (_undoStack.isEmpty) {
      isUndoMode = false;
      undoTimer?.cancel();
    }
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

  Future<void> previousOrUndo() async {
    _cleanupUndoStack();

    if (_undoStack.isNotEmpty) {
      final undo = _undoStack.removeLast(); // LIFO

      await _player.stop();
      currentIndex = undo.index;

      await _player.setSource(
        DeviceFileSource(filteredFiles[undo.index].file.path),
      );

      await _player.seek(undo.position);
      await _player.resume();

      notifyListeners();
      return;
    }

    // رفتار قبلی
    if (position > const Duration(seconds: 3)) {
      await _player.seek(Duration.zero);
    } else if (currentIndex > 0) {
      play(currentIndex - 1);
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
  undoTimer = Timer(const Duration(seconds: 1), () {
    _cleanupUndoStack();
    notifyListeners();
  });
}

  void playFromFolder(List<AudioFile> files, int index) {
    filteredFiles = files;
    play(index);
  }

}
