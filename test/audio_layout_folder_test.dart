import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sornaz/helpers/app_data.dart';
import 'package:sornaz/screens/Players/ui/components/audio_item.dart';
import 'package:sornaz/screens/Players/providers/folder_navigator_provider.dart';
import 'package:sornaz/screens/Players/scan/audio_file.dart';
import 'package:sornaz/screens/Players/scan/audio_file_loader.dart';

void main() {
  testWidgets(
    'audio row centers text and equally inset actions in RTL and LTR',
    (tester) async {
      final audio = AudioFile(
        file: File('/music/song.mp3'),
        fileName: 'song.mp3',
        folderName: '/music',
        duration: const Duration(seconds: 90),
      );
      for (final direction in TextDirection.values) {
        await tester.pumpWidget(
          ChangeNotifierProvider(
            create: (_) => AppData(),
            child: MaterialApp(
              home: Scaffold(
                body: Directionality(
                  textDirection: direction,
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: SizedBox(
                      width: 360,
                      height: 64,
                      child: AudioItem(
                        audio: audio,
                        isPlaying: false,
                        index: 0,
                        selected: true,
                        onTap: () {},
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        final row = tester.getRect(find.byType(AudioItem));
        final play = tester.getRect(find.byIcon(Icons.play_circle_outline));
        final menu = tester.getRect(find.byIcon(Icons.more_vert));
        expect(play.center.dy, closeTo(row.center.dy, .1));
        expect(menu.center.dy, closeTo(row.center.dy, .1));
        expect(
          (play.center.dx - row.center.dx).abs(),
          closeTo((menu.center.dx - row.center.dx).abs(), .1),
        );
        expect(tester.getRect(find.text('song')).top, greaterThan(row.top + 4));
        expect(find.byType(Checkbox), findsNothing);
        expect(find.byIcon(Icons.check_circle), findsNothing);
        expect(tester.takeException(), isNull);
      }
    },
  );
  test(
    'folder loading retains nested audio ancestors and finishes on errors',
    () async {
      final dir = await Directory.systemTemp.createTemp('sornaz-folders-');
      final nav = FolderNavigatorProvider();
      try {
        final nested = await Directory(
          '${dir.path}/album/disc',
        ).create(recursive: true);
        await Directory('${dir.path}/empty').create();
        final file = await File('${nested.path}/song.mp3').writeAsBytes([0]);
        final audio = AudioFile(
          file: file,
          fileName: 'song.mp3',
          folderName: nested.path,
          duration: const Duration(seconds: 10),
        );
        await nav.startRealNavigation(dir);
        await nav.indexFiles([audio]);
        expect(nav.isLoading, false);
        expect(nav.subFolders.length, 1);
        await nav.enterRealFolder(nav.subFolders.single);
        expect(nav.subFolders.length, 1);
        await nav.enterRealFolder(nav.subFolders.single);
        expect(nav.audioFiles.single, same(audio));
        await nav.startRealNavigation(Directory('${dir.path}/missing'));
        expect(nav.isLoading, false);
        expect(nav.error, isNotNull);
      } finally {
        nav.dispose();
        await dir.delete(recursive: true);
      }
    },
  );
  test('scan future waits for the completion callback', () async {
    final dir = await Directory.systemTemp.createTemp('sornaz-scan-');
    try {
      await File('${dir.path}/song.mp3').writeAsBytes([0]);
      bool complete = false;
      await AudioFileLoader.scanWithIsolate(
        roots: [dir],
        onProgress: (_) {},
        onDone: (files) async {
          await Future<void>.delayed(const Duration(milliseconds: 20));
          expect(files.length, 1);
          complete = true;
        },
      );
      expect(complete, true);
    } finally {
      await dir.delete(recursive: true);
    }
  });
}
