import 'package:audio_service/audio_service.dart';

MusicAudioHandler? musicAudioHandler;

/// Bridges system media controls to the same player used by the application.
class MusicAudioHandler extends BaseAudioHandler {
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
  Future<void> rewind() async => onRewind?.call();
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
    if (!playbackState.value.playing) await stop();
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
  }) {
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
          MediaControl.skipToPrevious,
          const MediaControl(
            androidIcon: 'drawable/ic_rewind_10',
            label: 'Rewind 10 seconds',
            action: MediaAction.rewind,
          ),
          playing ? MediaControl.pause : MediaControl.play,
          const MediaControl(
            androidIcon: 'drawable/ic_forward_10',
            label: 'Forward 10 seconds',
            action: MediaAction.fastForward,
          ),
          MediaControl.skipToNext,
          const MediaControl(
            androidIcon: 'drawable/ic_close_playback',
            label: 'Stop',
            action: MediaAction.stop,
          ),
        ],
        androidCompactActionIndices: const [0, 2, 4],
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
