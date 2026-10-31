import 'package:flutter/material.dart';
import 'dart:io';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sornaz/components/app_dialog.dart';
import 'package:sornaz/components/media_dialogs.dart';
import 'package:sornaz/screens/Players/services/music_playlists.dart';
import 'package:sornaz/screens/Players/ui/pages/playlists.dart';
import 'package:sornaz/screens/Players/ui/components/file_actions.dart';
import 'package:sornaz/screens/Players/scan/audio_file.dart';
import 'package:sornaz/screens/Site/panel_ui.dart';
import 'package:sornaz/screens/Voice%20Recorder/ui/components/delete_confirm_dialog.dart';
import 'package:sornaz/screens/Voice%20Recorder/ui/pages/recordings_list.dart';

class SpyPlaylists extends MusicPlaylists {
  int deleted = 0;
  @override
  Future<void> delete(String key) async {
    deleted++;
  }
}

Widget host(
  Widget child, {
  Brightness brightness = Brightness.light,
  String locale = 'en',
}) => MaterialApp(
  locale: Locale(locale),
  supportedLocales: const [Locale('fa'), Locale('en')],
  localizationsDelegates: const [
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  theme: ThemeData(
    brightness: brightness,
    fontFamily: 'SelectedFont',
    cardTheme: CardThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
    ),
  ),
  home: Scaffold(body: child),
);

void main() {
  testWidgets(
    'music removal retains both choices with shared destructive styling at 320px',
    (tester) async {
      tester.view.physicalSize = const Size(320, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final file = AudioFile(
        file: File('/fixture/song.mp3'),
        fileName: 'song.mp3',
        folderName: '/fixture',
        duration: const Duration(seconds: 10),
      );
      await tester.pumpWidget(
        host(
          Builder(
            builder: (c) => TextButton(
              onPressed: () => showDeleteConfirm(c, file),
              child: const Text('Open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      final actions = find.descendant(
        of: find.byType(AppDialog),
        matching: find.byType(AppDialogAction),
      );
      expect(actions, findsNWidgets(3));
      expect(
        tester.widget<AppDialogAction>(actions.first).role,
        AppDialogActionRole.cancel,
      );
      expect(
        tester.widget<AppDialogAction>(actions.at(1)).role,
        AppDialogActionRole.destructive,
      );
      expect(
        tester.widget<AppDialogAction>(actions.at(2)).role,
        AppDialogActionRole.destructive,
      );
      await tester.tap(actions.first);
      await tester.pumpAndSettle();
      expect(find.byType(AppDialog), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  for (final brightness in Brightness.values) {
    for (final locale in ['fa', 'en']) {
      testWidgets(
        'shared delete dialog respects appearance and cancellation: $brightness/$locale',
        (tester) async {
          bool? result;
          await tester.pumpWidget(
            host(
              Builder(
                builder: (context) => TextButton(
                  onPressed: () async {
                    result = await showDeleteConfirmation(
                      context,
                      title: 'Delete item?',
                      message: 'Existing results will remain.',
                    );
                  },
                  child: const Text('Open'),
                ),
              ),
              brightness: brightness,
              locale: locale,
            ),
          );
          await tester.tap(find.text('Open'));
          await tester.pumpAndSettle();
          expect(find.byType(DeleteConfirmationDialog), findsOneWidget);
          final dialog = tester.widget<AlertDialog>(find.byType(AlertDialog));
          expect(dialog.titleTextStyle!.fontSize, 14);
          expect(dialog.contentTextStyle!.fontSize, 12);
          expect(dialog.titleTextStyle!.fontFamily, 'SelectedFont');
          expect(
            (dialog.shape! as RoundedRectangleBorder).borderRadius,
            BorderRadius.circular(11),
          );
          final actions = find.descendant(
            of: find.byType(AlertDialog),
            matching: find.byType(TextButton),
          );
          expect(
            tester
                .widget<TextButton>(actions.first)
                .style!
                .foregroundColor!
                .resolve({}),
            Colors.grey,
          );
          expect(
            tester
                .widget<TextButton>(actions.last)
                .style!
                .foregroundColor!
                .resolve({}),
            Colors.red,
          );
          expect(
            tester
                .widget<TextButton>(actions.last)
                .style!
                .textStyle!
                .resolve({})!
                .fontSize,
            12,
          );
          expect(result, isNull);
          await tester.tap(actions.first);
          await tester.pumpAndSettle();
          expect(result, false);
          await tester.tap(find.text('Open'));
          await tester.pumpAndSettle();
          await tester.tap(actions.last);
          await tester.pumpAndSettle();
          expect(result, true);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
  testWidgets('dismissal never confirms deletion', (tester) async {
    bool? result;
    await tester.pumpWidget(
      host(
        Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              result = await showDeleteConfirmation(context, title: 'Delete?');
            },
            child: const Text('Open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();
    expect(result, false);
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(result, false);
  });
  testWidgets(
    'video and recorder deletion entry points use the shared widget',
    (tester) async {
      final entries = <Future<bool?> Function(BuildContext)>[
        (c) => confirmMediaDelete(c, 'Video'),
        (c) => confirmRecordingDelete(c, 'Recording'),
        (c) => showPanelConfirmation(c, 'Panel item', delete: true),
        (c) => showDeleteConfirmDialog(c, 'voice.wav'),
      ];
      for (final entry in entries) {
        bool? result;
        await tester.pumpWidget(
          host(
            Builder(
              builder: (c) => TextButton(
                onPressed: () async {
                  result = await entry(c);
                },
                child: const Text('Open'),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();
        expect(find.byType(DeleteConfirmationDialog), findsOneWidget);
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();
        expect(result, false);
      }
    },
  );
  testWidgets(
    'playlist deletion preserves cancel and only deletes after confirmation',
    (tester) async {
      final store = SpyPlaylists();
      await tester.pumpWidget(
        host(
          Builder(
            builder: (c) => TextButton(
              onPressed: () =>
                  editAudioCollection(c, store, 'Playlist', delete: true),
              child: const Text('Open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.byType(DeleteConfirmationDialog), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(store.deleted, 0);
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      expect(store.deleted, 1);
      store.dispose();
    },
  );
}
