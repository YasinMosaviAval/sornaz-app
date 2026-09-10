import 'dart:async';
import 'package:audioplayers/audioplayers.dart';

class AudioPlayerController {
  final AudioPlayer _player = AudioPlayer();
  final List<StreamSubscription> _subscriptions = [];
  
  Duration duration = Duration.zero;
  Duration position = Duration.zero;
  double playbackSpeed = 1.0;
  bool isPlaying = false;
  String? _path;

  final StreamController<void> _stateChanged = StreamController.broadcast();
  final StreamController<void> _completeChanged = StreamController.broadcast(); // جدید: برای complete

  Stream<void> get onStateChanged => _stateChanged.stream;
  Stream<void> get onComplete => _completeChanged.stream; // جدید

  AudioPlayerController() {
    _initListeners();
  }

  void _initListeners() {
    _subscriptions.add(_player.onPlayerStateChanged.listen((state) {
      isPlaying = state == PlayerState.playing;
      _stateChanged.add(null);
    }));

    _subscriptions.add(_player.onDurationChanged.listen((d) {
      if (d > Duration.zero) duration = d;
      _stateChanged.add(null);
    }));

    _subscriptions.add(_player.onPositionChanged.listen((p) {
      position = p;
      _stateChanged.add(null);
    }));

    _subscriptions.add(_player.onPlayerComplete.listen((_) {
      _completeChanged.add(null);
    }));

    _player.setReleaseMode(ReleaseMode.stop);
  }

  // ========================
  // Playback controls
  // ========================

  Future<void> playFile(String path) async {
    await _player.stop();
    if (_path != path) duration = Duration.zero;
    _path = path;
    position = Duration.zero;
    await _player.setSource(DeviceFileSource(path));
    final loaded = await _player.getDuration();
    if (loaded != null && loaded > Duration.zero) duration = loaded;
    await _player.seek(Duration.zero);
    await _player.resume();
    _stateChanged.add(null);
  }

  Future<void> pause() async => await _player.pause();

  Future<void> resume() async {
    if (_path == null) return;
    if (duration > Duration.zero && position >= duration) await seek(Duration.zero);
    await _player.resume();
    final loaded = await _player.getDuration();
    if (loaded != null && loaded > Duration.zero) duration = loaded;
    _stateChanged.add(null);
  }

  Future<void> stop() async {
    await _player.stop();
    position = Duration.zero;
    _stateChanged.add(null);
  }

  Future<void> seek(Duration newPosition) async {
    final safePosition = Duration(milliseconds: newPosition.inMilliseconds.clamp(0, duration.inMilliseconds));
    await _player.seek(safePosition);
    position = safePosition;
    _stateChanged.add(null);
  }

  Future<void> setSpeed(double speed) async {
    playbackSpeed = speed;
    await _player.setPlaybackRate(speed);
    _stateChanged.add(null);
  }

  Future<void> playFileAndSeek(String path, Duration position) async {
    await _player.stop();
    await _player.setSource(DeviceFileSource(path));
    await _player.seek(position);
    await _player.resume();
  }

  void dispose() {
    for (final subscription in _subscriptions) { subscription.cancel(); }
    _stateChanged.close();
    _completeChanged.close();
    _player.dispose();
  }
}
