import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sornaz/components/music_accidental_glyph.dart';
import 'package:sornaz/screens/Tuner/controller/tuner_provider.dart';
import 'package:sornaz/screens/Tuner/ui/components/piano_keyboard.dart';
import 'social_widget_test.dart' as fixture;
import 'tuner_professional_playback_test.dart' show RecordingNotePlayer;

void main() {
  test('bundled official Bravura is an OpenType font', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final bytes = await rootBundle.load('assets/notation/fonts/Bravura.otf');
    expect(String.fromCharCodes(bytes.buffer.asUint8List(0, 4)), 'OTTO');
    expect(
      await rootBundle.loadString('assets/notation/fonts/LICENSE.txt'),
      contains('SIL OPEN FONT LICENSE'),
    );
  });
  testWidgets(
    'tuner quarter-tone keys display Bravura signs and retain pitch',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final player = RecordingNotePlayer();
      final tuner = TunerProvider(notePlayer: player);
      tuner.keyboardSettings.showQuarterTones = true;
      tuner.keyboardSettings.startOctave = 4;
      tuner.keyboardSettings.octaveCount = 1;
      await tester.pumpWidget(
        fixture.host(
          ChangeNotifierProvider<TunerProvider>.value(
            value: tuner,
            child: const Scaffold(body: PianoKeyboard()),
          ),
        ),
      );
      await tester.pump();
      final koron = find.byWidgetPredicate(
        (w) => w is MusicAccidentalGlyph && w.accidental == 'k',
      );
      final sori = find.byWidgetPredicate(
        (w) => w is MusicAccidentalGlyph && w.accidental == 'o',
      );
      expect(koron, findsWidgets);
      expect(sori, findsWidgets);
      final text = tester.widget<Text>(
        find.descendant(of: koron.first, matching: find.byType(Text)),
      );
      expect(text.data, '\uE460');
      expect(text.style!.fontFamily, 'Bravura');
      final labels = tester
          .widgetList<Text>(find.byType(Text))
          .where((text) => text.data != null);
      expect(labels, isNotEmpty);
      for (final label in labels) {
        final value = label.data!;
        expect(value, isNot(contains('↑')));
        expect(value, isNot(contains('↓')));
      }
      expect(
        find.ancestor(of: koron.first, matching: find.byType(Row)),
        findsOneWidget,
      );
      await tester.tap(koron.first);
      await tester.pump();
      expect(
        player.played.last,
        closeTo(440 * pow(2, (61 - 69 + .5) / 12), .0001),
      );
      await tester.pumpWidget(const SizedBox());
      tuner.dispose();
    },
  );
}
