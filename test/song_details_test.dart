import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sornaz/screens/Players/metadata/audio_metadata.dart';
import 'package:sornaz/screens/Players/providers/audio_player_provider.dart';
import 'package:sornaz/screens/Players/scan/audio_file.dart';
import 'package:sornaz/screens/Players/ui/pages/lyrics.dart';
import 'package:sornaz/screens/Players/ui/pages/song_information.dart';
import 'social_widget_test.dart' as fixture;

class _Audio extends ChangeNotifier implements AudioPlayerProvider {
  AudioFile track = AudioFile(
    file: File('/music/one.mp3'),
    fileName: 'one.mp3',
    folderName: 'music',
    duration: const Duration(minutes: 2),
  );
  @override
  AudioFile get currentAudio => track;
  @override
  AudioMetadata get currentMetadata => AudioMetadata(
    title: 'Title',
    artist: 'Artist',
    artwork: Uint8List.fromList([1, 2, 3]),
    details: {
      'filename': 'hidden-name',
      'folder': 'hidden-folder',
      'duration': 'hidden-duration',
    },
  );
  void changeTrack() {
    track = AudioFile(
      file: File('/music/two.mp3'),
      fileName: 'two.mp3',
      folderName: 'music',
      duration: Duration.zero,
    );
    notifyListeners();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  testWidgets('lyrics persist per file and survive switching tracks', (
    tester,
  ) async {
    final audio = _Audio();
    Widget host() => fixture.host(
      ChangeNotifierProvider<AudioPlayerProvider>.value(
        value: audio,
        child: const Scaffold(body: SongLyricsTab()),
      ),
    );
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'My title');
    await tester.enterText(
      find.byType(TextField).last,
      'First line\nSecond line',
    );
    await tester.pumpAndSettle();
    final original = audio.track;
    audio.changeTrack();
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(find.byType(TextField).last).controller!.text,
      isEmpty,
    );
    await tester.enterText(find.byType(TextField).last, 'Other song');
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox());
    audio.track = original;
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(find.byType(TextField).first).controller!.text,
      'My title',
    );
    expect(
      tester.widget<TextField>(find.byType(TextField).last).controller!.text,
      'First line\nSecond line',
    );
    await tester.pumpWidget(const SizedBox());
    audio.dispose();
  });
  testWidgets('information uses fallback cover and hides removed fields', (
    tester,
  ) async {
    final audio = _Audio();
    await tester.pumpWidget(
      fixture.host(
        ChangeNotifierProvider<AudioPlayerProvider>.value(
          value: audio,
          child: const SongDetailsPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('اطلاعات'));
    await tester.pumpAndSettle();
    expect(find.byType(DefaultSongCover), findsOneWidget);
    expect(find.text('one.mp3'), findsNothing);
    for (final value in ['hidden-name', 'hidden-folder', 'hidden-duration']) {
      expect(find.text(value), findsNothing);
    }
    expect(
      tester
          .widget<SelectableText>(
            find.byWidgetPredicate(
              (widget) => widget is SelectableText && widget.data == 'Artist',
            ),
          )
          .style!
          .fontSize,
      12,
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    audio.dispose();
  });
}
