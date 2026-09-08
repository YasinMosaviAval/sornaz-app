import 'dart:async';
import 'dart:io';
import 'package:just_audio/just_audio.dart';

class PlaybackService {
  final AudioPlayer _player = AudioPlayer();
  final List<StreamSubscription> _subscriptions = [];
  String? currentPath;
  bool isPlaying = false;
  Duration position = Duration.zero, duration = Duration.zero;
  void Function()? onChanged;
  PlaybackService() {
    _subscriptions.add(_player.playerStateStream.listen((state) {
      isPlaying = state.playing && state.processingState != ProcessingState.completed;
      onChanged?.call();
    }));
    _subscriptions.add(_player.positionStream.listen((p) {
      position = p;
      onChanged?.call();
    }));
    _subscriptions.add(_player.durationStream.listen((d) {
      duration = d ?? Duration.zero;
      onChanged?.call();
    }));
  }
  Future<void> play(String path) async {
    if (currentPath == path && isPlaying) {
      await _player.pause();
      return;
    }
    if (currentPath != path) {
      await _player.stop();
      currentPath = null;
      position = Duration.zero;
      duration = Duration.zero;
      // ExoPlayer's content data source opens MediaStore URIs through Android.
      await _player.setAudioSource(AudioSource.uri(
        path.startsWith('content://') ? Uri.parse(path) : Uri.file(path),
      ));
      currentPath = path;
    }
    if (_player.processingState == ProcessingState.completed) {
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
  Future<void> seek(Duration p) => _player.seek(p);
  Future<void> toggle(File file) => play(file.path);
  void dispose() {
    onChanged = null;
    for (final subscription in _subscriptions) { subscription.cancel(); }
    _player.dispose();
  }
}
