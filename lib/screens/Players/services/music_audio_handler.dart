import 'player_settings.dart';
import 'package:audio_service/audio_service.dart';

MusicAudioHandler? musicAudioHandler;

/// Bridges system media controls to the same player used by the application.
class MusicAudioHandler extends BaseAudioHandler {
  MusicAudioHandler({this.customUndo = false});
  final bool customUndo;
  bool _undoVisible = false;
  Object? owner;
  Future<void> activate(
    Object nextOwner, {
    required Future<void> Function() play,
    required Future<void> Function() pause,
    required Future<void> Function() stop,
    required Future<void> Function() previous,
    required Future<void> Function() next,
    required Future<void> Function(Duration) seek,
  }) async {
    if (owner != null && !identical(owner, nextOwner)) await onPause?.call();
    owner = nextOwner;
    onPlay = play;
    onPause = pause;
    onStop = stop;
    onPrevious = previous;
    onNext = next;
    onSeek = seek;
  }

  void release(Object currentOwner) {
    if (!identical(owner, currentOwner)) return;
    owner = null;
    onPlay = null;
    onPause = null;
    onStop = null;
    onPrevious = null;
    onNext = null;
    onSeek = null;
    clear();
  }

  Future<void> Function()? onPlay, onPause, onStop, onNext, onPrevious;
  Future<void> Function(Duration)? onSeek;
  Future<void> Function()? onRewind, onForward;
  @override
  Future<void> play() async => onPlay?.call();
  @override
  Future<void> pause() async => onPause?.call();
  @override
  Future<void> seek(Duration position) async => onSeek?.call(position);
  @override
  Future<void> skipToNext() async => onNext?.call();
  @override
  Future<void> skipToPrevious() async => onPrevious?.call();
  @override
  Future<dynamic> customAction(
    String name, [
    Map<String, dynamic>? extras,
  ]) async {
    if (name == 'undoPlayback') return onPrevious?.call();
    return super.customAction(name, extras);
  }

  @override
  Future<void> rewind() async =>
      _undoVisible ? onPrevious?.call() : onRewind?.call();
  @override
  Future<void> fastForward() async => onForward?.call();
  @override
  Future<void> stop() async {
    try {
      await onStop?.call();
    } finally {
      clear();
    }
  }

  @override
  Future<void> onNotificationDeleted() => stop();
  @override
  Future<void> onTaskRemoved() async {
    await PlayerSettings.instance.load();
    if (PlayerSettings.instance.stopsFor(PlaybackInterruption.exitApp) ||
        !playbackState.value.playing)
      await stop();
  }

  void clear() {
    playbackState.add(
      PlaybackState(processingState: AudioProcessingState.idle),
    );
    mediaItem.add(null);
  }

  void publish({
    required String id,
    required String title,
    String? artist,
    required Duration duration,
    required Duration position,
    required bool playing,
    required bool loading,
    required double speed,
    bool undo = false,
  }) {
    _undoVisible = undo;
    final item = mediaItem.valueOrNull;
    if (item?.id != id ||
        item?.title != title ||
        item?.artist != artist ||
        item?.duration != duration) {
      mediaItem.add(
        MediaItem(id: id, title: title, artist: artist, duration: duration),
      );
    }
    playbackState.add(
      PlaybackState(
        controls: [
          undo
              ? const MediaControl(
                  androidIcon: 'drawable/ic_playback_undo',
                  label: 'Undo',
                  action: MediaAction.rewind,
                )
              : MediaControl.skipToPrevious,
          playing ? MediaControl.pause : MediaControl.play,
          MediaControl.skipToNext,
          const MediaControl(
            androidIcon: 'drawable/ic_close_playback',
            label: 'Stop',
            action: MediaAction.stop,
          ),
        ],
        androidCompactActionIndices: const [0, 1, 2],
        systemActions: const {
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
        },
        processingState: loading
            ? AudioProcessingState.loading
            : AudioProcessingState.ready,
        playing: playing,
        updatePosition: position,
        bufferedPosition: duration,
        speed: speed,
      ),
    );
  }
}
