import '../../Players/services/music_audio_handler.dart';
import 'package:sornaz/helpers/browser_bridge.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:sornaz/components/ab_repeat.dart';
import 'dart:io';
import '../../Players/playback/playback_queue_manager.dart';
import 'package:just_audio/just_audio.dart';

class PlaybackService {
  final AudioPlayer _player;
  final DateTime Function() _now;
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
  bool _loading = false;
  bool _needsReload = false;
  bool _completionHandled = false;
  Future<void> _pending = Future.value();
  Future<void> _serialize(Future<void> Function() operation) {
    final next = _pending.then((_) => operation());
    _pending = next.catchError((Object _) {});
    return next;
  }

  void _startPlayback() {
    _completionHandled = false;
    unawaited(
      _player.play().catchError((Object _) {
        isPlaying = false;
        _needsReload = true;
        _loading = false;
        changed();
      }),
    );
  }

  final _positionClock = Stopwatch()..start();
  static final titles = <String, String>{};
  Duration get displayPosition {
    final milliseconds =
        position.inMilliseconds +
        (isPlaying ? (_positionClock.elapsedMilliseconds * speed).round() : 0);
    return Duration(
      milliseconds: milliseconds.clamp(0, duration.inMilliseconds),
    );
  }

  void changed() {
    final handler = musicAudioHandler;
    if (handler != null &&
        identical(handler.owner, this) &&
        currentPath != null) {
      handler.publish(
        id: currentPath!,
        title: titles[currentPath!] ?? currentPath!.split('/').last,
        duration: duration,
        position: position,
        playing: isPlaying,
        loading: false,
        speed: speed,
        undo: isUndoMode,
      );
    }
    onChanged?.call();
  }

  Future<void> activateMedia() async {
    if (currentPath == null || !paths.contains(currentPath)) return;
    await musicAudioHandler?.activate(
      this,
      play: resume,
      pause: pause,
      stop: stop,
      previous: previousOrUndo,
      next: nextWithUndo,
      seek: (at) async {
        rememberPosition();
        await seek(at);
      },
    );
  }

  Future<void> resume() => _serialize(() async {
    await activateMedia();
    if (position >= duration && duration > Duration.zero)
      await _seekNow(Duration.zero);
    _positionClock.reset();
    _startPlayback();
  });

  final _history =
      <({String path, Duration position, DateTime time, List<String> paths})>[];
  Timer? _undoTimer;
  void _pruneHistory() => _history.removeWhere(
    (item) => _now().difference(item.time) >= const Duration(seconds: 10),
  );
  bool get isUndoMode {
    _pruneHistory();
    return _history.isNotEmpty;
  }

  void rememberPosition() {
    if (currentPath == null) return;
    _pruneHistory();
    _history.add((
      path: currentPath!,
      position: displayPosition,
      time: _now(),
      paths: List.of(paths),
    ));
    _undoTimer?.cancel();
    _undoTimer = Timer.periodic(const Duration(milliseconds: 250), (_) {
      _pruneHistory();
      if (_history.isEmpty) _undoTimer?.cancel();
      changed();
    });
    changed();
  }

  Future<void> previousOrUndo() => _serialize(() async {
    _pruneHistory();
    if (_history.isEmpty) {
      await _move(queue.previous());
      return;
    }
    final item = _history.removeLast();
    setQueue(item.paths, item.path);
    if (currentPath != item.path) await _play(item.path);
    await _seekNow(item.position);
  });

  Future<void> skip(Duration delta) => _serialize(() async {
    rememberPosition();
    await _seekNow(displayPosition + delta);
  });

  void setQueue(Iterable<String> items, String current) {
    paths = items.toList();
    queue.setQueue(paths.length);
    queue.setCurrentIndex(paths.indexOf(current));
  }

  void toggleShuffle() {
    queue.toggleShuffle();
    queue.rebuildOrder(queueLength: paths.length);
    changed();
  }

  void toggleRepeat() {
    queue.toggleRepeat();
    changed();
  }

  void toggleTime() {
    showRemaining = !showRemaining;
    changed();
  }

  Future<void> setSpeed(double value) async {
    await _player.setSpeed(value);
    speed = value;
    changed();
  }

  Future<void> next() => _serialize(() => _move(queue.next()));
  Future<void> nextWithUndo() => _serialize(() async {
    rememberPosition();
    await _move(queue.next());
  });

  Future<void> previous() => _serialize(() => _move(queue.previous()));
  Future<void> _move(int? index) async {
    if (index == null || index < 0 || index >= paths.length) return;
    queue.setCurrentIndex(index);
    if (currentPath == paths[index]) {
      await _seekNow(Duration.zero);
      if (!isPlaying) await _play(paths[index]);
    } else {
      await _play(paths[index]);
    }
  }

  Future<void> pause() => _serialize(_player.pause);
  Future<void> toggleCurrent() async {
    final path = currentPath ?? paths.firstOrNull;
    if (path != null) await play(path);
  }

  void cycleAbRepeat() {
    abRepeat.cycle(position);
    changed();
  }

  PlaybackService({AudioPlayer? player, DateTime Function()? now})
    : _player = player ?? AudioPlayer(),
      _now = now ?? DateTime.now {
    _subscriptions.add(
      _player.playerStateStream.listen((state) {
        isPlaying =
            state.playing && state.processingState != ProcessingState.completed;
        changed();
        if (state.processingState == ProcessingState.completed &&
            !_advancing &&
            !_loading &&
            !_completionHandled) {
          _completionHandled = true;
          _advancing = true;
          final operation = abRepeat.active
              ? seek(abRepeat.start!).then((_) {
                  _startPlayback();
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
        _positionClock.reset();
        if (!_seeking && abRepeat.shouldLoop(p)) {
          _seeking = true;
          position = abRepeat.start!;
          seek(
            position,
          ).catchError((Object _) {}).whenComplete(() => _seeking = false);
        }
        changed();
      }),
    );
    _subscriptions.add(
      _player.durationStream.listen((d) {
        duration = d ?? Duration.zero;
        changed();
      }),
    );
  }
  Future<void> play(String path, {bool autoplay = true}) =>
      _serialize(() => _play(path, autoplay: autoplay));
  Future<void> _play(String path, {bool autoplay = true}) async {
    _loading = true;
    try {
      if (currentPath == path && isPlaying) {
        if (autoplay) await _player.pause();
        return;
      }
      if (currentPath != path || _needsReload) {
        abRepeat.clear();
        await _player.stop();
        currentPath = null;
        position = Duration.zero;
        duration = Duration.zero;
        // ExoPlayer's content data source opens MediaStore URIs through Android.
        final source = kIsWeb
            ? await browserCall('recordingsUrl', {'id': path}) as String
            : path;
        duration =
            await _player.setAudioSource(
              AudioSource.uri(
                (kIsWeb || path.startsWith('content://'))
                    ? Uri.parse(source)
                    : Uri.file(path),
              ),
            ) ??
            Duration.zero;
        currentPath = path;
        _needsReload = false;
        queue.setCurrentIndex(paths.indexOf(path));
        changed();
      }
      if (!autoplay) return;
      await activateMedia();
      _positionClock.reset();
      if (_player.processingState == ProcessingState.completed ||
          (duration > Duration.zero && position >= duration)) {
        await _player.seek(Duration.zero);
      }
      _startPlayback();
    } catch (_) {
      currentPath = null;
      isPlaying = false;
      rethrow;
    } finally {
      _loading = false;
      changed();
    }
  }

  Future<void> stop() => _serialize(() async {
    musicAudioHandler?.release(this);
    await _player.stop();
    isPlaying = false;
    currentPath = null;
    position = Duration.zero;
    duration = Duration.zero;
    abRepeat.clear();
    _undoTimer?.cancel();
    _history.clear();
    paths = [];
    queue.setQueue(0);
    changed();
  });

  Future<void> seek(Duration p) => _serialize(() => _seekNow(p));
  Future<void> _seekNow(Duration p) async {
    final target = Duration(
      milliseconds: p.inMilliseconds.clamp(0, duration.inMilliseconds),
    );
    await _player.seek(target);
    position = target;
    _positionClock.reset();
    if (target < duration) _completionHandled = false;
    changed();
  }

  Future<void> toggle(File file) => play(file.path);
  void dispose() {
    musicAudioHandler?.release(this);
    _undoTimer?.cancel();
    onChanged = null;
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _player.dispose();
  }
}
