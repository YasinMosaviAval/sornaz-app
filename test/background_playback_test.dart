import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sornaz/screens/Players/library/audio_library_manager.dart';
import 'package:sornaz/screens/Players/providers/audio_player_provider.dart';
import 'package:sornaz/screens/Players/services/music_audio_handler.dart';
import 'package:sornaz/screens/Players/services/player_settings.dart';

import 'player_behavior_revision_test.dart' show FolderAudio, MemoryController;

class TransitionController extends MemoryController {
  Completer<void>? pendingTrack;

  @override
  Future<void> playFile(String path) async {
    isPlaying = false;
    changes.add(null);
    await pendingTrack?.future;
    await super.playFile(path);
    changes.add(null);
  }
}

void publish(
  MusicAudioHandler handler, {
  bool playing = true,
  bool loading = false,
}) {
  handler.publish(
    id: 'track',
    title: 'Track',
    duration: const Duration(minutes: 5),
    position: Duration.zero,
    playing: playing,
    loading: loading,
    speed: 1,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await PlayerSettings.instance.setStop(PlaybackInterruption.exitApp, false);
  });

  tearDown(() => musicAudioHandler = null);

  test('service config keeps Android foreground protection during pauses', () {
    // Constructing the production config also validates audio_service's
    // assertion against incompatible notification/foreground options.
    expect(
      MusicAudioHandler.serviceConfig.androidStopForegroundOnPause,
      isFalse,
    );
  });

  for (final processing in [
    AudioProcessingState.ready,
    AudioProcessingState.loading,
    AudioProcessingState.buffering,
  ]) {
    test(
      'removing task preserves background playback in $processing',
      () async {
        final handler = MusicAudioHandler();
        var stopped = false;
        handler.onStop = () async => stopped = true;
        publish(handler, playing: processing == AudioProcessingState.ready);
        handler.playbackState.add(
          handler.playbackState.value.copyWith(processingState: processing),
        );
        await handler.onTaskRemoved();
        expect(stopped, isFalse);
        expect(handler.mediaItem.value?.id, 'track');
      },
    );
  }

  test('removing a paused task releases the session', () async {
    final handler = MusicAudioHandler();
    var stopped = false;
    handler.onStop = () async => stopped = true;
    publish(handler, playing: false);
    await handler.onTaskRemoved();
    expect(stopped, isTrue);
    expect(
      handler.playbackState.value.processingState,
      AudioProcessingState.idle,
    );
    expect(handler.mediaItem.value, isNull);
  });

  test(
    'explicit exit preference stops even during a track transition',
    () async {
      await PlayerSettings.instance.setStop(PlaybackInterruption.exitApp, true);
      final handler = MusicAudioHandler();
      var stopped = false;
      handler.onStop = () async => stopped = true;
      publish(handler, playing: false, loading: true);
      await handler.onTaskRemoved();
      expect(stopped, isTrue);
      expect(
        handler.playbackState.value.processingState,
        AudioProcessingState.idle,
      );
    },
  );

  testWidgets('background queue survives task removal during track change', (
    tester,
  ) async {
    final library = AudioLibraryManager();
    final controller = TransitionController();
    final handler = musicAudioHandler = MusicAudioHandler();
    final player = AudioPlayerProvider(
      libraryManager: library,
      controller: controller,
      playbackSettings: PlayerSettings(),
    );
    try {
      player.setFileList(FolderAudio().allFiles);
      await player.play(0);
      await tester.pump();
      player.didChangeAppLifecycleState(AppLifecycleState.paused);
      player.didChangeAppLifecycleState(AppLifecycleState.detached);
      await tester.pump(const Duration(minutes: 10));
      expect(player.isPlaying, isTrue);

      controller.pendingTrack = Completer<void>();
      final advance = player.onTrackComplete();
      await tester.pump();
      expect(
        handler.playbackState.value.processingState,
        AudioProcessingState.loading,
      );
      expect(handler.playbackState.value.playing, isFalse);
      await tester.runAsync(handler.onTaskRemoved);
      expect(handler.owner, same(player));

      controller.pendingTrack!.complete();
      await advance;
      await tester.pump();
      expect(player.currentIndex, 1);
      expect(player.isPlaying, isTrue);
      expect(handler.playbackState.value.playing, isTrue);

      await handler.pause();
      await tester.pump();
      expect(player.isPlaying, isFalse);
      await handler.play();
      await tester.pump();
      expect(player.isPlaying, isTrue);
      await handler.stop();
      await tester.pump();
      expect(player.isPlaying, isFalse);
      expect(handler.owner, isNull);
      expect(
        handler.playbackState.value.processingState,
        AudioProcessingState.idle,
      );
    } finally {
      player.dispose();
      library.dispose();
    }
  });
}
