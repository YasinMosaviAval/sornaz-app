import 'package:sornaz/helpers/app_platform.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:sornaz/helpers/app_constants.dart';
import 'package:sornaz/screens/Metronome/classes/note_length.dart';

class MetronomeController extends ChangeNotifier {
  late final AudioPlayer _accentPlayer = AudioPlayer();
  late final AudioPlayer _tickPlayer = AudioPlayer();
  late final AudioPlayer _subTickPlayer = AudioPlayer();

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
  static const _native = MethodChannel('sornaz/metronome');
  StreamSubscription? _nativeTicks;
  bool _disposed = false;
  int _generation = 0;
  Map<String, Object> get _configuration => {
    'bpm': bpm,
    'beats': timeSignature,
    'subdivisions': subdivisionCount,
    'accent': accentVolume,
    'tick': tickVolume,
    'sub': subTickVolume,
    'seconds': stopMode == StopMode.timer
        ? (practiceDuration?.inSeconds ?? 0)
        : 0,
    'bars': stopMode == StopMode.bars ? targetBars : 0,
  };
  void _configureNative() {
    if (AppPlatform.isAndroid && isPlaying)
      _native.invokeMethod<void>('configure', _configuration);
  }

  Future<void> _startNative() async {
    final generation = ++_generation;
    await init();
    if (_disposed || generation != _generation) return;
    await _native.invokeMethod<void>('start', _configuration);
    if (_disposed || generation != _generation) return;
    isPlaying = true;
    remainingDuration = practiceDuration ?? Duration.zero;
    _practiceTimer?.cancel();
    if (stopMode == StopMode.timer) {
      final clock = Stopwatch()..start();
      _practiceTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        final left = (practiceDuration! - clock.elapsed).inSeconds;
        remainingDuration = Duration(seconds: left < 0 ? 0 : left);
        onPracticeTick?.call();
      });
    }
    notifyListeners();
  }

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
    if (AppPlatform.isAndroid) {
      _nativeTicks ??= const EventChannel('sornaz/metronome/events')
          .receiveBroadcastStream()
          .listen(
            (event) {
              if (_disposed) return;
              if (event['finished'] == true) {
                isPlaying = false;
                _practiceTimer?.cancel();
                remainingDuration = Duration.zero;
                notifyListeners();
                onPracticeFinished?.call();
                onPracticeTick?.call();
                return;
              }
              currentBeat = event['beat'] as int;
              currentBar = event['bar'] as int;
              isAccentBeat = event['accent'] == true;
              onBeat?.call();
            },
            onError: (Object error) {
              if (!_disposed) {
                stop();
                onPracticeFinished?.call();
              }
            },
          );
      return;
    }
    await _tickPlayer.setAsset(AppConstants.TICK_WAV);
    await _accentPlayer.setAsset(AppConstants.ACCENT_WAV);
    await _subTickPlayer.setAsset(AppConstants.SUB_TICK_WAV);

    if (AppPlatform.isAndroid) {
      _configureNative();
    } else {
      _subTickPlayer.setVolume(subTickVolume);
    }
    if (AppPlatform.isAndroid) {
      _configureNative();
    } else {
      _tickPlayer.setVolume(tickVolume);
    }
    if (AppPlatform.isAndroid) {
      _configureNative();
    } else {
      _accentPlayer.setVolume(accentVolume);
    }
  }

  void start() {
    if (AppPlatform.isAndroid) {
      _startNative();
      return;
    }
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
    _generation++;
    if (AppPlatform.isAndroid) _native.invokeMethod<void>('stop');
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

  void setPracticeTimer({required int minutes, required int seconds}) {
    practiceDuration = Duration(minutes: minutes, seconds: seconds);
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
    _practiceTimer?.cancel();
    _practiceTimer = Timer(duration, stop);
  }

  void setNoteLength(NoteLength note) {
    selectedNote = note;
    if (AppPlatform.isAndroid) {
      _configureNative();
    } else if (isPlaying) {
      start();
    }
  }

  void pause() {
    if (AppPlatform.isAndroid) {
      stop();
      return;
    }
    _timer?.cancel();
    _timer = null;
    isPlaying = false;
  }

  void setBpm(int value) {
    bpm = value.clamp(30, 300);
    if (AppPlatform.isAndroid) {
      _configureNative();
    } else if (isPlaying) {
      start();
    }
  }

  void setTimeSignature(int value) {
    timeSignature = value;
    currentBeat = 0;
    _configureNative();
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
  void dispose() {
    _generation++;
    _disposed = true;
    _tapResetTimer?.cancel();
    _timer?.cancel();
    _practiceTimer?.cancel();
    _nativeTicks?.cancel();
    if (AppPlatform.isAndroid) {
      _native.invokeMethod<void>('stop');
    } else {
      _tickPlayer.dispose();
      _accentPlayer.dispose();
      _subTickPlayer.dispose();
    }
    super.dispose();
  }
}

enum StopMode { none, timer, bars }
