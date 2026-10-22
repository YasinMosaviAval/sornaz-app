import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sornaz/components/app_scroll_behavior.dart';
import 'package:sornaz/screens/Players/library/audio_library_manager.dart';
import 'package:sornaz/screens/Players/providers/audio_player_provider.dart';
import 'package:sornaz/screens/Players/scan/audio_file.dart';
import 'package:sornaz/screens/Players/services/media_file_operations.dart';
import 'package:sornaz/screens/Players/services/player_settings.dart';
import 'package:sornaz/screens/Players/services/music_playlists.dart';
import 'package:sornaz/screens/Players/ui/pages/playlists.dart';
import 'package:sornaz/screens/Players/ui/components/audio_item.dart';
import 'player_behavior_revision_test.dart' show MemoryController;
import 'social_widget_test.dart' as fixture;

AudioFile song(String name) => AudioFile(
  file: File('/music/$name.mp3'),
  fileName: '$name.mp3',
  folderName: '/music',
  duration: const Duration(seconds: 20),
);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('device refresh preserves playlist order and next track', (
    tester,
  ) async {
    final library = AudioLibraryManager(hydrateMetadata: false);
    final settings = PlayerSettings();
    await settings.setOption('savePlaybackPosition', false);
    final controller = MemoryController();
    final player = AudioPlayerProvider(
      libraryManager: library,
      controller: controller,
      playbackSettings: settings,
    );
    final a = song('a'), b = song('b'), outside = song('outside');
    player.setFileList([a, b, outside]);
    await player.playFromFolder([b, a], 0, listKey: 'practice');
    library.allFiles = [outside, a, b, song('new')];
    await library.setRoots([]);
    expect(player.filteredFiles, [b, a]);
    expect(player.isActiveCollection([b, a], 'practice'), isTrue);
    expect(player.isActiveCollection([b, a], '/music'), isFalse);
    await player.playNext();
    expect(player.currentAudio, a);
    await player.onTrackComplete();
    expect(player.isPlaying, isFalse);
    await tester.pump();
    player.dispose();
    library.dispose();
    settings.dispose();
  });

  test(
    'moving a file preserves source on collision and moves on success',
    () async {
      final root = await Directory.systemTemp.createTemp('sornaz-move-');
      try {
        final source = await File(
          '${root.path}/song.mp3',
        ).writeAsString('source');
        final folder = await Directory('${root.path}/album').create();
        final target = await File(
          '${folder.path}/song.mp3',
        ).writeAsString('existing');
        await expectLater(
          MediaFileOperations.relocate(source.path, target.path),
          throwsA(isA<FileSystemException>()),
        );
        expect(await source.readAsString(), 'source');
        expect(await target.readAsString(), 'existing');
        await target.delete();
        expect(
          await MediaFileOperations.relocate(source.path, target.path),
          target.path,
        );
        expect(await source.exists(), isFalse);
        expect(await target.readAsString(), 'source');
      } finally {
        await root.delete(recursive: true);
      }
    },
  );

  testWidgets(
    'playlist tap replaces the folder queue and selection hides row menus',
    (tester) async {
      final library = AudioLibraryManager(hydrateMetadata: false);
      final settings = PlayerSettings();
      await settings.setOption('savePlaybackPosition', false);
      final player = AudioPlayerProvider(
        libraryManager: library,
        controller: MemoryController(),
        playbackSettings: settings,
      );
      final a = song('a'), b = song('b'), outside = song('outside');
      player.setFileList([a, b, outside]);
      await player.playFromFolder([a, b, outside], 0, listKey: '/music');
      final store = MusicPlaylists.instance;
      await store.create('PracticePlayback');
      await store.add('PracticePlayback', [b.file.path, a.file.path]);
      await tester.pumpWidget(
        fixture.host(
          ChangeNotifierProvider<AudioPlayerProvider>.value(
            value: player,
            child: const Scaffold(body: PlaylistsTab()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('PracticePlayback'));
      await tester.pumpAndSettle();
      // The same file is already playing from a folder: tapping must switch context.
      await tester.tap(find.text('a'));
      await tester.pumpAndSettle();
      expect(player.filteredFiles, [b, a]);
      expect(player.isActiveCollection([b, a], 'PracticePlayback'), isTrue);
      await tester.longPress(find.byType(AudioItem).first);
      await tester.pumpAndSettle();
      expect(find.byType(PopupMenuButton<String>), findsOneWidget);
      await tester.tap(find.widgetWithIcon(IconButton, Icons.close));
      await tester.pumpAndSettle();
      expect(
        find.byType(PopupMenuButton<String>).evaluate().length,
        greaterThan(1),
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      player.dispose();
      library.dispose();
      settings.dispose();
    },
  );

  for (final direction in TextDirection.values) {
    testWidgets(
      'fast scroll stays between toolbar and playback controls: $direction',
      (tester) async {
        final controller = ScrollController();
        await tester.pumpWidget(
          MaterialApp(
            scrollBehavior: const AppScrollBehavior(),
            home: Directionality(
              textDirection: direction,
              child: Scaffold(
                body: Column(
                  children: [
                    const SizedBox(key: ValueKey('tabs'), height: 60),
                    Expanded(
                      child: ListView.builder(
                        controller: controller,
                        itemExtent: 50,
                        itemCount: 1000,
                        itemBuilder: (_, i) => Text('item $i'),
                      ),
                    ),
                    const SizedBox(key: ValueKey('controls'), height: 100),
                  ],
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final scrollbar = tester.widget<Scrollbar>(find.byType(Scrollbar));
        expect(
          scrollbar.scrollbarOrientation,
          direction == TextDirection.rtl
              ? ScrollbarOrientation.right
              : ScrollbarOrientation.left,
        );
        final bounds = tester.getRect(find.byType(Scrollbar));
        expect(
          bounds.top,
          tester.getRect(find.byKey(const ValueKey('tabs'))).bottom,
        );
        expect(
          bounds.bottom,
          tester.getRect(find.byKey(const ValueKey('controls'))).top,
        );
        final x = direction == TextDirection.rtl
            ? bounds.right - 4
            : bounds.left + 4;
        await tester.dragFrom(
          Offset(x, bounds.top + 12),
          Offset(0, bounds.height * .7),
        );
        await tester.pumpAndSettle();
        expect(
          controller.offset,
          greaterThan(controller.position.maxScrollExtent * .4),
        );
        expect(find.byType(Text).evaluate().length, lessThan(40));
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        controller.dispose();
      },
    );
  }
}
