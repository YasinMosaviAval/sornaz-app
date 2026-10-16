import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sornaz/helpers/app_data.dart';
import 'package:sornaz/screens/Players/library/audio_library_manager.dart';
import 'package:sornaz/screens/Players/providers/audio_player_provider.dart';
import 'package:sornaz/screens/Players/services/player_settings.dart';
import 'package:sornaz/screens/Players/ui/components/music_playback_entry.dart';
import 'package:sornaz/screens/Players/ui/components/player_sort_tile.dart';
import 'package:sornaz/screens/Players/ui/pages/video_settings_page.dart';
import 'player_behavior_revision_test.dart' as fixture;

const reasons = [
  PlaybackInterruption.notation,
  PlaybackInterruption.video,
  PlaybackInterruption.solfege,
  PlaybackInterruption.performanceAnalysis,
  PlaybackInterruption.stageAndProfile,
];

class CountingController extends fixture.MemoryController {
  int stops = 0;
  @override
  Future<void> stop() async {
    stops++;
    await super.stop();
  }
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'all five entry switches default on and retain explicit off settings',
    () async {
      final settings = PlayerSettings();
      await settings.load();
      for (final reason in reasons) {
        expect(settings.stopsFor(reason), isTrue);
        await settings.setStop(reason, false);
      }
      final restored = PlayerSettings();
      await restored.load();
      for (final reason in reasons) {
        expect(restored.stopsFor(reason), isFalse);
      }
      settings.dispose();
      restored.dispose();
    },
  );

  for (final reason in reasons) {
    testWidgets('$reason stops actual playback only while enabled', (
      tester,
    ) async {
      final settings = PlayerSettings();
      final controller = CountingController();
      final library = AudioLibraryManager();
      final player = AudioPlayerProvider(
        libraryManager: library,
        controller: controller,
        playbackSettings: settings,
      );
      player.setFileList(fixture.FolderAudio().allFiles);
      await player.play(0);
      await player.interrupt(reason);
      expect(player.isPlaying, isFalse);
      await settings.setStop(reason, false);
      await player.play(0);
      await player.interrupt(reason);
      expect(player.isPlaying, isTrue);
      player.dispose();
      library.dispose();
      settings.dispose();
    });
  }

  testWidgets(
    'retained tab stops only on activation, not inactive mount or rebuild',
    (tester) async {
      final settings = PlayerSettings();
      final controller = CountingController();
      final library = AudioLibraryManager();
      final player = AudioPlayerProvider(
        libraryManager: library,
        controller: controller,
        playbackSettings: settings,
      );
      Future<void> render(bool active) async {
        await tester.pumpWidget(
          ChangeNotifierProvider<AudioPlayerProvider>.value(
            value: player,
            child: MaterialApp(
              home: MusicPlaybackEntry(
                reason: PlaybackInterruption.stageAndProfile,
                active: active,
                child: const Text('Tab'),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
      }

      await settings.load();
      await render(false);
      expect(controller.stops, 0);
      await render(true);
      expect(controller.stops, 1);
      await render(true);
      expect(controller.stops, 1);
      await render(false);
      await render(true);
      expect(controller.stops, 2);
      await settings.setStop(PlaybackInterruption.stageAndProfile, false);
      await render(false);
      await render(true);
      expect(controller.stops, 2);
      await tester.pumpWidget(const SizedBox.shrink());
      player.dispose();
      library.dispose();
      settings.dispose();
    },
  );

  testWidgets(
    'video settings expose eight combined sort choices and no direction switch',
    (tester) async {
      await PlayerSettings.instance.load();
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => AppData(),
          child: MaterialApp(
            home: VideoSettingsPage(
              videoNames: const {},
              viewMode: 0,
              onViewMode: (_) {},
            ),
          ),
        ),
      );
      expect(find.byType(SwitchListTile), findsOneWidget);
      await tester.tap(find.text('Sort'));
      await tester.pumpAndSettle();
      expect(find.byType(SimpleDialogOption), findsNWidgets(8));
      for (final option in playerSortOptions) {
        for (final ascending in ['Ascending', 'Descending']) {
          expect(
            find.descendant(
              of: find.byType(SimpleDialog),
              matching: find.text('${option.$3} - $ascending'),
            ),
            findsOneWidget,
          );
        }
      }
      await tester.tap(find.text('Duration - Descending'));
      await tester.pumpAndSettle();
      expect(PlayerSettings.instance.videoSort, 'duration');
      expect(PlayerSettings.instance.videoSortAscending, isFalse);
      expect(find.text('Duration - Descending'), findsOneWidget);
      final restored = PlayerSettings();
      await restored.load();
      expect(restored.videoSort, 'duration');
      expect(restored.videoSortAscending, isFalse);
      restored.dispose();
    },
  );
}
