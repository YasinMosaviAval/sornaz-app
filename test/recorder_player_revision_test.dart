import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sornaz/components/ab_repeat.dart';
import 'package:sornaz/screens/Players/scan/audio_file.dart';
import 'package:sornaz/screens/Players/services/music_playlists.dart';
import 'package:sornaz/screens/Players/ui/components/audio_selection.dart';
import 'package:sornaz/screens/Players/ui/components/audio_slider.dart';
import 'package:sornaz/screens/Players/playback/playback_queue_manager.dart';
import 'package:sornaz/screens/Voice%20Recorder/provider/voice_recorder_provider.dart';
import 'package:sornaz/screens/Voice%20Recorder/services/file_service.dart';
import 'package:sornaz/screens/Voice%20Recorder/services/recording_service.dart';
import 'package:sornaz/screens/Voice%20Recorder/services/recording_text.dart';
import 'package:sornaz/screens/Voice%20Recorder/ui/components/seekable_waveform.dart';
import 'package:sornaz/screens/Voice%20Recorder/ui/pages/voice_recorder.dart';
import 'package:sornaz/screens/Voice%20Recorder/ui/pages/recordings_list.dart';
import 'package:sornaz/screens/Voice%20Recorder/ui/pages/recording_playback.dart';
import 'recording_draft_test.dart' as draft;
import 'social_widget_test.dart' as fixture;

class Files extends draft.Files {
  final deleted = <String>[];
  bool failSave = false;
  List<SavedRecording> items = [];
  @override
  Future<String> materialize(SavedRecording file) async =>
      throw StateError('Wave extraction unavailable in test');
  @override
  Future<void> discardDraft(String path) async {
    deleted.add(path);
  }

  @override
  Future<void> publish(String path, {String? sourceUri}) async {
    if (failSave) throw StateError('storage full');
    await super.publish(path, sourceUri: sourceUri);
  }

  @override
  Future<List<SavedRecording>> loadFiles() async => items;
  @override
  Future<Map<String, String>> describe(SavedRecording file) async => {
    'location': 'Music/Sornaz',
    'durationMs': '12500',
  };
}

class Player extends draft.Player {
  @override
  final queue = PlaybackQueueManager();
  @override
  final abRepeat = AbRepeat();
  @override
  double speed = 1;
  @override
  List<String> paths = [];
  @override
  void setQueue(Iterable<String> items, String current) {
    paths = items.toList();
  }

  @override
  Duration duration = const Duration(seconds: 12);
  @override
  Future<void> pause() async {
    isPlaying = false;
  }
}

void main() {
  test(
    'recording text survives URI rename and is removed on deletion',
    () async {
      SharedPreferences.setMockInitialValues({
        'music_lyrics_old': '{"lyrics":"notes"}',
      });
      await moveRecordingText('old', 'old');
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('music_lyrics_old'), isNotNull);
      await moveRecordingText('old', 'new');
      expect(prefs.getString('music_lyrics_old'), isNull);
      expect(prefs.getString('music_lyrics_new'), '{"lyrics":"notes"}');
      await moveRecordingText('new', null);
      expect(prefs.getString('music_lyrics_new'), isNull);
    },
  );
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });
  test(
    'silence is gated, voice has visible contrast, timer has hundredths',
    () {
      expect(recordingAmplitude(-60), 0);
      expect(recordingAmplitude(-50), 0);
      expect(recordingAmplitude(-45), lessThan(.02));
      expect(recordingAmplitude(-15), greaterThan(.25));
      expect(recordingTime(61239), '01:01.23');
    },
  );
  test('save failure preserves the paused draft and allows retry', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    final files = Files()..failSave = true;
    final vm = VoiceRecorderProvider(files, draft.Recorder(), Player());
    try {
      await vm.startRecording();
      final path = vm.currentFilePath;
      vm.amplitudes.add(.3);
      await vm.pauseRecording();
      await expectLater(vm.stopRecording(), throwsStateError);
      expect(vm.currentFilePath, path);
      expect(vm.isPaused, isTrue);
      expect(vm.amplitudes, [.3]);
      files.failSave = false;
      await vm.stopRecording();
      expect(files.published, path);
      expect(vm.hasDraft, isFalse);
    } finally {
      vm.dispose();
      debugDefaultTargetPlatformOverride = null;
    }
  });
  test(
    'recording categories migrate favorites without changing music',
    () async {
      SharedPreferences.setMockInitialValues({
        'recording.favorites': ['/voice.m4a'],
        'music.favorites': ['/song.mp3'],
      });
      final recordings = MusicPlaylists(storagePrefix: 'recording');
      await recordings.create('تمرین');
      await recordings.add('تمرین', ['/voice.m4a']);
      await recordings.replacePath('/voice.m4a', '/renamed.m4a');
      final reloaded = MusicPlaylists(storagePrefix: 'recording');
      await reloaded.load();
      expect(reloaded.lists['تمرین'], ['/renamed.m4a']);
      expect(reloaded.lists[MusicPlaylists.favorite], ['/renamed.m4a']);
      expect(
        (await SharedPreferences.getInstance()).getStringList(
          'music.favorites',
        ),
        ['/song.mp3'],
      );
    },
  );
  testWidgets(
    'wave information tabs and compact bookmark edit/delete controls',
    (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final file = SavedRecording(
        uri: '/wave.m4a',
        name: 'Wave',
        modified: DateTime(2026),
      );
      final files = Files()..items = [file];
      final player = Player()..currentPath = file.uri;
      final vm = VoiceRecorderProvider(files, draft.Recorder(), player);
      vm.files = [file];
      for (var i = 0; i < 10; i++) {
        await files.bookmarks.add(file.uri, i * 1000);
      }
      await tester.pumpWidget(
        fixture.host(
          ChangeNotifierProvider<VoiceRecorderProvider>.value(
            value: vm,
            child: RecordingInformationPage(file: file),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.widgetWithText(Tab, 'موج صدا'), findsOneWidget);
      expect(find.widgetWithText(Tab, 'متن'), findsOneWidget);
      expect(find.widgetWithText(Tab, 'اطلاعات'), findsOneWidget);
      expect(find.byIcon(Icons.replay_10), findsNothing);
      expect(find.byIcon(Icons.forward_10), findsNothing);
      expect(find.text('ضبط جایگزین از این نقطه'), findsNothing);
      await tester.tap(find.byTooltip('لیست نشانه‌ها'));
      await tester.pumpAndSettle();
      final visible = find.byTooltip('ویرایش نشانه').hitTestable();
      expect(visible.evaluate().length, inInclusiveRange(6, 7));
      await tester.tap(visible.first);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField), 'Intro');
      await tester.tap(find.text('ذخیره'));
      await tester.pumpAndSettle();
      expect(await files.bookmarks.name(file.uri, 0), 'Intro');
      await tester.tap(find.byTooltip('حذف نشانه').hitTestable().first);
      await tester.pumpAndSettle();
      expect(find.text('حذف نشانه؟'), findsOneWidget);
      await tester.tap(find.text('انصراف'));
      await tester.pumpAndSettle();
      expect(await files.bookmarks.load(file.uri), hasLength(10));
      await tester.tap(find.byTooltip('حذف نشانه').hitTestable().first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('حذف'));
      await tester.pumpAndSettle();
      expect(await files.bookmarks.load(file.uri), hasLength(9));
      await tester.tap(find.widgetWithText(Tab, 'متن'));
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsWidgets);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      vm.dispose();
    },
  );
  for (final count in [1, 2]) {
    testWidgets('rename menu is available only for one selected file: $count', (
      tester,
    ) async {
      final files = List.generate(
        count,
        (i) => AudioFile(
          file: File('/$i.mp3'),
          fileName: '$i.mp3',
          folderName: '/',
          duration: Duration.zero,
        ),
      );
      await tester.pumpWidget(
        fixture.host(Scaffold(body: AudioActionsMenu(files: files))),
      );
      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();
      expect(
        find.text('تغییر نام'),
        count == 1 ? findsOneWidget : findsNothing,
      );
    });
  }
  testWidgets('A marker uses the same track coordinates and subsecond seek', (
    tester,
  ) async {
    final repeat = AbRepeat()..cycle(const Duration(milliseconds: 1500));
    Duration? target;
    await tester.pumpWidget(
      fixture.host(
        Scaffold(
          body: Center(
            child: SizedBox(
              width: 360,
              child: PlaybackProgress(
                position: const Duration(milliseconds: 1500),
                duration: const Duration(seconds: 10),
                repeat: repeat,
                onSeek: (at) => target = at,
              ),
            ),
          ),
        ),
      ),
    );
    final slider = tester.widget<Slider>(find.byType(Slider));
    expect(slider.value, 1500);
    final rect = tester.getRect(find.byType(AbTrack));
    // The same horizontal inset is used by the painted A marker and Slider track.
    final marker = Offset(
      rect.left + 15 + (rect.width - 30) * .15,
      rect.center.dy,
    );
    await tester.tapAt(marker);
    await tester.pumpAndSettle();
    expect(target?.inMilliseconds, closeTo(1500, 2));
    expect(tester.takeException(), isNull);
  });
  for (final choice in ['ذخیره', 'حذف']) {
    testWidgets(
      'stop offers the same draft choices and $choice stays on recorder',
      (tester) async {
        final files = Files(), recorder = draft.Recorder(), player = Player();
        final vm = VoiceRecorderProvider(files, recorder, player);
        await tester.pumpWidget(
          fixture.host(
            ChangeNotifierProvider<VoiceRecorderProvider>.value(
              value: vm,
              child: const VoiceRecorderPage(),
            ),
          ),
        );
        await vm.startRecording();
        await tester.pump();
        await tester.tap(find.byTooltip('پایان ضبط'));
        await tester.pumpAndSettle();
        expect(
          find.text('صدای ضبط شده را ذخیره می کنید یا حذف؟'),
          findsOneWidget,
        );
        await tester.tap(find.text('ادامه ضبط'));
        await tester.pump(const Duration(milliseconds: 300));
        expect(vm.isRecording, true);
        await tester.tap(find.byTooltip('پایان ضبط'));
        await tester.pumpAndSettle();
        await tester.tap(find.text(choice));
        await tester.pumpAndSettle();
        expect(vm.hasDraft, false);
        expect(find.byType(VoiceRecorderPage), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        vm.dispose();
      },
    );
    testWidgets(
      'back pauses immediately; cancel keeps draft; $choice completes exit',
      (tester) async {
        final files = Files(), recorder = draft.Recorder(), player = Player();
        final vm = VoiceRecorderProvider(files, recorder, player);
        await tester.pumpWidget(
          fixture.host(
            ChangeNotifierProvider<VoiceRecorderProvider>.value(
              value: vm,
              child: Builder(
                builder: (c) => Scaffold(
                  body: TextButton(
                    onPressed: () => Navigator.push(
                      c,
                      MaterialPageRoute(
                        builder: (_) =>
                            ChangeNotifierProvider<VoiceRecorderProvider>.value(
                              value: vm,
                              child: const VoiceRecorderPage(),
                            ),
                      ),
                    ),
                    child: const Text('open'),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();
        await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle();
        expect(find.byType(AlertDialog), findsNothing);
        expect(find.byType(VoiceRecorderPage), findsNothing);
        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();
        await vm.startRecording();
        vm.amplitudes.add(.3);
        await tester.pump();
        final wave = tester.getRect(find.byType(SeekableWaveform));
        final path = vm.currentFilePath;
        await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle();
        expect(recorder.stops, 1);
        expect(vm.isPaused, isTrue);
        expect(
          find.text('صدای ضبط شده را ذخیره می کنید یا حذف؟'),
          findsOneWidget,
        );
        expect(find.byIcon(Icons.favorite_outline_rounded), findsNothing);
        await tester.tap(find.text('ادامه ضبط'));
        await tester.pump(const Duration(milliseconds: 300));
        expect(vm.currentFilePath, path);
        expect(tester.getRect(find.byType(SeekableWaveform)), wave);
        await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle();
        await tester.tap(find.text(choice));
        await tester.pumpAndSettle();
        expect(find.byType(VoiceRecorderPage), findsNothing);
        expect(vm.hasDraft, isFalse);
        if (choice == 'ذخیره') {
          expect(files.published, path);
        } else {
          expect(files.deleted, [path]);
          expect(files.published, isNull);
        }
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        vm.dispose();
      },
    );
  }
  testWidgets('recording tabs show all, favorites, and a new category', (
    tester,
  ) async {
    final file = SavedRecording(
      uri: '/voice.m4a',
      name: 'Voice',
      modified: DateTime(2026),
    );
    final files = Files()..items = [file];
    final vm = VoiceRecorderProvider(files, draft.Recorder(), Player());
    await tester.pumpWidget(
      fixture.host(
        ChangeNotifierProvider<VoiceRecorderProvider>.value(
          value: vm,
          child: const RecordedFilesPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.widgetWithText(Tab, 'همه'), findsOneWidget);
    expect(find.widgetWithText(Tab, 'علاقه‌مندی'), findsOneWidget);
    expect(find.text('Voice'), findsOneWidget);
    await tester.tap(find.widgetWithText(Tab, 'علاقه‌مندی'));
    await tester.pumpAndSettle();
    expect(find.text('Voice'), findsNothing);
    await MusicPlaylists.recordings.add(MusicPlaylists.favorite, [file.uri]);
    await tester.pumpAndSettle();
    expect(find.text('Voice'), findsOneWidget);
    await tester.tap(find.byTooltip('دسته‌بندی جدید'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Session');
    await tester.tap(find.text('ایجاد'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(Tab, 'Session'), findsOneWidget);
    expect(find.text('Voice'), findsNothing);
    await MusicPlaylists.recordings.add('Session', [file.uri]);
    await tester.pumpAndSettle();
    expect(find.text('Voice'), findsOneWidget);
    expect(find.byType(Slider), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(
      fixture.host(
        ChangeNotifierProvider<VoiceRecorderProvider>.value(
          value: vm,
          child: const RecordedFilesPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.widgetWithText(Tab, 'Session'), findsOneWidget);
    await tester.tap(find.widgetWithText(Tab, 'Session'));
    await tester.pumpAndSettle();
    expect(find.text('Voice'), findsOneWidget);
    expect(find.byTooltip('تغییر نام دسته‌بندی'), findsOneWidget);
    expect(find.byTooltip('حذف دسته‌بندی'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    vm.dispose();
  });
}
