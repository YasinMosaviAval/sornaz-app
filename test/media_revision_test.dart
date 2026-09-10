import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sornaz/helpers/app_data.dart';
import 'package:sornaz/helpers/color_palette.dart';
import 'package:sornaz/components/ab_repeat.dart';
import 'package:sornaz/components/expanding_search_bar.dart';
import 'package:sornaz/screens/Players/playback/playback_queue_manager.dart';
import 'package:sornaz/screens/Social/course_cache.dart';
import 'package:sornaz/screens/Social/protected_media.dart';
import 'package:sornaz/screens/Social/social_api.dart';
import 'package:sornaz/screens/Voice%20Recorder/services/recording_bookmarks.dart';
import 'package:sornaz/screens/Onboarding/ui/pages/startup_preferences.dart';
import 'drawer_accounts_test.dart' as fixture;
import 'package:sornaz/screens/Authentication/providers/auth_session.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    CourseCache.checked.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (_) async => Directory.systemTemp.path,
        );
  });
  test(
    'all five palettes persist independently of light and dark mode',
    () async {
      final prefs = await SharedPreferences.getInstance();
      for (final p in ColorPalette.values) {
        final app = AppData(preferences: prefs);
        await app.setPalette(p);
        app.toggleDarkMode(true);
        final restored = AppData(preferences: prefs);
        expect(restored.palette, p);
        expect(restored.accent, p.dark);
        restored.toggleDarkMode(false);
        expect(restored.accent, p.light);
      }
    },
  );
  test('A-B loops only a complete range and clears on third press', () {
    final repeat = AbRepeat();
    repeat.cycle(const Duration(seconds: 3));
    expect(repeat.active, false);
    repeat.cycle(const Duration(seconds: 8));
    expect(repeat.active, true);
    expect(repeat.shouldLoop(const Duration(seconds: 7)), false);
    expect(repeat.shouldLoop(const Duration(seconds: 8)), true);
    repeat.cycle(const Duration(seconds: 4));
    expect(repeat.start, isNull);
  });
  test('shuffle preserves track identity and visits each track once', () {
    final queue = PlaybackQueueManager()
      ..setQueue(15)
      ..setCurrentIndex(7)
      ..toggleShuffle()
      ..rebuildOrder(queueLength: 15);
    final visited = <int>{7};
    var next = queue.next();
    while (next != null) {
      expect(visited.add(next), true);
      queue.setCurrentIndex(next);
      next = queue.next();
    }
    queue.rebuildOrder(queueLength: 0);
    expect(queue.next(), isNull);
  });
  test('rapid and nearby bookmarks cannot bypass one-second spacing', () async {
    final store = RecordingBookmarks();
    await Future.wait([
      store.add('track', 2000),
      store.add('track', 2200),
      store.add('track', 1300),
    ]);
    expect(await store.load('track'), [2000]);
    await store.add('track', 3000);
    expect(await store.load('track'), [2000, 3000]);
    await store.rename('track', 2000, 'Intro');
    expect(await store.name('track', 2000), 'Intro');
    await store.move('track', 'renamed');
    expect(await store.load('renamed'), [2000, 3000]);
    expect(await store.name('renamed', 2000), 'Intro');
    expect(await store.name('track', 2000), '');
    await store.remove('renamed', 2000);
    expect(await store.name('renamed', 2000), '');
  });
  test('course metadata survives offline use and isolates accounts', () async {
    var offline = false;
    final api = SocialApi(
      'account-a',
      client: MockClient((_) async {
        if (offline) throw const SocketException('https://private-api.example');
        return http.Response(
          jsonEncode({
            'success': true,
            'data': {'id': 5, 'updated_at': '2026-09-10', 'title': 'cached'},
          }),
          200,
        );
      }),
    );
    expect((await api.get('/courses/5'))['title'], 'cached');
    offline = true;
    CourseCache.checked.clear();
    expect((await api.get('/courses/5'))['title'], 'cached');
    final other = SocialApi(
      'account-b',
      client: MockClient((_) async => throw const SocketException('offline')),
    );
    await expectLater(other.get('/courses/5'), throwsA(isA<SocialException>()));
    await Future<void>.delayed(Duration.zero);
    api.dispose();
    other.dispose();
  });
  test(
    'protected media round trip rejects tampering, truncation and another account',
    () async {
      final dir = await Directory.systemTemp.createTemp('protected-test-');
      final target = File('${dir.path}/1.sornaz'),
          store = ProtectedMedia('encryption-test');
      final plain = List<int>.generate(140000, (i) => i % 251);
      try {
        await store.save(target, Stream.value(plain));
        expect((await target.readAsBytes()).take(8), utf8.encode('SORNAZ01'));
        final opened = await store.open(target);
        expect(await opened.readAsBytes(), plain);
        await ProtectedMedia.close(opened);
        await expectLater(
          ProtectedMedia('different-account').open(target),
          throwsA(anything),
        );
        final bytes = await target.readAsBytes();
        bytes[40] ^= 1;
        await target.writeAsBytes(bytes);
        await expectLater(store.open(target), throwsA(anything));
        await store.save(target, Stream.value(plain));
        final complete = await target.readAsBytes();
        await target.writeAsBytes(complete.sublist(0, complete.length - 32));
        await expectLater(store.open(target), throwsA(anything));
      } finally {
        await dir.delete(recursive: true);
      }
    },
  );
  testWidgets(
    'search animates at narrow width without losing input or overflowing',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      String query = '';
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: ExpandingSearchBar(
              title: const Row(
                children: [
                  BackButton(),
                  Expanded(child: Text('Long folder breadcrumb')),
                ],
              ),
              onChanged: (v) => query = v,
              onSettings: () {},
            ),
          ),
        ),
      );
      await tester.tap(find.byKey(const ValueKey('open-search')));
      await tester.pump(const Duration(milliseconds: 120));
      expect(tester.takeException(), isNull);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'song');
      expect(query, 'song');
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();
      expect(query, '');
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('startup shows five palettes without overflow', (tester) async {
    tester.view.physicalSize = const Size(360, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      fixture.host(const StartupPreferencesScreen(), AppData(), AuthSession()),
    );
    await tester.pumpAndSettle();
    expect(find.byType(ChoiceChip), findsNWidgets(5));
    expect(tester.takeException(), isNull);
  });
}
