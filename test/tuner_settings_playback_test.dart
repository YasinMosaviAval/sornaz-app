import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sornaz/helpers/app_data.dart';
import 'package:sornaz/helpers/app_locale_provider.dart';
import 'package:sornaz/screens/Tuner/controller/tuner_provider.dart';
import 'package:sornaz/screens/Tuner/audio/note_player.dart';
import 'package:sornaz/screens/Metronome/ui/components/labeled_slider.dart';
import 'package:sornaz/screens/Tuner/ui/pages/tuner_settings.dart';

void main() {
  testWidgets('silence slider is enabled only for intermittent playback', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final tuner = TunerProvider(notePlayer: _SilentNotePlayer());
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AppData()),
          ChangeNotifierProvider(create: (_) => LocaleProvider()),
          ChangeNotifierProvider<TunerProvider>.value(value: tuner),
        ],
        child: const MaterialApp(
          locale: Locale('fa'),
          supportedLocales: [Locale('fa'), Locale('en')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: TunerSettingsPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final silenceTile = find.ancestor(
      of: find.textContaining('میزان سکوت'),
      matching: find.byType(LabeledSlider),
    );
    final silence = find.descendant(
      of: silenceTile,
      matching: find.byType(Slider),
    );
    expect(tester.widget<Slider>(silence).onChanged, isNull);
    await tester.tap(find.text('نوع پخش'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('پخش منفصل'));
    await tester.pumpAndSettle();
    expect(tester.widget<Slider>(silence).onChanged, isNotNull);
    tuner.dispose();
  });
}

class _SilentNotePlayer extends NotePlayer {
  @override
  Future<void> stop() async {}
}
