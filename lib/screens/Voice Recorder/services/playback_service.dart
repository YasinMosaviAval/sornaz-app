import 'package:sornaz/helpers/browser_bridge.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:sornaz/components/ab_repeat.dart';
import 'dart:io';
import 'package:just_audio/just_audio.dart';

class PlaybackService {
  final AudioPlayer _player = AudioPlayer();
  final List<StreamSubscription> _subscriptions = [];
  String? currentPath;
  bool isPlaying = false;
  Duration position = Duration.zero, duration = Duration.zero;
  void Function()? onChanged;
  final abRepeat = AbRepeat();
  bool _seeking = false;
  void cycleAbRepeat() {
    abRepeat.cycle(position);
    onChanged?.call();
  }

  PlaybackService() {
    _subscriptions.add(
      _player.playerStateStream.listen((state) {
        isPlaying =
            state.playing && state.processingState != ProcessingState.completed;
        onChanged?.call();
      }),
    );
    _subscriptions.add(
      _player.positionStream.listen((p) {
        position = p;
        if (!_seeking && abRepeat.shouldLoop(p)) {
          _seeking = true;
          _player.seek(abRepeat.start!).whenComplete(() => _seeking = false);
        }
        onChanged?.call();
      }),
    );
    _subscriptions.add(
      _player.durationStream.listen((d) {
        duration = d ?? Duration.zero;
        onChanged?.call();
      }),
    );
  }
  Future<void> play(String path, {bool autoplay = true}) async {
    if (currentPath == path && isPlaying) {
      await _player.pause();
      return;
    }
    if (currentPath != path) {
      abRepeat.clear();
      await _player.stop();
      currentPath = null;
      position = Duration.zero;
      duration = Duration.zero;
      // ExoPlayer's content data source opens MediaStore URIs through Android.
      final source = kIsWeb
          ? await browserCall('recordingsUrl', {'id': path}) as String
          : path;
      await _player.setAudioSource(
        AudioSource.uri(
          (kIsWeb || path.startsWith('content://'))
              ? Uri.parse(source)
              : Uri.file(path),
        ),
      );
      currentPath = path;
    }
    if (!autoplay) return;
    if (_player.processingState == ProcessingState.completed ||
        (duration > Duration.zero && position >= duration)) {
      await _player.seek(Duration.zero);
    }
    unawaited(_player.play());
  }

  Future<void> stop() async {
    await _player.stop();
    isPlaying = false;
    currentPath = null;
    position = Duration.zero;
    onChanged?.call();
  }

  Future<void> seek(Duration p) async {
    final target = Duration(
      milliseconds: p.inMilliseconds.clamp(0, duration.inMilliseconds),
    );
    await _player.seek(target);
    position = target;
    onChanged?.call();
  }

  Future<void> toggle(File file) => play(file.path);
  void dispose() {
    onChanged = null;
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _player.dispose();
  }
}
