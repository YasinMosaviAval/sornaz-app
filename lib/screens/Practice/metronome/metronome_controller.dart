import 'dart:async';
import 'package:just_audio/just_audio.dart';

class MetronomeController {
  final AudioPlayer _tickPlayer = AudioPlayer();
  final AudioPlayer _accentPlayer = AudioPlayer();

  List<int> _tapTimes = [];
  static const int _maxTaps = 5;

bool swingEnabled = false;
double swingPercent = 0.0; // 0 - 75
double volume = 1.0; // 0.0 - 1.0
bool _isFirstSubBeat = true;


  Timer? _timer;

  int bpm = 120;
  int timeSignature = 4;
  int _currentBeat = 0;

  bool isPlaying = false;

  Future<void> init() async {
    await _tickPlayer.setAsset('assets/audio/tick.wav');
    await _accentPlayer.setAsset('assets/audio/accent.wav');
  }

  void start() {
    stop();
    isPlaying = true;
    _currentBeat = 0;

    final interval = Duration(
      milliseconds: (60000 / bpm).round(),
    );

    _timer = Timer.periodic(interval, (_) {
      _playBeat();
    });
  }

  void _playBeat() {
    if (_currentBeat == 0) {
      _accentPlayer.seek(Duration.zero);
      _accentPlayer.play();
    } else {
      _tickPlayer.seek(Duration.zero);
      _tickPlayer.play();
    }

    _currentBeat = (_currentBeat + 1) % timeSignature;
  }
/*
  void stop() {
    _timer?.cancel();
    _timer = null;
    isPlaying = false;
  }
*/
  void setBpm(int value) {
    bpm = value;
    if (isPlaying) start(); // ریست تایمر
  }

  void setTimeSignature(int value) {
    timeSignature = value;
    _currentBeat = 0;
  }

  Future<void> dispose() async {
    stop();
    await _tickPlayer.dispose();
    await _accentPlayer.dispose();
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

    final avgInterval =
        intervals.reduce((a, b) => a + b) / intervals.length;

    final newBpm = (60000 / avgInterval).round();

    setBpm(newBpm.clamp(40, 200));
  }
}

void stop() {
  _timer?.cancel();
  _timer = null;
  isPlaying = false;
  _tapTimes.clear();
}


Duration _nextInterval() {
  final beatMs = 60000 / bpm;

  if (!swingEnabled) {
    return Duration(milliseconds: beatMs.round());
  }

  final swingAmount = swingPercent / 200;
  final first = beatMs * (0.5 + swingAmount);
  final second = beatMs * (0.5 - swingAmount);

  final duration =
      _isFirstSubBeat ? first : second;

  _isFirstSubBeat = !_isFirstSubBeat;

  return Duration(milliseconds: duration.round());
}


Future<void> _playTick(bool accented) async {
  final player = accented ? _accentPlayer : _tickPlayer;

  await player.seek(Duration.zero);
  await player.play();
}

void _scheduleNext() {
  if (!isPlaying) return;

  _timer = Timer(_nextInterval(), () {
    _handleBeat();
    _scheduleNext();
  });
}

void _handleBeat() {
  if (_isFirstSubBeat) {
    final isAccent = _currentBeat == 0;
    _playTick(isAccent);
    _currentBeat = (_currentBeat + 1) % timeSignature;
  } else {
    _playTick(false);
  }
}


void setVolume(double value) {
  volume = value;

  _tickPlayer.setVolume(volume);
  _accentPlayer.setVolume(volume);
}


}
