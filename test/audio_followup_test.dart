import 'package:flutter/material.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sornaz/helpers/app_data.dart';
import 'package:sornaz/components/sleep_timer_chrome.dart';
import 'package:sornaz/screens/Players/library/audio_library_manager.dart';
import 'package:sornaz/screens/Players/providers/audio_player_provider.dart';
import 'package:sornaz/screens/Players/services/music_audio_handler.dart';
import 'package:sornaz/screens/Players/services/music_playlists.dart';
import 'package:sornaz/screens/Players/services/player_settings.dart';
import 'package:sornaz/screens/Players/services/sleep_timer_status.dart';
import 'package:sornaz/screens/Players/services/equalizer_settings.dart';
import 'package:sornaz/screens/Players/ui/components/audio_item.dart';
import 'package:sornaz/screens/Players/ui/components/flat_list_view.dart';
import 'package:sornaz/screens/Players/ui/components/search_bar.dart';
import 'package:sornaz/screens/Players/ui/pages/equalizer.dart';
import 'package:sornaz/screens/Players/ui/pages/playlists.dart';
import 'package:sornaz/screens/Voice%20Recorder/services/recording_waveforms.dart';
import 'package:sornaz/screens/Voice%20Recorder/services/file_service.dart';
import 'player_behavior_revision_test.dart' as behavior;
import 'recorder_player_revision_test.dart' as recordings;
import 'social_widget_test.dart' as fixture;

void main() {
  test(
    'Android 13 undo uses a custom action with the shared previous callback',
    () async {
      final handler = MusicAudioHandler(customUndo: true);
      var calls = 0;
      handler.onPrevious = () async {
        calls++;
      };
      handler.publish(
        id: 'a',
        title: 'a',
        duration: const Duration(minutes: 1),
        position: Duration.zero,
        playing: true,
        loading: false,
        speed: 1,
        undo: true,
      );
      final previous = handler.playbackState.value.controls.first;
      expect(previous.action, MediaAction.rewind);
      expect(previous.androidIcon, 'drawable/ic_playback_undo');
      await handler.rewind();
      expect(calls, 1);
    },
  );
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    SleepTimerStatus.instance.update();
    RecordingWaveforms.memory.clear();
  });
  test(
    'only leaving the music page is disabled by default; saved choices win',
    () async {
      final settings = PlayerSettings();
      await settings.load();
      for (final reason in PlaybackInterruption.values) {
        expect(
          settings.stopsFor(reason),
          reason != PlaybackInterruption.leavePlayer,
        );
      }
      await settings.setStop(PlaybackInterruption.recording, false);
      final restored = PlayerSettings();
      await restored.load();
      expect(restored.stopsFor(PlaybackInterruption.recording), false);
    },
  );

  test(
    'notification ownership switches safely and undo changes the previous icon',
    () async {
      final handler = MusicAudioHandler();
      final music = Object(), recording = Object();
      var pausedMusic = 0, recordingPrevious = 0;
      Future<void> noop() async {}
      await handler.activate(
        music,
        play: noop,
        pause: () async {
          pausedMusic++;
        },
        stop: noop,
        previous: noop,
        next: noop,
        seek: (_) async {},
      );
      await handler.activate(
        recording,
        play: noop,
        pause: noop,
        stop: noop,
        previous: () async {
          recordingPrevious++;
        },
        next: noop,
        seek: (_) async {},
      );
      expect(pausedMusic, 1);
      handler.release(music);
      await handler.skipToPrevious();
      expect(recordingPrevious, 1);
      handler.publish(
        id: 'recording',
        title: 'Voice',
        duration: const Duration(minutes: 1),
        position: Duration.zero,
        playing: true,
        loading: false,
        speed: 1,
        undo: true,
      );
      expect(
        handler.playbackState.value.controls.first.androidIcon,
        'drawable/ic_playback_undo',
      );
      handler.release(recording);
      expect(handler.mediaItem.value, isNull);
    },
  );

  test(
    'recorded waveform persists and follows rename without extraction',
    () async {
      await RecordingWaveforms.save('/old', [.1, .5, .9]);
      RecordingWaveforms.memory.clear();
      await RecordingWaveforms.move('/old', '/new');
      final file = SavedRecording(
        uri: '/new',
        name: 'New',
        modified: DateTime(2026),
      );
      final samples = await RecordingWaveforms.load(file, recordings.Files());
      expect(samples.length, 3);
      expect(samples[1], closeTo(.5, .005));
      expect(RecordingWaveforms.pending, isEmpty);
      await RecordingWaveforms.move('/new', null);
      expect(await RecordingWaveforms.cached('/new'), isNull);
      final missing = SavedRecording(
        uri: '/missing',
        name: 'Missing',
        modified: DateTime(2026),
      );
      await expectLater(
        RecordingWaveforms.load(missing, recordings.Files()),
        throwsStateError,
      );
      expect(RecordingWaveforms.pending, isEmpty);
    },
  );

  testWidgets('English playback settings and timer dialog contain no Persian', (
    tester,
  ) async {
    final settings = PlayerSettings();
    await settings.load();
    final library = AudioLibraryManager();
    final player = AudioPlayerProvider(
      libraryManager: library,
      controller: behavior.MemoryController(),
      playbackSettings: settings,
    );
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AppData()),
          ChangeNotifierProvider<AudioPlayerProvider>.value(value: player),
        ],
        child: const MaterialApp(home: PlayerSettingsPage()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(SwitchListTile), findsNWidgets(5));
    expect(find.text('Stop when entering the voice recorder'), findsOneWidget);
    player.setSleepTimer(duration: const Duration(minutes: 5));
    await tester.pump();
    expect(find.text('5 minutes'), findsOneWidget);
    expect(
      tester.getCenter(find.text('Sleep Timer')).dy,
      tester.getCenter(find.text('5 minutes')).dy,
    );
    expect(find.byIcon(Icons.expand_more), findsNothing);
    for (final text in tester.widgetList<Text>(find.byType(Text))) {
      expect(RegExp(r'[\u0600-\u06ff]').hasMatch(text.data ?? ''), false);
    }
    await tester.tap(find.text('Sleep Timer'));
    await tester.pumpAndSettle();
    final dialog = tester.widget<SimpleDialog>(find.byType(SimpleDialog));
    expect((dialog.title as Text).style!.fontSize, 14);
    expect(find.text('Custom duration'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    player.dispose();
    library.dispose();
  });

  testWidgets(
    'next folder opens and both the folder and track are highlighted',
    (tester) async {
      final settings = PlayerSettings();
      await settings.load();
      final library = AudioLibraryManager();
      final player = AudioPlayerProvider(
        libraryManager: library,
        controller: behavior.MemoryController(),
        playbackSettings: settings,
      );
      final files = behavior.FolderAudio().allFiles;
      player.setFileList(files);
      await tester.pumpWidget(
        fixture.host(
          ChangeNotifierProvider<AudioPlayerProvider>.value(
            value: player,
            child: const Scaffold(body: FlatListView(folders: true)),
          ),
        ),
      );
      final lists = [
        for (final file in files) MapEntry(file.file.parent.path, [file]),
      ];
      await player.playFromFolder(
        [files.first],
        0,
        listKey: lists.first.key,
        lists: lists,
      );
      await settings.setListEnd(ListEndAction.nextList);
      await player.onTrackComplete();
      await tester.pumpAndSettle();
      expect(find.text('child'), findsOneWidget);
      expect(find.byIcon(Icons.folder), findsOneWidget);
      expect(
        tester
            .widgetList<AudioRow>(find.byType(AudioRow))
            .where((w) => w.isPlaying)
            .length,
        2,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      player.dispose();
      library.dispose();
    },
  );

  testWidgets('disabled equalizer ignores presets and band tabs', (
    tester,
  ) async {
    final eq = EqualizerSettings(applyOverride: (_) async {});
    await eq.load();
    await eq.setEnabled(false);
    await tester.pumpWidget(
      fixture.host(Scaffold(body: EqualizerTab(settings: eq))),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('10 فیلتر'), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(eq.bands, 5);
    expect(
      find.descendant(
        of: find.byType(EqualizerTab),
        matching: find.byType(ColorFiltered),
      ),
      findsNothing,
    );
    expect(
      tester.widget<AbsorbPointer>(find.byType(AbsorbPointer).last).absorbing,
      true,
    );
    await tester.pumpWidget(const SizedBox());
    eq.dispose();
  });

  testWidgets('playlist picker excludes the current collection', (
    tester,
  ) async {
    final store = MusicPlaylists(storagePrefix: 'exclude');
    await store.create('Current');
    await store.create('Other');
    await tester.pumpWidget(
      fixture.host(
        Scaffold(
          body: Builder(
            builder: (c) => TextButton(
              onPressed: () =>
                  chooseAudioPlaylist(c, ['/a'], store, excludeKey: 'Current'),
              child: const Text('choose'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('choose'));
    await tester.pumpAndSettle();
    expect(find.text('Current'), findsNothing);
    expect(find.text('Other'), findsOneWidget);
  });

  testWidgets('global timer is visible across toolbar rebuilds', (
    tester,
  ) async {
    SleepTimerStatus.instance.update(
      trackRemaining: const Duration(minutes: 5),
    );
    await tester.pumpWidget(
      fixture.host(
        const Scaffold(
          body: SleepTimerChrome(child: SizedBox(height: 56, width: 400)),
        ),
      ),
    );
    expect(find.text('5:00'), findsOneWidget);
    SleepTimerStatus.instance.update(
      trackRemaining: const Duration(minutes: 4, seconds: 59),
    );
    await tester.pump();
    expect(find.text('4:59'), findsOneWidget);
    SleepTimerStatus.instance.update();
    await tester.pump();
    expect(find.byKey(const ValueKey('global-sleep-countdown')), findsNothing);
  });
}
