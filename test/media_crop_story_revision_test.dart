import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sornaz/screens/Voice%20Recorder/services/playback_service.dart';
import 'package:sornaz/screens/Voice%20Recorder/services/recording_bookmarks.dart';
import 'package:sornaz/screens/Voice%20Recorder/ui/components/seekable_waveform.dart';
import 'package:sornaz/screens/Social/story_snap.dart';
import 'package:sornaz/screens/Site/chat_message_bubble.dart';
import 'package:sornaz/screens/Site/panel_navigation.dart';
import 'package:sornaz/components/audio_crop_page.dart';
import 'package:sornaz/screens/Players/ui/pages/video_player_page.dart';
import 'social_widget_test.dart' as fixture;

class TestAudioBackend implements AudioPlayer {
  Completer<void>? gate;
  bool failLoad = false;
  final sources = <String>[];
  final seeks = <Duration>[];
  @override
  Stream<PlayerState> get playerStateStream => const Stream.empty();
  @override
  Stream<Duration> get positionStream => const Stream.empty();
  @override
  Stream<Duration?> get durationStream => const Stream.empty();
  @override
  ProcessingState get processingState => ProcessingState.ready;
  @override
  Future<Duration?> setAudioSource(
    AudioSource source, {
    bool preload = true,
    int? initialIndex,
    Duration? initialPosition,
  }) async {
    sources.add((source as UriAudioSource).uri.path);
    await gate?.future;
    if (failLoad) {
      failLoad = false;
      throw StateError('load failed');
    }
    return const Duration(minutes: 2);
  }

  @override
  Future<void> stop() async {}
  @override
  Future<void> pause() async {}
  @override
  Future<void> play() async {}
  @override
  Future<void> seek(Duration? position, {int? index}) async {
    seeks.add(position!);
  }

  @override
  Future<void> dispose() async {}
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));
  for (final replace in [false, true]) {
    testWidgets('crop saves the selected range with replace=$replace', (
      tester,
    ) async {
      final calls = <MethodCall>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        audioCropChannel,
        (call) async {
          calls.add(call);
          return '/nonexistent/crop-test.m4a';
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          audioCropChannel,
          null,
        ),
      );
      bool? savedReplace;
      Duration? savedStart, savedEnd;
      await tester.pumpWidget(
        fixture.host(
          AudioCropPage(
            source: '/song',
            name: 'Song',
            previewPlayer: TestAudioBackend(),
            onSave: (staged, replacing, start, end) async {
              savedReplace = replacing;
              savedStart = start;
              savedEnd = end;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('شروع: 00:00.00'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '5.25');
      await tester.tap(find.text('تأیید'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.text(replace ? 'جایگزینی فایل اصلی' : 'ذخیره به عنوان فایل جدید'),
      );
      await tester.pump();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 30)),
      );
      await tester.pumpAndSettle();
      expect(calls.single.method, 'render');
      expect(calls.single.arguments['start'], 5250);
      expect(savedReplace, replace);
      expect(savedStart, const Duration(milliseconds: 5250));
      expect(savedEnd, const Duration(minutes: 2));
      await tester.pumpWidget(const SizedBox());
    });
  }
  testWidgets(
    'device videos show first-frame thumbnails and expand folders and saved playlists',
    (tester) async {
      SharedPreferences.setMockInitialValues({
        'video.playlists': '{"Clips":["content://video/1"]}',
      });
      const videos = MethodChannel('sornaz/device_videos');
      const permissions = MethodChannel(
        'flutter.baseflow.com/permissions/methods',
      );
      const media = MethodChannel('sornaz/story_media');
      final frames = <MethodCall>[];
      final handlers = <MethodChannel, Future<Object?> Function(MethodCall)>{
        videos: (call) async => call.method == 'sdk'
            ? 33
            : [
                {
                  'uri': 'content://video/1',
                  'name': 'First clip.mp4',
                  'folder': 'Camera',
                  'folderId': '1',
                  'duration': 65000,
                },
                {
                  'uri': 'content://video/2',
                  'name': 'Second clip.mp4',
                  'folder': 'Camera',
                  'folderId': '1',
                  'duration': 30000,
                },
              ],
        permissions: (call) async => {
          for (final key in call.arguments as List) key: 1,
        },
        media: (call) async {
          frames.add(call);
          return base64Decode(
            'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
          );
        },
      };
      for (final entry in handlers.entries) {
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          entry.key,
          entry.value,
        );
      }
      addTearDown(() {
        for (final channel in handlers.keys) {
          tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
            channel,
            null,
          );
        }
      });
      await tester.pumpWidget(fixture.host(const VideoLibraryPage()));
      await tester.pumpAndSettle();
      expect(find.text('First clip.mp4'), findsOneWidget);
      expect(frames.length, 2);
      expect(
        frames.every(
          (c) =>
              c.method == 'thumbnail' &&
              c.arguments['timeMs'] == 0 &&
              c.arguments['video'] == true,
        ),
        true,
      );
      expect(find.byType(Image), findsNWidgets(2));
      await tester.tap(find.text('پوشه‌ها'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Camera'));
      await tester.pumpAndSettle();
      expect(find.text('First clip.mp4'), findsOneWidget);
      await tester.tap(find.text('لیست پخش‌ها'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Clips'));
      await tester.pumpAndSettle();
      expect(find.text('First clip.mp4'), findsOneWidget);
      expect(find.text('Second clip.mp4'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  test(
    'recording undo restores all recent changes in reverse order and expires each independently',
    () async {
      var now = DateTime(2026);
      final backend = TestAudioBackend();
      final service = PlaybackService(player: backend, now: () => now);
      addTearDown(service.dispose);
      service.setQueue(['/a', '/b'], '/a');
      await service.play('/a', autoplay: false);
      await service.seek(const Duration(seconds: 10));
      service.rememberPosition();
      now = now.add(const Duration(seconds: 4));
      await service.seek(const Duration(seconds: 30));
      service.rememberPosition();
      now = now.add(const Duration(seconds: 4));
      await service.play('/b', autoplay: false);
      await service.seek(const Duration(seconds: 50));
      service.rememberPosition();
      await service.seek(const Duration(seconds: 70));
      await service.previousOrUndo();
      expect(service.currentPath, '/b');
      expect(service.position.inSeconds, 50);
      now = now.add(const Duration(seconds: 3));
      await service.previousOrUndo();
      expect(service.currentPath, '/a');
      expect(service.position.inSeconds, 30);
      expect(
        service.isUndoMode,
        false,
      ); // The oldest change is now eleven seconds old.
    },
  );
  test(
    'overlapping recording loads are serialized and a failed load can be retried',
    () async {
      final backend = TestAudioBackend()..gate = Completer<void>();
      final service = PlaybackService(player: backend);
      addTearDown(service.dispose);
      final first = service.play('/a', autoplay: false);
      final second = service.play('/b', autoplay: false);
      await Future<void>.delayed(Duration.zero);
      expect(backend.sources, ['/a']);
      backend.gate!.complete();
      await Future.wait([first, second]);
      expect(backend.sources, ['/a', '/b']);
      expect(service.currentPath, '/b');
      backend.failLoad = true;
      await expectLater(service.play('/c', autoplay: false), throwsStateError);
      await service.play('/c', autoplay: false);
      expect(service.currentPath, '/c');
      expect(service.duration, const Duration(minutes: 2));
    },
  );
  test(
    'cropping relocates retained bookmarks and removes discarded names',
    () async {
      final store = RecordingBookmarks();
      await store.add('a', 1000);
      await store.add('a', 6000);
      await store.add('a', 20000);
      await store.rename('a', 6000, 'phrase');
      await store.crop('a', 5000, 15000);
      expect(await store.load('a'), [1000]);
      expect(await store.name('a', 1000), 'phrase');
      expect(await store.name('a', 6000), '');
    },
  );
  test(
    'story guides capture edges and center and require extra movement to release',
    () {
      final snap = StorySnapController();
      expect(
        snap.snap(
          const Offset(20, 20),
          const Size(100, 100),
          const Size(400, 600),
        ),
        const Offset(16, 16),
      );
      expect(
        snap.snap(
          const Offset(38, 38),
          const Size(100, 100),
          const Size(400, 600),
        ),
        const Offset(16, 16),
      );
      expect(
        snap.snap(
          const Offset(41, 41),
          const Size(100, 100),
          const Size(400, 600),
        ),
        const Offset(41, 41),
      );
      snap.reset();
      expect(
        snap.snap(
          const Offset(153, 247),
          const Size(100, 100),
          const Size(400, 600),
        ),
        const Offset(150, 250),
      );
      snap.reset();
      expect(
        snap.snap(
          const Offset(280, 487),
          const Size(100, 100),
          const Size(400, 600),
        ),
        const Offset(284, 484),
      );
    },
  );
  test('site settings are omitted from panel navigation', () {
    expect(
      panelNavigation([
        {'key': 'settings'},
        {'key': 'site-settings'},
        {'key': 'courses'},
      ]).map((v) => v['key']),
      ['courses'],
    );
  });
  testWidgets('waveform drags stay local and commit one seek when released', (
    tester,
  ) async {
    final seeks = <int>[];
    var starts = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 400,
            height: 200,
            child: SeekableWaveform(
              samples: List.filled(600, .5),
              duration: 60000,
              position: 30000,
              markers: const [],
              onSeekStart: () => starts++,
              onSeek: seeks.add,
            ),
          ),
        ),
      ),
    );
    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(SeekableWaveform)),
    );
    await gesture.moveBy(const Offset(-30, 0));
    await gesture.moveBy(const Offset(-80, 0));
    await tester.pump();
    expect(seeks, isEmpty);
    await gesture.up();
    expect(starts, 1);
    expect(seeks, hasLength(1));
    expect(seeks.single, greaterThan(30000));
  });
  testWidgets(
    'chat actions start at the message edge and incoming colors differ',
    (tester) async {
      await tester.pumpWidget(
        fixture.host(
          Column(
            children: [
              for (final mine in [true, false])
                ChatMessageBubble(
                  message: {
                    'id': mine ? 1 : 2,
                    'mine': mine,
                    'body': 'A message',
                    'createdAt': '2026-09-24 12:00',
                  },
                  actions: const {'like': {}, 'edit-message': {}},
                  onAction: (_) {},
                ),
            ],
          ),
        ),
      );
      final mine = tester.widget<Container>(
        find.byKey(const ValueKey('message-body-1')),
      );
      final other = tester.widget<Container>(
        find.byKey(const ValueKey('message-body-2')),
      );
      expect(
        (mine.decoration as BoxDecoration).color,
        isNot((other.decoration as BoxDecoration).color),
      );
      final likes = find.byIcon(Icons.favorite_border);
      final copies = find.byIcon(Icons.copy);
      expect(
        tester.getCenter(likes.first).dx,
        greaterThan(tester.getCenter(copies.first).dx),
      );
      expect(
        tester.getCenter(likes.last).dx,
        lessThan(tester.getCenter(copies.last).dx),
      );
      expect(
        tester.getCenter(likes.first).dx -
            tester.getCenter(find.byIcon(Icons.edit_outlined)).dx,
        closeTo(26, .01),
      );
    },
  );
}
