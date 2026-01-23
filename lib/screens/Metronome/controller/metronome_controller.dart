import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:sornaz/helpers/app_constants.dart';
import 'package:sornaz/screens/Metronome/classes/note_length.dart';

class MetronomeController extends ChangeNotifier {
  final AudioPlayer _accentPlayer = AudioPlayer();
  final AudioPlayer _tickPlayer = AudioPlayer();
  final AudioPlayer _subTickPlayer = AudioPlayer();

  double accentVolume = 1.0;
  double tickVolume = 0.75;
  double subTickVolume = 0.1;

  int bpm = 120;
  int timeSignature = 4;

  bool isPlaying = false;
  bool isAccentBeat = false;

  int currentBeat = 0;
  int _subTickIndex = 0;

  Timer? _timer;

  VoidCallback? onBeat;

  NoteLength selectedNote = noteLengths.first;

  int get subdivisionCount {
    switch (selectedNote.name) {
      case AppConstants.NUMBER_1:
        return 1;
      case AppConstants.NUMBER_2:
        return 2;
      case AppConstants.NUMBER_3:
        return 3;
      case AppConstants.NUMBER_4:
        return 4;
      default:
        return 1;
    }
  }

  bool showTapTempo = false;
  bool showTimerStopwatch = false;
  bool showBarsStopwatch = false;
  bool showBarsDivision = false;

  Timer? _tapResetTimer;

  bool _tapActive = false;

  bool get tapActive => _tapActive;

  final List<int> _tapTimes = [];
  static const int _maxTaps = 5;

  Timer? _practiceTimer;

  Duration? practiceDuration;
  Duration remainingDuration = Duration.zero;

  VoidCallback? onPracticeTick;
  VoidCallback? onPracticeFinished;

  StopMode stopMode = StopMode.none;

  int targetBars = 0;
  int currentBar = 0;

  Future<void> init() async {
    await _tickPlayer.setAsset(AppConstants.TICK_WAV);
    await _accentPlayer.setAsset(AppConstants.ACCENT_WAV);
    await _subTickPlayer.setAsset(AppConstants.SUB_TICK_WAV);
    
    _subTickPlayer.setVolume(subTickVolume);
    _tickPlayer.setVolume(tickVolume);
    _accentPlayer.setVolume(accentVolume);
  }

  void start() {
    stop();
    isPlaying = true;
    currentBeat = 1;
    currentBar = 0;
    
    _subTickIndex = 0;

    final baseIntervalMs = 60000 / bpm;
    final intervalMs = baseIntervalMs / subdivisionCount;

    _timer = Timer.periodic(
      Duration(milliseconds: intervalMs.round()),
      (_) => _playTick(),
    );

    if (stopMode == StopMode.timer &&
        practiceDuration != null &&
        practiceDuration != Duration.zero) {
      _practiceTimer = Timer(practiceDuration!, stop);
    }

    notifyListeners();
  }

  void stop() {
    _timer?.cancel();
    _practiceTimer?.cancel();
    _timer = null;
    _practiceTimer = null;

    isPlaying = false;
    currentBeat = 1;
    currentBar = 0;

    notifyListeners();
  }

  void _playTick() {
    final isMainBeat = _subTickIndex == 0;
    final isAccent = isMainBeat && currentBeat == 1;

    isAccentBeat = isAccent;

    if (isAccent) {
      _accentPlayer.seek(Duration.zero);
      _accentPlayer.play();
    } else if (isMainBeat) {
      _tickPlayer.seek(Duration.zero);
      _tickPlayer.play();
    } else {
      _subTickPlayer.seek(Duration.zero);
      _subTickPlayer.play();
    }

    onBeat?.call();

    _subTickIndex++;

    if (_subTickIndex >= subdivisionCount) {
      _subTickIndex = 0;
      currentBeat++;

      if (currentBeat > timeSignature) {
        currentBeat = 1;
      }
    }
  }

  void setPracticeTimer({
    required int minutes,
    required int seconds,
  }) {
    practiceDuration = Duration(
      minutes: minutes,
      seconds: seconds,
    );
    remainingDuration = practiceDuration!;
  }

  void enableTimerMode({required int minutes, required int seconds}) {
    stopMode = StopMode.timer;
    practiceDuration = Duration(minutes: minutes, seconds: seconds);
    targetBars = 0;
  }

  void enableBarsMode(int bars) {
    stopMode = StopMode.bars;
    targetBars = bars;
    practiceDuration = null;
  }

  void disableStopConditions() {
    stopMode = StopMode.none;
    practiceDuration = null;
    targetBars = 0;
  }

  void startTimerFor(int hours, int minutes) {
    final duration = Duration(hours: hours, minutes: minutes);
    _timer?.cancel();
    _timer = Timer(duration, stop);
  }

  void setNoteLength(NoteLength note) {
    selectedNote = note;
    if (isPlaying) start();
  }

  void pause() {
    _timer?.cancel();
    _timer = null;
    isPlaying = false;
  }

  void setBpm(int value) {
    bpm = value;
    if (isPlaying) start();
  }

  void setTimeSignature(int value) {
    timeSignature = value;
    currentBeat = 0;
  }

  void setTickVolume(double value) {
    tickVolume = value.clamp(0.0, 1.0);
    _tickPlayer.setVolume(tickVolume);
  }

  void setAccentVolume(double value) {
    accentVolume = value.clamp(0.0, 1.0);
    _accentPlayer.setVolume(accentVolume);
  }

  void setSubTickVolume(double value) {
    subTickVolume = value.clamp(0.0, 1.0);
    _subTickPlayer.setVolume(subTickVolume);
  }

  void setShowTapTempo(bool value) {
    showTapTempo = value;
    notifyListeners();
  }

  void tapTempo() {
    final now = DateTime.now().millisecondsSinceEpoch;

    _tapTimes.add(now);
    if (_tapTimes.length > _maxTaps) {
      _tapTimes.removeAt(0);
    }

    if (_tapTimes.length >= 2) {
      final intervals = <int>[];
      for (int i = 1; i < _tapTimes.length; i++) {
        intervals.add(_tapTimes[i] - _tapTimes[i - 1]);
      }

      final avgInterval = intervals.reduce((a, b) => a + b) / intervals.length;
      final newBpm = (60000 / avgInterval).round();
      setBpm(newBpm.clamp(40, 200));
    }

    _tapActive = true;

    _tapResetTimer?.cancel();
    _tapResetTimer = Timer(const Duration(seconds: 3), () {
      resetTapTempo();
    });
  }

  void resetTapTempo() {
    _tapTimes.clear();
    _tapActive = false;
    notifyListeners();
  }

  @override
  Future<void> dispose() async {
    _tapResetTimer?.cancel();
    stop();
    await _tickPlayer.dispose();
    await _accentPlayer.dispose();
    await _subTickPlayer.dispose();
    super.dispose();
  }

}

enum StopMode {
  none,
  timer,
  bars,
}

