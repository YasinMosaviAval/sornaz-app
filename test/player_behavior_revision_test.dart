import 'dart:io';
import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sornaz/screens/Players/playback/playback_history.dart';
import 'package:sornaz/screens/Players/controller/audio_player_controller.dart';
import 'package:sornaz/screens/Players/library/audio_library_manager.dart';
import 'package:sornaz/screens/Players/providers/audio_player_provider.dart';
import 'package:sornaz/screens/Players/scan/audio_file.dart';
import 'package:sornaz/screens/Players/services/music_audio_handler.dart';
import 'package:sornaz/screens/Players/services/music_playlists.dart';
import 'package:sornaz/screens/Players/services/player_settings.dart';
import 'package:sornaz/screens/Players/ui/components/audio_item.dart';
import 'package:sornaz/screens/Players/ui/components/flat_list_view.dart';
import 'package:sornaz/screens/Players/ui/pages/lyrics.dart';
import 'package:sornaz/screens/Voice%20Recorder/ui/components/recording_timer.dart';
import 'player_slides_test.dart' as player_fixture;
import 'social_widget_test.dart' as fixture;

class FolderAudio extends player_fixture.Audio {
  @override
  String get searchQuery => '';
  @override
  List<AudioFile> get allFiles => [
    for (final path in ['/album/parent.mp3', '/album/disc/child.mp3'])
      AudioFile(
        file: File(path),
        fileName: path.split('/').last,
        folderName: File(path).parent.path,
        duration: const Duration(seconds: 5),
      ),
  ];
}

class MemoryController implements AudioPlayerController {
  final changes = StreamController<void>.broadcast();
  final completions = StreamController<void>.broadcast();
  @override
  Stream<void> get onStateChanged => changes.stream;
  @override
  Stream<void> get onComplete => completions.stream;
  @override
  Duration position = Duration.zero, duration = const Duration(minutes: 2);
  @override
  bool isPlaying = false;
  @override
  Future<void> playFile(String path) async {
    isPlaying = true;
    position = Duration.zero;
  }

  @override
  Future<void> stop() async {
    isPlaying = false;
    position = Duration.zero;
  }

  @override
  Future<void> seek(Duration value) async {
    position = value;
  }

  @override
  Future<void> pause() async {
    isPlaying = false;
  }

  @override
  Future<void> resume() async {
    isPlaying = true;
  }

  @override
  void dispose() {
    changes.close();
    completions.close();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('undo expires each change independently and restores newest first', () {
    var now = DateTime(2026);
    final history = PlaybackHistoryManager(now: () => now);
    history.push(index: 0, position: const Duration(seconds: 12));
    now = now.add(const Duration(seconds: 7));
    history.push(index: 1, position: const Duration(seconds: 24));
    now = now.add(const Duration(seconds: 2));
    history.push(index: 2, position: const Duration(seconds: 36));
    now = now.add(const Duration(seconds: 1));
    expect(history.pop()?.index, 2);
    expect(history.pop()?.position, const Duration(seconds: 24));
    expect(history.pop(), isNull);
    expect(history.hasUndo, false);
    history.dispose();
  });

  test(
    'collection rename and delete persist without affecting other lists',
    () async {
      final store = MusicPlaylists(storagePrefix: 'revision');
      await store.create('Practice');
      await store.add('Practice', ['/a.mp3']);
      await store.add(MusicPlaylists.favorite, ['/a.mp3']);
      expect(await store.rename('Practice', 'Evening'), true);
      expect(await store.rename('Evening', 'favorite'), false);
      final reloaded = MusicPlaylists(storagePrefix: 'revision');
      await reloaded.load();
      expect(reloaded.lists['Evening'], ['/a.mp3']);
      expect(reloaded.lists.containsKey('Practice'), false);
      await reloaded.delete('Evening');
      final afterDelete = MusicPlaylists(storagePrefix: 'revision');
      await afterDelete.load();
      expect(afterDelete.lists.keys, [MusicPlaylists.favorite]);
      expect(afterDelete.lists[MusicPlaylists.favorite], ['/a.mp3']);
    },
  );

  test('playback interruption and list end settings survive reload', () async {
    final settings = PlayerSettings();
    await settings.load();
    expect(settings.stopsFor(PlaybackInterruption.leavePlayer), false);
    for (final reason in PlaybackInterruption.values) {
      await settings.setStop(reason, true);
    }
    await settings.setListEnd(ListEndAction.nextList);
    final restored = PlayerSettings();
    await restored.load();
    expect(restored.listEnd, ListEndAction.nextList);
    for (final reason in PlaybackInterruption.values) {
      expect(restored.stopsFor(reason), true);
    }
  });

  test('notification exposes previous, play, next and stop', () async {
    final handler = MusicAudioHandler();
    handler.publish(
      id: 'a',
      title: 'a',
      duration: const Duration(minutes: 1),
      position: Duration.zero,
      playing: false,
      loading: false,
      speed: 1,
    );
    expect(handler.playbackState.value.controls.map((c) => c.action), [
      MediaAction.skipToPrevious,
      MediaAction.play,
      MediaAction.skipToNext,
      MediaAction.stop,
    ]);
    var previous = 0;
    handler.onPrevious = () async {
      previous++;
    };
    await handler.skipToPrevious();
    expect(previous, 1);
    await handler.stop();
    expect(handler.mediaItem.value, isNull);
  });

  testWidgets(
    'list completion, interruption and sleep timer control playback',
    (tester) async {
      final controller = MemoryController();
      final settings = PlayerSettings();
      await settings.load();
      final library = AudioLibraryManager();
      final player = AudioPlayerProvider(
        libraryManager: library,
        controller: controller,
        playbackSettings: settings,
      );
      final files = FolderAudio().allFiles;
      player.setFileList(files);
      await player.play(1);
      await settings.setListEnd(ListEndAction.restart);
      await player.onTrackComplete();
      expect(player.currentAudio, files.first);
      final lists = [
        MapEntry('first', [files.first]),
        MapEntry('empty', <AudioFile>[]),
        MapEntry('second', [files.last]),
      ];
      await player.playFromFolder(
        lists.first.value,
        0,
        listKey: 'first',
        lists: lists,
      );
      await settings.setListEnd(ListEndAction.nextList);
      await player.onTrackComplete();
      expect(player.currentAudio, files.last);
      await player.onTrackComplete();
      expect(player.isPlaying, false);
      await player.resume();
      await player.interrupt(PlaybackInterruption.leavePlayer);
      expect(player.isPlaying, true);
      await settings.setStop(PlaybackInterruption.leavePlayer, true);
      await player.interrupt(PlaybackInterruption.leavePlayer);
      expect(player.isPlaying, false);
      await player.resume();
      player.setSleepTimer(duration: const Duration(minutes: 5));
      await tester.pump(const Duration(minutes: 5));
      expect(player.isPlaying, false);
      expect(player.sleepDeadline, isNull);
      await player.resume();
      player.setSleepTimer(atTrackEnd: true);
      await player.onTrackComplete();
      expect(player.isPlaying, false);
      expect(player.sleepAtTrackEnd, false);
      await tester.pump();
      player.dispose();
      library.dispose();
    },
  );

  testWidgets('audio folders expand independently without nested navigation', (
    tester,
  ) async {
    final audio = FolderAudio();
    await tester.pumpWidget(
      fixture.host(
        ChangeNotifierProvider<AudioPlayerProvider>.value(
          value: audio,
          child: const Scaffold(body: FlatListView(folders: true)),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.folder_outlined), findsNWidgets(2));
    expect(find.byType(AudioItem), findsNothing);
    await tester.tap(find.text('album'));
    await tester.pumpAndSettle();
    expect(find.text('parent'), findsOneWidget);
    expect(find.text('child'), findsNothing);
    expect(tester.getSize(find.byType(AudioRow).first).height, 64);
    await tester.tap(find.text('disc'));
    await tester.pumpAndSettle();
    expect(find.byType(AudioItem), findsNWidgets(2));
    await tester.tap(find.text('album'));
    await tester.pumpAndSettle();
    expect(find.text('parent'), findsNothing);
    expect(find.text('child'), findsOneWidget);
    expect(find.byType(BackButton), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    audio.dispose();
  });

  testWidgets(
    'timer digit positions remain fixed across narrow and wide digits',
    (tester) async {
      Future<List<Rect>> positions(String value) async {
        await tester.pumpWidget(
          fixture.host(Center(child: RecordingTimer(text: value))),
        );
        return [
          for (final text
              in find
                  .descendant(
                    of: find.byType(RecordingTimer),
                    matching: find.byType(Text),
                  )
                  .evaluate())
            tester.getRect(find.byWidget(text.widget)),
        ];
      }

      expect(await positions('11:11.11'), await positions('88:88.88'));
    },
  );

  testWidgets('notes persist separately from lyrics and other audio files', (
    tester,
  ) async {
    Future<void> editor(String path, {bool notes = true}) async {
      await tester.pumpWidget(
        fixture.host(
          Scaffold(
            body: AudioLyricsEditor(
              key: ValueKey('$path:$notes'),
              path: path,
              initialTitle: 'Track',
              notes: notes,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    await editor('/a');
    await tester.enterText(find.byType(TextField), 'Practice slowly');
    await tester.pumpAndSettle();
    await editor('/b');
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      '',
    );
    await editor('/a', notes: false);
    expect(
      tester
          .widgetList<TextField>(find.byType(TextField))
          .last
          .controller!
          .text,
      '',
    );
    await editor('/a');
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'Practice slowly',
    );
  });
}
