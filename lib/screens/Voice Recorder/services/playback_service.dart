import 'package:sornaz/helpers/browser_bridge.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:sornaz/components/ab_repeat.dart';
import 'dart:io';
import '../../Players/playback/playback_queue_manager.dart';
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
  final queue = PlaybackQueueManager();
  List<String> paths = [];
  double speed = 1;
  static const speedOptions = <double>[
    .25,
    .5,
    .75,
    1,
    1.25,
    1.5,
    1.75,
    2,
    3,
    4,
  ];
  bool showRemaining = false;
  bool _advancing = false;
  String? _undoPath;
  Duration _undoPosition = Duration.zero;
  Timer? _undoTimer;
  bool get isUndoMode => _undoPath != null;
  void rememberPosition() {
    _undoPath = currentPath;
    _undoPosition = position;
    _undoTimer?.cancel();
    _undoTimer = Timer(const Duration(seconds: 10), () {
      _undoPath = null;
      onChanged?.call();
    });
    onChanged?.call();
  }

  Future<void> previousOrUndo() async {
    final path = _undoPath;
    if (path == null) {
      await previous();
      return;
    }
    final at = _undoPosition;
    _undoTimer?.cancel();
    _undoPath = null;
    if (currentPath != path) await play(path);
    await seek(at);
  }

  Future<void> skip(Duration delta) async {
    rememberPosition();
    await seek(position + delta);
  }

  void setQueue(Iterable<String> items, String current) {
    paths = items.toList();
    queue.setQueue(paths.length);
    queue.setCurrentIndex(paths.indexOf(current));
  }

  void toggleShuffle() {
    queue.toggleShuffle();
    queue.rebuildOrder(queueLength: paths.length);
    onChanged?.call();
  }

  void toggleRepeat() {
    queue.toggleRepeat();
    onChanged?.call();
  }

  void toggleTime() {
    showRemaining = !showRemaining;
    onChanged?.call();
  }

  Future<void> setSpeed(double value) async {
    await _player.setSpeed(value);
    speed = value;
    onChanged?.call();
  }

  Future<void> next() => _move(queue.next());
  Future<void> nextWithUndo() async {
    rememberPosition();
    await next();
  }

  Future<void> previous() => _move(queue.previous());
  Future<void> _move(int? index) async {
    if (index == null || index < 0 || index >= paths.length) return;
    queue.setCurrentIndex(index);
    if (currentPath == paths[index]) {
      await seek(Duration.zero);
      if (!isPlaying) await play(paths[index]);
    } else {
      await play(paths[index]);
    }
  }

  Future<void> pause() => _player.pause();
  Future<void> toggleCurrent() async {
    final path = currentPath ?? paths.firstOrNull;
    if (path != null) await play(path);
  }

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
        if (state.processingState == ProcessingState.completed && !_advancing) {
          _advancing = true;
          final operation = abRepeat.active
              ? seek(abRepeat.start!).then((_) {
                  unawaited(_player.play());
                })
              : next();
          operation
              .catchError((Object _) {})
              .whenComplete(() => _advancing = false);
        }
      }),
    );
    _subscriptions.add(
      _player.positionStream.listen((p) {
        position = p;
        if (!_seeking && abRepeat.shouldLoop(p)) {
          _seeking = true;
          position = abRepeat.start!;
          _player.seek(position).whenComplete(() => _seeking = false);
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
      if (autoplay) await _player.pause();
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
      queue.setCurrentIndex(paths.indexOf(path));
      onChanged?.call();
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
    duration = Duration.zero;
    abRepeat.clear();
    _undoTimer?.cancel();
    _undoPath = null;
    paths = [];
    queue.setQueue(0);
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
    _undoTimer?.cancel();
    onChanged = null;
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _player.dispose();
  }
}
