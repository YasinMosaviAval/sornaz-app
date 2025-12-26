import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:sornaz/screens/Practice/metronome/note_length.dart';

class MetronomeController extends ChangeNotifier {
  final AudioPlayer _tickPlayer = AudioPlayer();
  final AudioPlayer _accentPlayer = AudioPlayer();

  final List<int> _tapTimes = [];
  static const int _maxTaps = 5;

  double tickVolume = 1.0;
  double accentVolume = 1.0;

  Timer? _timer;

  int bpm = 120;
  int timeSignature = 4;
  int currentBeat = 0;

  bool isPlaying = false;
  bool isAccentBeat = false;

  /// UI callback (برای انیمیشن)
  VoidCallback? onBeat;

Timer? _practiceTimer;

Duration? practiceDuration;
Duration remainingDuration = Duration.zero;

VoidCallback? onPracticeTick;
VoidCallback? onPracticeFinished;

StopMode stopMode = StopMode.none;

// 🎼 Bars
int targetBars = 0;
int currentBar = 0;

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
/*
void start() {
  stop();
  isPlaying = true;
  currentBeat = 1;

  final beatInterval = Duration(
    milliseconds: (60000 / bpm).round(),
  );

  _timer = Timer.periodic(beatInterval, (_) {
    _playBeat();
  });

  /// اگر تایمر تمرین تنظیم شده باشد
  // if (practiceDuration != null) {
  //   _startPracticeTimer();
  // }

  if (practiceDuration != null  && practiceDuration != Duration.zero) {
    _startPracticeTimer();
  }

  
}

void _startPracticeTimer() {
  remainingDuration = practiceDuration!;

  _practiceTimer?.cancel();
  _practiceTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
    remainingDuration -= const Duration(seconds: 1);

    onPracticeTick?.call();

    if (remainingDuration <= Duration.zero) {
      timer.cancel();
      stop();
      onPracticeFinished?.call();
    }
  });
}

void stop() {
  _timer?.cancel();
  _practiceTimer?.cancel();

  _timer = null;
  _practiceTimer = null;

  isPlaying = false;
  currentBeat = 1;
}
*/
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

void start() {
  stop();
  isPlaying = true;
  currentBeat = 1;
  currentBar = 0;

  final interval = Duration(milliseconds: (60000 / bpm).round());

  _timer = Timer.periodic(interval, (_) {
    _playBeat();
  });

  if (stopMode == StopMode.timer &&
      practiceDuration != null &&
      practiceDuration != Duration.zero) {
    _practiceTimer = Timer(practiceDuration!, stop);
  }
}

void _playBeat() {
  final isAccent = currentBeat == 1;
  isAccentBeat = isAccent;

  if (isAccent) {
    _accentPlayer.seek(Duration.zero);
    _accentPlayer.play();
  } else {
    _tickPlayer.seek(Duration.zero);
    _tickPlayer.play();
  }

  onBeat?.call();

  if (isAccent) {
    currentBar++;

    if (stopMode == StopMode.bars &&
        targetBars > 0 &&
        currentBar >= targetBars) {
      stop();
      return;
    }
  }

  currentBeat++;
  if (currentBeat > timeSignature) {
    currentBeat = 1;
  }
}

void stop() {
  _timer?.cancel();
  _practiceTimer?.cancel();
  _timer = null;
  _practiceTimer = null;

  isPlaying = false;
  currentBeat = 1;
  currentBar = 0;
}

void startTimerFor(int hours, int minutes) {
  final duration = Duration(hours: hours, minutes: minutes);
  _timer?.cancel();
  _timer = Timer(duration, stop);
}


  NoteLength selectedNote = noteLengths[0];

  void setNoteLength(NoteLength note) {
    selectedNote = note;
    if (isPlaying) start();
  }

  Future<void> init() async {
    await _tickPlayer.setAsset('assets/audio/tick.wav');
    await _accentPlayer.setAsset('assets/audio/accent.wav');

    _tickPlayer.setVolume(tickVolume);
    _accentPlayer.setVolume(accentVolume);
  }
/*
  void start() {
    stop();
    isPlaying = true;
    currentBeat = 0;

    final interval = Duration(
      milliseconds: (60000 / bpm * selectedNote.multiplier).round(),
    );

    // final interval = Duration(milliseconds: (60000 / bpm).round(),);

    _timer = Timer.periodic(interval, (_) {
      _playBeat();
    });
  }
*/
  void pause() {
    _timer?.cancel();
    _timer = null;
    isPlaying = false;
  }
/*
  void stop() {
    _timer?.cancel();
    _timer = null;
    isPlaying = false;
    currentBeat = 0;
    _tapTimes.clear();
  }
*/
/*
  void _playBeat() {
    isAccentBeat = currentBeat == 0;

    if (isAccentBeat) {
      _accentPlayer.seek(Duration.zero);
      _accentPlayer.play();
    } else {
      _tickPlayer.seek(Duration.zero);
      _tickPlayer.play();
    }

    onBeat?.call();

    currentBeat = (currentBeat + 1) % timeSignature;
  }
*/
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
/*
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
  }
*/
bool showTapTempo = false;
bool showTimerStopwatch = false;
bool showBarsStopwatch = false;
bool showBarsDivision = false;


void setShowTapTempo(bool value) {
  showTapTempo = value;
  notifyListeners();
}

  Timer? _tapResetTimer;

  // void tapTempo() {
  //   final now = DateTime.now().millisecondsSinceEpoch;

  //   _tapTimes.add(now);
  //   if (_tapTimes.length > _maxTaps) {
  //     _tapTimes.removeAt(0);
  //   }

  //   if (_tapTimes.length >= 2) {
  //     final intervals = <int>[];
  //     for (int i = 1; i < _tapTimes.length; i++) {
  //       intervals.add(_tapTimes[i] - _tapTimes[i - 1]);
  //     }

  //     final avgInterval = intervals.reduce((a, b) => a + b) / intervals.length;
  //     final newBpm = (60000 / avgInterval).round();
  //     setBpm(newBpm.clamp(40, 200));
  //   }

  //   // ریست خودکار Tap Tempo بعد از 3 ثانیه
  //   _tapResetTimer?.cancel(); // لغو تایمر قبلی
  //   _tapResetTimer = Timer(const Duration(seconds: 3), () {
  //     resetTapTempo();
  //   });
  // }


  @override
  Future<void> dispose() async {
    _tapResetTimer?.cancel();
    super.dispose();
    stop();
    await _tickPlayer.dispose();
    await _accentPlayer.dispose();
  }

bool _tapActive = false; // وضعیت Tap فعال

bool get tapActive => _tapActive;

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

  // فعال کردن Tap Active بعد از اولین Tap
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


}

enum StopMode {
  none,
  timer,
  bars,
}
