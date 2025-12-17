import 'dart:async';
import 'package:audioplayers/audioplayers.dart';

class AudioPlayerController {
  final AudioPlayer _player = AudioPlayer();

  bool isPlaying = false;
  Duration duration = Duration.zero;
  Duration position = Duration.zero;
  double playbackSpeed = 1.0;

  final StreamController<void> _stateChanged = StreamController.broadcast();

  Stream<void> get onStateChanged => _stateChanged.stream;

  AudioPlayerController() {
    _initListeners();
  }

  void _initListeners() {
    _player.onPlayerStateChanged.listen((state) {
      isPlaying = state == PlayerState.playing;
      _stateChanged.add(null);
    });

    _player.onDurationChanged.listen((d) {
      duration = d;
      _stateChanged.add(null);
    });

    _player.onPositionChanged.listen((p) {
      position = p;
      _stateChanged.add(null);
    });

    _player.setReleaseMode(ReleaseMode.stop);
  }

  // ========================
  // Playback controls
  // ========================

  Future<void> playFile(String path) async {
    await _player.stop();
    await _player.setSource(DeviceFileSource(path));
    await _player.resume();
  }

  Future<void> pause() async {
    await _player.pause();
  }

  Future<void> resume() async {
    await _player.resume();
  }

  Future<void> stop() async {
    await _player.stop();
    position = Duration.zero;
    _stateChanged.add(null);
  }

  Future<void> seek(Duration newPosition) async {
    await _player.seek(newPosition);
  }

  Future<void> setSpeed(double speed) async {
    playbackSpeed = speed;
    await _player.setPlaybackRate(speed);
    _stateChanged.add(null);
  }

  void dispose() {
    _stateChanged.close();
    _player.dispose();
  }
}
