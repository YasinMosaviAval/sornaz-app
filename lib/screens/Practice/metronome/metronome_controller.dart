import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:sornaz/screens/Practice/metronome/note_length.dart';

class MetronomeController {
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

    void pause() {
    _timer?.cancel();
    _timer = null;
    isPlaying = false;
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    isPlaying = false;
    currentBeat = 0;
    _tapTimes.clear();
  }

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

    // currentBeat++;
    // if (currentBeat >= timeSignature) {
    //   currentBeat = 0;
    // }
    
    currentBeat = (currentBeat + 1) % timeSignature;
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

  Future<void> dispose() async {
    stop();
    await _tickPlayer.dispose();
    await _accentPlayer.dispose();
  }

}
