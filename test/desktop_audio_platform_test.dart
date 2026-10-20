import 'dart:async';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart' as audio;
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio_platform_interface/just_audio_platform_interface.dart';
import 'package:path/path.dart' as p;
import 'package:sornaz/helpers/desktop_audio_platform.dart';

class _Engine extends Fake implements audio.AudioPlayer {
  final durations = StreamController<Duration>.broadcast();
  final completions = StreamController<void>.broadcast();
  audio.Source? source;
  Duration position = Duration.zero;
  bool playing = false, disposed = false;
  @override
  Stream<Duration> get onDurationChanged => durations.stream;
  @override
  Stream<void> get onPlayerComplete => completions.stream;
  @override
  Future<void> stop() async {
    playing = false;
  }

  @override
  Future<void> setReleaseMode(audio.ReleaseMode mode) async {}
  @override
  Future<void> setSource(audio.Source value) async {
    source = value;
  }

  @override
  Future<Duration?> getDuration() async => const Duration(seconds: 2);
  @override
  Future<Duration?> getCurrentPosition() async => position;
  @override
  Future<void> seek(Duration value) async {
    position = value;
  }

  @override
  Future<void> setPlaybackRate(double value) async {}
  @override
  Future<void> setVolume(double value) async {}
  @override
  Future<void> resume() async {
    playing = true;
  }

  @override
  Future<void> pause() async {
    playing = false;
  }

  @override
  Future<void> dispose() async {
    disposed = true;
    await durations.close();
    await completions.close();
  }
}

void main() {
  test(
    'play before loading and replacing a playing source preserve playback',
    () async {
      final engine = _Engine();
      final platform = DesktopAudioPlatform(createPlayer: () => engine);
      final player = await platform.init(InitRequest(id: 'preload'));
      try {
        final playing = player.play(PlayRequest());
        expect(engine.playing, false);
        final source = ProgressiveAudioSourceMessage(
          id: 'sample',
          uri: File(
            p.join(Directory.systemTemp.path, 'tick.wav'),
          ).uri.toString(),
        );
        await player.load(LoadRequest(audioSourceMessage: source));
        expect(engine.playing, true);
        await player.load(LoadRequest(audioSourceMessage: source));
        expect(engine.playing, true);
        await player.pause(PauseRequest());
        await playing;
      } finally {
        await platform.disposeAllPlayers(DisposeAllPlayersRequest());
      }
    },
  );
  test('completed metronome sample restarts when seeking to zero', () async {
    final engine = _Engine();
    final platform = DesktopAudioPlatform(createPlayer: () => engine);
    final player = await platform.init(InitRequest(id: 'repeat'));
    try {
      await player.load(
        LoadRequest(
          audioSourceMessage: ProgressiveAudioSourceMessage(
            id: 'sample',
            uri: File(
              p.join(Directory.systemTemp.path, 'tick.wav'),
            ).uri.toString(),
          ),
        ),
      );
      final playing = player.play(PlayRequest());
      await Future<void>.delayed(Duration.zero);
      engine.completions.add(null);
      await playing;
      await Future<void>.delayed(Duration.zero);
      expect(engine.playing, false);
      await player.seek(SeekRequest(position: Duration.zero));
      expect(engine.playing, true);
      expect(engine.position, Duration.zero);
      await player.pause(PauseRequest());
    } finally {
      await platform.disposeAllPlayers(DisposeAllPlayersRequest());
    }
  });
  test(
    'Windows preview engine preserves Unicode file paths and finite duration',
    () async {
      final engine = _Engine();
      final platform = DesktopAudioPlatform(createPlayer: () => engine);
      final player = await platform.init(InitRequest(id: 'file'));
      final path = p.join(Directory.systemTemp.path, 'آهنگ من.wav');
      try {
        final response = await player.load(
          LoadRequest(
            audioSourceMessage: ProgressiveAudioSourceMessage(
              id: 'source',
              uri: File(path).uri.toString(),
            ),
          ),
        );
        expect((engine.source as audio.DeviceFileSource).path, path);
        expect(response.duration, const Duration(seconds: 2));
      } finally {
        await platform.disposeAllPlayers(DisposeAllPlayersRequest());
      }
      expect(engine.disposed, true);
    },
  );
  test(
    'clip seeks stay relative and pause completes the pending play request',
    () async {
      final engine = _Engine();
      final platform = DesktopAudioPlatform(createPlayer: () => engine);
      final player = await platform.init(InitRequest(id: 'clip'));
      try {
        final loaded = await player.load(
          LoadRequest(
            audioSourceMessage: ClippingAudioSourceMessage(
              id: 'clip-source',
              child: ProgressiveAudioSourceMessage(
                id: 'source',
                uri: File(
                  p.join(Directory.systemTemp.path, 'clip.wav'),
                ).uri.toString(),
              ),
              start: const Duration(milliseconds: 100),
              end: const Duration(milliseconds: 700),
            ),
          ),
        );
        expect(loaded.duration, const Duration(milliseconds: 600));
        await player.seek(
          SeekRequest(position: const Duration(milliseconds: 200)),
        );
        expect(engine.position, const Duration(milliseconds: 300));
        var completed = false;
        final playing = player.play(PlayRequest()).then((_) {
          completed = true;
        });
        await Future<void>.delayed(Duration.zero);
        expect(engine.playing, true);
        expect(completed, false);
        await player.pause(PauseRequest());
        await playing;
        expect(completed, true);
        expect(engine.playing, false);
      } finally {
        await platform.disposeAllPlayers(DisposeAllPlayersRequest());
      }
    },
  );
  test(
    'unsupported source fails explicitly instead of pretending to load',
    () async {
      final engine = _Engine();
      final platform = DesktopAudioPlatform(createPlayer: () => engine);
      final player = await platform.init(InitRequest(id: 'unsupported'));
      try {
        await expectLater(
          player.load(
            LoadRequest(
              audioSourceMessage: ConcatenatingAudioSourceMessage(
                id: 'list',
                children: [],
                useLazyPreparation: false,
                shuffleOrder: [],
              ),
            ),
          ),
          throwsA(isA<UnsupportedError>()),
        );
      } finally {
        await platform.disposeAllPlayers(DisposeAllPlayersRequest());
      }
    },
  );
}
