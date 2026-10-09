import 'package:flutter/material.dart' hide RepeatMode;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sornaz/screens/Players/services/player_settings.dart';
import 'package:provider/provider.dart';
import 'package:sornaz/components/ab_repeat.dart';
import 'package:sornaz/screens/Players/providers/audio_player_provider.dart';
import 'package:sornaz/screens/Players/playback/playback_queue_manager.dart';
import 'package:sornaz/screens/Players/scan/audio_file.dart';
import 'package:sornaz/screens/Players/ui/pages/music_player_tabs.dart';
import 'package:sornaz/screens/Players/ui/components/audio_controls.dart';
import 'social_widget_test.dart' as fixture;

class Audio extends ChangeNotifier implements AudioPlayerProvider {
  @override
  PlayerSettings get settings => PlayerSettings.instance;
  @override
  bool get isPlaying => false;
  @override
  bool get isUndoMode => false;
  @override
  bool get folderMode => false;
  @override
  bool get isShuffle => false;
  @override
  RepeatMode get repeatMode => RepeatMode.off;
  @override
  double get playbackSpeed => 1;
  @override
  List<double> get speedOptions => [1, 2];
  @override
  AudioFile? get currentAudio => null;
  @override
  final abRepeat = AbRepeat();
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  testWidgets('tab reordering and hiding preserve the selected page', (
    tester,
  ) async {
    final settings = PlayerSettings.instance;
    await settings.setOption('tabOrder', ['0', '1', '2', '3']);
    await settings.setOption('hiddenTabs', <String>[]);
    await tester.pumpWidget(
      fixture.host(
        const Scaffold(
          body: MusicPlayerTabs(
            pages: [
              Center(child: Text('songs-page')),
              Center(child: Text('folders-page')),
              Center(child: Text('lists-page')),
              Center(child: Text('equalizer-page')),
            ],
            controls: SizedBox(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await settings.setOption('tabOrder', ['2', '0', '3', '1']);
    await tester.pumpAndSettle();
    expect(find.text('songs-page').hitTestable(), findsOneWidget);
    await settings.setOption('hiddenTabs', ['0']);
    await tester.pumpAndSettle();
    expect(tester.widget<TabBar>(find.byType(TabBar)).tabs.length, 3);
    expect(find.text('lists-page').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await settings.setOption('tabOrder', ['0', '1', '2', '3']);
    await settings.setOption('hiddenTabs', <String>[]);
  });
  for (final direction in TextDirection.values) {
    testWidgets(
      'player slides retain physical left/right order with controls at 320: $direction',
      (tester) async {
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final audio = Audio();
        await tester.pumpWidget(
          fixture.host(
            ChangeNotifierProvider<AudioPlayerProvider>.value(
              value: audio,
              child: Directionality(
                textDirection: direction,
                child: const Scaffold(
                  body: MusicPlayerTabs(
                    pages: [
                      Center(child: Text('list-page')),
                      Center(child: Text('folder-page')),
                      Center(child: Text('playlist-page')),
                      Center(child: Text('eq-page')),
                    ],
                    controls: AudioControls(),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('list-page').hitTestable(), findsOneWidget);
        expect(find.byType(TabBar), findsOneWidget);
        final left = 'player-leading-slide';
        final right = 'player-trailing-slide';
        expect(find.text('list-page').hitTestable(), findsOneWidget);
        expect(
          tester.widget<IconButton>(find.byKey(ValueKey(left))).onPressed,
          isNull,
        );
        await tester.tap(find.byKey(ValueKey(right)));
        await tester.pumpAndSettle();
        await tester.drag(
          find.byType(PageView),
          Offset(direction == TextDirection.rtl ? 280 : -280, 0),
        );
        await tester.pumpAndSettle();
        expect(find.text('playlist-page').hitTestable(), findsOneWidget);
        await tester.tap(find.byKey(ValueKey(right)));
        await tester.pumpAndSettle();
        expect(find.text('eq-page').hitTestable(), findsOneWidget);
        expect(
          tester.widget<IconButton>(find.byKey(ValueKey(right))).onPressed,
          isNull,
        );
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        audio.dispose();
      },
    );
  }
}
