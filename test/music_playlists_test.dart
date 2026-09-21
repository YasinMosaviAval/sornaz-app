import 'dart:io';
import 'package:provider/provider.dart';
import 'package:sornaz/screens/Players/scan/audio_file.dart';
import 'package:sornaz/screens/Players/providers/audio_player_provider.dart';
import 'package:sornaz/screens/Players/ui/pages/playlists.dart';
import 'player_slides_test.dart' as audio_fixture;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sornaz/screens/Players/services/music_playlists.dart';
import 'package:sornaz/screens/Players/ui/components/playback_speed_dialog.dart';
import 'social_widget_test.dart' as fixture;

class PlaylistAudio extends audio_fixture.Audio {
  @override
  List<AudioFile> allFiles = [
    AudioFile(
      file: File('/one.mp3'),
      fileName: 'one.mp3',
      folderName: '/',
      duration: const Duration(seconds: 10),
    ),
    AudioFile(
      file: File('/two.mp3'),
      fileName: 'two.mp3',
      folderName: '/',
      duration: const Duration(seconds: 20),
    ),
  ];
  List<AudioFile>? queue;
  @override
  Future<void> playFromFolder(List<AudioFile> files, int index) async {
    queue = files;
  }
}

void main() {
  test(
    'favorites migrate and playlist membership survives rename and removal',
    () async {
      SharedPreferences.setMockInitialValues({
        'music.favorites': ['/a.mp3'],
        'music.playlists': '{"Practice":["/b.mp3"]}',
      });
      final store = MusicPlaylists();
      await store.load();
      expect(store.lists[MusicPlaylists.favorite], ['/a.mp3']);
      expect(store.lists['Practice'], ['/b.mp3']);
      expect(await store.create('   '), isNull);
      expect(await store.create('Practice'), 'Practice');
      await store.create('Evening');
      await Future.wait([
        store.add('Evening', ['/a.mp3', '/a.mp3']),
        store.add(MusicPlaylists.favorite, ['/b.mp3']),
      ]);
      await store.replacePath('/a.mp3', '/renamed.mp3');
      expect(store.lists['Evening'], ['/renamed.mp3']);
      expect(store.lists[MusicPlaylists.favorite], contains('/renamed.mp3'));
      await store.replacePath('/b.mp3', null);
      expect(store.lists['Practice'], isEmpty);
      expect(store.lists[MusicPlaylists.favorite], ['/renamed.mp3']);
      await store.remove('Evening', '/renamed.mp3');
      expect(store.lists['Evening'], isEmpty);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getStringList('music.favorites'), ['/renamed.mp3']);
      expect(prefs.getString('music.playlists'), contains('Evening'));
    },
  );
  testWidgets('create a playlist, add multiple files, and play its queue', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final audio = PlaylistAudio();
    await tester.pumpWidget(
      fixture.host(
        ChangeNotifierProvider<AudioPlayerProvider>.value(
          value: audio,
          child: const Scaffold(body: PlaylistsTab()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.playlist_add));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'New Mix');
    await tester.tap(find.text('ایجاد'));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.add), findsNothing);
    final choose = chooseMusicPlaylist(
      tester.element(find.byType(PlaylistsTab)),
      audio.allFiles,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('New Mix').last);
    await tester.pumpAndSettle();
    await choose;
    await tester.pumpAndSettle();
    expect(MusicPlaylists.instance.lists['New Mix'], ['/one.mp3', '/two.mp3']);
    await tester.tap(find.byIcon(Icons.play_circle_filled).first);
    await tester.pumpAndSettle();
    expect(audio.queue?.length, 2);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    audio.dispose();
  });
  testWidgets(
    'speed presets move the slider and dragging chooses an intermediate speed',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      double speed = 1;
      await tester.pumpWidget(
        fixture.host(
          Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showPlaybackSpeedDialog(
                  context,
                  speed: 1,
                  presets: [.25, .5, .75, 1, 1.25, 1.5, 1.75, 2, 3, 4],
                  onChanged: (v) => speed = v,
                ),
                child: const Text('speed'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('speed'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('2.0×'));
      await tester.pumpAndSettle();
      expect(speed, 2);
      expect(tester.widget<Slider>(find.byType(Slider)).value, 2);
      await tester.drag(find.byType(Slider), const Offset(-25, 0));
      await tester.pumpAndSettle();
      expect(speed, isNot(2));
      expect(speed, inInclusiveRange(.25, 4));
      expect(tester.takeException(), isNull);
    },
  );
}
