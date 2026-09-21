import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart' as just;
import '../services/equalizer_settings.dart';

class AudioPlayerController {
  final bool _useAndroid =
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  late final AudioPlayer _player = AudioPlayer();
  late final just.AudioPlayer _android = just.AudioPlayer();
  final equalizer = EqualizerSettings();
  final List<StreamSubscription> _subscriptions = [];
  Duration duration = Duration.zero, position = Duration.zero;
  double playbackSpeed = 1;
  bool isPlaying = false, _disposed = false, _completed = false;
  String? _path;
  final _stateChanged = StreamController<void>.broadcast(),
      _completeChanged = StreamController<void>.broadcast();
  Stream<void> get onStateChanged => _stateChanged.stream;
  Stream<void> get onComplete => _completeChanged.stream;
  void changed() {
    if (!_disposed) _stateChanged.add(null);
  }

  AudioPlayerController() {
    if (_useAndroid) {
      _subscriptions.add(
        _android.androidAudioSessionIdStream.listen((id) {
          unawaited(equalizer.attach(id));
        }),
      );
      _subscriptions.add(
        _android.playerStateStream.listen((s) {
          isPlaying =
              s.playing && s.processingState != just.ProcessingState.completed;
          changed();
          if (s.processingState == just.ProcessingState.completed &&
              !_completed) {
            _completed = true;
            _completeChanged.add(null);
          }
        }),
      );
      _subscriptions.add(
        _android.durationStream.listen((d) {
          if (d != null && d > Duration.zero) duration = d;
          changed();
        }),
      );
      _subscriptions.add(
        _android.positionStream.listen((p) {
          position = p;
          changed();
        }),
      );
    } else {
      _subscriptions.add(
        _player.onPlayerStateChanged.listen((s) {
          isPlaying = s == PlayerState.playing;
          changed();
        }),
      );
      _subscriptions.add(
        _player.onDurationChanged.listen((d) {
          if (d > Duration.zero) duration = d;
          changed();
        }),
      );
      _subscriptions.add(
        _player.onPositionChanged.listen((p) {
          position = p;
          changed();
        }),
      );
      _subscriptions.add(
        _player.onPlayerComplete.listen((_) {
          _completeChanged.add(null);
        }),
      );
      _player.setReleaseMode(ReleaseMode.stop);
    }
  }
  Future<void> playFile(String path) async {
    await pause();
    if (_path != path) duration = Duration.zero;
    _path = path;
    position = Duration.zero;
    _completed = false;
    if (_useAndroid) {
      final d = await _android.setFilePath(path);
      if (d != null && d > Duration.zero) duration = d;
      await _android.setSpeed(playbackSpeed);
      await equalizer.attach(_android.androidAudioSessionId);
      unawaited(_android.play());
    } else {
      await _player.stop();
      await _player.setSource(DeviceFileSource(path));
      final d = await _player.getDuration();
      if (d != null && d > Duration.zero) duration = d;
      await _player.setPlaybackRate(playbackSpeed);
      await _player.seek(Duration.zero);
      await _player.resume();
    }
    changed();
  }

  Future<void> pause() async {
    if (_useAndroid) {
      await _android.pause();
    } else {
      await _player.pause();
    }
  }

  Future<void> resume() async {
    if (_path == null) return;
    if (position >= duration && duration > Duration.zero)
      await seek(Duration.zero);
    _completed = false;
    if (_useAndroid) {
      unawaited(_android.play());
    } else {
      await _player.resume();
      final d = await _player.getDuration();
      if (d != null && d > Duration.zero) duration = d;
    }
    changed();
  }

  Future<void> stop() async {
    await pause();
    await seek(Duration.zero);
    isPlaying = false;
    changed();
  }

  Future<void> seek(Duration target) async {
    final safe = Duration(
      milliseconds: target.inMilliseconds.clamp(0, duration.inMilliseconds),
    );
    if (_useAndroid) {
      await _android.seek(safe);
    } else {
      await _player.seek(safe);
    }
    position = safe;
    _completed = false;
    changed();
  }

  Future<void> setSpeed(double value) async {
    if (_useAndroid) {
      await _android.setSpeed(value);
    } else {
      await _player.setPlaybackRate(value);
    }
    playbackSpeed = value;
    changed();
  }

  Future<void> playFileAndSeek(String path, Duration target) async {
    await playFile(path);
    await seek(target);
  }

  void dispose() {
    _disposed = true;
    equalizer.dispose();
    for (final s in _subscriptions) {
      s.cancel();
    }
    _stateChanged.close();
    _completeChanged.close();
    if (_useAndroid) {
      _android.dispose();
    } else {
      _player.dispose();
    }
  }
}
