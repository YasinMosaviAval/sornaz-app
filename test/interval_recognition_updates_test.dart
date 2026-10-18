import 'dart:async';
import 'interval_test_storage.dart';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sornaz/helpers/app_data.dart';
import 'package:sornaz/helpers/app_colors.dart';
import 'package:sornaz/helpers/app_locale_provider.dart';
import 'package:sornaz/helpers/app_translations.dart';
import 'package:sornaz/screens/IntervalRecognition/audio.dart';
import 'package:sornaz/screens/IntervalRecognition/controller.dart';
import 'package:sornaz/screens/IntervalRecognition/models.dart';
import 'package:sornaz/screens/IntervalRecognition/settings.dart';
import 'package:sornaz/screens/IntervalRecognition/settings_screen.dart';
import 'package:sornaz/screens/IntervalRecognition/levels_screen.dart';
import 'package:sornaz/screens/IntervalRecognition/play_button.dart';
import 'package:sornaz/screens/IntervalRecognition/training_screen.dart';
import 'interval_recognition_test.dart' as fixture;

class ControlledRandom implements Random {
  ControlledRandom(this.indices);
  final List<int> indices;
  int calls = 0;
  @override
  int nextInt(int max) => indices[(calls++) % indices.length] % max;
  @override
  bool nextBool() => nextInt(2) == 1;
  @override
  double nextDouble() => nextInt(1000) / 1000;
}

class SampleOutput implements IntervalSampleOutput {
  final List<String> assets = [];
  final List<String> events = [];
  bool active = false;
  bool disposed = false;
  bool fail = false;
  @override
  Future<void> start(String asset) async {
    if (fail) throw StateError('Test audio failure');
    expect(active, isFalse, reason: 'A note must stop before the next starts');
    active = true;
    assets.add(asset);
    events.add('start');
  }

  @override
  Future<void> volume(double value) async {
    events.add('volume:$value');
  }

  @override
  Future<void> stop() async {
    active = false;
    events.add('stop');
  }

  @override
  Future<void> dispose() async {
    active = false;
    disposed = true;
  }
}

Widget host(Widget page, {LocaleProvider? locale}) => MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => AppData()),
    ChangeNotifierProvider.value(
      value: locale ?? (LocaleProvider()..setLocale('en')),
    ),
  ],
  child: Consumer<LocaleProvider>(
    builder: (context, p, _) => MaterialApp(
      locale: p.locale,
      supportedLocales: const [Locale('en'), Locale('fa')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: page,
    ),
  ),
);

void main() {
  useIntervalTestStorage();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'all 44 levels allow arbitrarily long independent runs of each interval',
    () {
      for (final level in IntervalLevel.all) {
        for (var index = 0; index < level.intervals.length; index++) {
          final random = ControlledRandom([index]);
          final generator = IntervalQuestionGenerator(random: random);
          final questions = List.generate(30, (_) => generator.generate(level));
          expect(
            questions.every((q) => q.interval == level.intervals[index]),
            isTrue,
          );
          expect(random.calls, level.variableRoot ? 60 : 30);
        }
      }
    },
  );
  test(
    'two-option levels follow controlled draws, never forced alternation',
    () {
      const sequence = [0, 0, 1, 1, 1, 0, 0, 0];
      for (final level in IntervalLevel.all.take(4)) {
        final random = ControlledRandom(
          level.variableRoot
              ? [
                  for (final i in sequence) ...[i, 0],
                ]
              : sequence,
        );
        final generator = IntervalQuestionGenerator(random: random);
        expect(
          List.generate(8, (_) => generator.generate(level).interval),
          sequence.map((i) => level.intervals[i]),
        );
      }
    },
  );
  test(
    'seeded frequency distribution is compatible with equal probabilities in every level',
    () {
      final generator = IntervalQuestionGenerator(random: Random(87435));
      for (final level in IntervalLevel.all) {
        final counts = {for (final interval in level.intervals) interval: 0};
        for (var i = 0; i < 12000; i++) {
          final interval = generator.generate(level).interval;
          counts[interval] = counts[interval]! + 1;
        }
        final expected = 12000 / level.intervals.length;
        for (final count in counts.values) {
          expect(count, closeTo(expected, expected * .12));
        }
      }
    },
  );

  test(
    'audio settings default to 1000ms piano, clamp and persist rapid changes',
    () async {
      final settings = IntervalAudioSettings();
      await settings.ready;
      expect(settings.noteDurationMs, 1000);
      expect(settings.instrument, IntervalInstrument.piano);
      await settings.setDuration(200);
      expect(settings.noteDurationMs, 500);
      await settings.setDuration(747);
      expect(settings.noteDurationMs, 750);
      await Future.wait([
        settings.setDuration(800),
        settings.setDuration(950),
        settings.setInstrument(IntervalInstrument.cello),
      ]);
      await settings.flush();
      final restored = IntervalAudioSettings();
      await restored.ready;
      expect(restored.noteDurationMs, 950);
      expect(restored.instrument, IntervalInstrument.cello);
      expect(restored.errorKey, isNull);
      settings.dispose();
      restored.dispose();
    },
  );
  test('malformed audio preferences fall back to defaults', () async {
    final prefs = await SharedPreferences.getInstance();
    for (final raw in [
      'invalid',
      '[]',
      '{"durationMs":9999,"instrument":"unknown"}',
    ]) {
      await prefs.setString(IntervalAudioSettings.key, raw);
      final settings = IntervalAudioSettings();
      await settings.ready;
      expect(settings.noteDurationMs, 1000);
      expect(settings.instrument, IntervalInstrument.piano);
      settings.dispose();
    }
  });

  test(
    'real playback service chooses each bank and applies note durations without changing training state',
    () async {
      final settings = IntervalAudioSettings();
      await settings.ready;
      final output = SampleOutput();
      final delays = <Duration>[];
      final audio = InstrumentIntervalAudio(
        settings: settings,
        output: output,
        delay: (duration) async {
          delays.add(duration);
        },
      );
      final store = fixture.MemoryStore();
      final c = IntervalTrainingController(
        levelNumber: 1,
        audio: audio,
        store: store,
        progress: await store.load(),
        feedbackDuration: Duration.zero,
      );
      await fixture.answer(c);
      final q = c.question;
      c.select(q.interval);
      for (final instrument in IntervalInstrument.values) {
        await settings.setInstrument(instrument);
        await settings.setDuration(
          instrument == IntervalInstrument.piano
              ? 1000
              : instrument == IntervalInstrument.cello
              ? 2000
              : 750,
        );
        delays.clear();
        output.assets.clear();
        await c.play();
        expect(output.assets, [
          instrument.asset(q.rootMidi),
          instrument.asset(q.targetMidi),
        ]);
        expect(
          delays.fold<int>(0, (sum, duration) => sum + duration.inMilliseconds),
          settings.noteDurationMs * 2 + 150,
        );
        expect(output.active, isFalse);
        expect(c.question, same(q));
        expect(c.selected, q.interval);
        expect(c.wins, 1);
      }
      c.dispose();
      await Future<void>.delayed(Duration.zero);
      expect(output.disposed, isTrue);
      settings.dispose();
    },
  );
  test(
    'settings snapshots keep both notes consistent; following replay uses new timbre and duration',
    () async {
      final settings = IntervalAudioSettings();
      await settings.ready;
      final output = SampleOutput();
      final delays = <Duration>[];
      var changed = false;
      final audio = InstrumentIntervalAudio(
        settings: settings,
        output: output,
        delay: (duration) async {
          delays.add(duration);
          if (!changed) {
            changed = true;
            await settings.setDuration(500);
            await settings.setInstrument(IntervalInstrument.viola);
          }
        },
      );
      final q = IntervalQuestionGenerator().generate(IntervalLevel.all.first);
      await audio.play(q);
      expect(output.assets, [
        IntervalInstrument.piano.asset(q.rootMidi),
        IntervalInstrument.piano.asset(q.targetMidi),
      ]);
      expect(delays.fold<int>(0, (sum, d) => sum + d.inMilliseconds), 2150);
      output.assets.clear();
      delays.clear();
      await audio.play(q);
      expect(output.assets, [
        IntervalInstrument.viola.asset(q.rootMidi),
        IntervalInstrument.viola.asset(q.targetMidi),
      ]);
      expect(delays.fold<int>(0, (sum, d) => sum + d.inMilliseconds), 1150);
      await audio.dispose();
      settings.dispose();
    },
  );
  test(
    'stop during first note cancels second note; next replay remains available',
    () async {
      final settings = IntervalAudioSettings();
      await settings.ready;
      final output = SampleOutput();
      final waiting = Completer<void>();
      final entered = Completer<void>();
      var hold = true;
      final audio = InstrumentIntervalAudio(
        settings: settings,
        output: output,
        delay: (_) async {
          if (hold) {
            entered.complete();
            await waiting.future;
          }
        },
      );
      final q = IntervalQuestionGenerator().generate(IntervalLevel.all.first);
      final play = audio.play(q);
      await entered.future;
      await audio.stop();
      hold = false;
      waiting.complete();
      await play;
      expect(output.assets, [IntervalInstrument.piano.asset(q.rootMidi)]);
      await audio.play(q);
      expect(output.assets, hasLength(3));
      expect(output.active, isFalse);
      await audio.dispose();
      settings.dispose();
    },
  );
  test('all five banks cover 88 notes with distinct real audio bytes', () {
    for (var midi = 21; midi <= 108; midi++) {
      final banks = [
        for (final instrument in IntervalInstrument.values)
          File('assets/${instrument.asset(midi)}').readAsBytesSync(),
      ];
      for (final bytes in banks) {
        expect(bytes.length, greaterThan(1000));
        expect(
          bytes[0] == 0xff || String.fromCharCodes(bytes.take(3)) == 'ID3',
          isTrue,
        );
      }
      for (var i = 0; i < banks.length; i++) {
        for (var j = i + 1; j < banks.length; j++) {
          expect(banks[i], isNot(banks[j]));
        }
      }
    }
  });

  test(
    'decoded sample audit confirms every note is audible for the maximum duration',
    () {
      final lines = File(
        'assets/audio/interval_samples_audit.csv',
      ).readAsLinesSync();
      expect(lines, hasLength(441));
      final assets = <String>{};
      var extended = 0;
      for (final line in lines.skip(1)) {
        final fields = line.split(',');
        expect(assets.add(fields[0]), isTrue);
        expect(double.parse(fields[4]), greaterThanOrEqualTo(2));
        expect(double.parse(fields[5]), greaterThan(.0001));
        expect(
          int.parse(fields[1]) - int.parse(fields[2]),
          int.parse(fields[3]),
        );
        if (fields[3] != '0') extended++;
      }
      expect(extended, 20);
    },
  );

  test(
    'sample playback errors stop audio and leave the current question retryable',
    () async {
      final settings = IntervalAudioSettings();
      await settings.ready;
      final output = SampleOutput()..fail = true;
      final audio = InstrumentIntervalAudio(
        settings: settings,
        output: output,
        delay: (_) async {},
      );
      final store = fixture.MemoryStore();
      final c = IntervalTrainingController(
        levelNumber: 1,
        audio: audio,
        store: store,
        progress: await store.load(),
      );
      final q = c.question;
      c.select(q.interval);
      await c.play();
      expect(c.errorKey, 'interval.audioError');
      expect(output.active, isFalse);
      expect(c.playing, isFalse);
      expect(c.question, same(q));
      expect(c.selected, q.interval);
      expect(c.wins, 0);
      output.fail = false;
      await c.play();
      expect(c.errorKey, isNull);
      expect(output.assets, hasLength(2));
      c.dispose();
      settings.dispose();
    },
  );
  test('new labels and instrument names are translated', () {
    final fa = AppLocalizations(const Locale('fa'));
    final en = AppLocalizations(const Locale('en'));
    for (final key in [
      'interval.settingsTitle',
      'interval.duration',
      'interval.durationValue',
      'interval.instrument',
      'interval.settingsLoadError',
      'interval.settingsSaveError',
      ...IntervalInstrument.values.map((v) => v.translationKey),
    ]) {
      expect(fa.translate(key), isNot(key));
      expect(en.translate(key), isNot(key));
      expect(fa.translate(key), isNot(en.translate(key)));
    }
  });

  testWidgets(
    'level details use isolated bidi segments, hyphens, unchanged icons and 16dp bottom padding',
    (tester) async {
      final locale = LocaleProvider();
      await tester.pumpWidget(
        host(
          IntervalLevelsScreen(store: fixture.MemoryStore()),
          locale: locale,
        ),
      );
      await tester.pumpAndSettle();
      final list = tester.widget<ListView>(find.byType(ListView));
      expect(list.padding, const EdgeInsets.fromLTRB(12, 12, 12, 16));
      final tile = find.byType(ListTile).first;
      expect(
        find.descendant(of: tile, matching: find.text(' - ')),
        findsNWidgets(3),
      );
      final root = find.descendant(of: tile, matching: find.text('C4'));
      expect(tester.widget<Text>(root).textDirection, TextDirection.ltr);
      expect(
        find.descendant(of: tile, matching: find.text('نت مبدا:')),
        findsOneWidget,
      );
      expect(
        tester.getCenter(root).dx,
        lessThan(
          tester
              .getCenter(
                find.descendant(of: tile, matching: find.text('نت مبدا:')),
              )
              .dx,
        ),
      );
      expect(find.byIcon(Icons.play_circle_outline), findsOneWidget);
      locale.setLocale('en');
      await tester.pumpAndSettle();
      expect(
        tester.getCenter(root).dx,
        greaterThan(
          tester
              .getCenter(
                find.descendant(
                  of: tile,
                  matching: find.text('Starting Note:'),
                ),
              )
              .dx,
        ),
      );
      expect(tester.takeException(), isNull);
    },
  );

  for (final level in [1, 9, 17, 25, 33, 41]) {
    testWidgets(
      'level $level uses 24dp insets, fixed Check and centered 100dp Play',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(400, 700));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final c = fixture.training(level: level);
        final store = fixture.MemoryStore();
        await tester.pumpWidget(
          host(
            IntervalTrainingScreen(
              levelNumber: level,
              store: store,
              progress: c.progress,
              controller: c,
            ),
          ),
        );
        await tester.pumpAndSettle();
        final options = find.byType(OutlinedButton);
        expect(
          options,
          findsNWidgets(
            level == 1
                ? 2
                : level == 9
                ? 4
                : level == 17
                ? 6
                : level == 25
                ? 8
                : level == 33
                ? 10
                : 12,
          ),
        );
        for (var i = 0; i < options.evaluate().length; i++) {
          expect(tester.getSize(options.at(i)).width, 352);
          if (i > 0) {
            expect(
              tester.getTopLeft(options.at(i)).dy,
              greaterThan(tester.getBottomLeft(options.at(i - 1)).dy),
            );
          }
        }
        final check = find.widgetWithText(FilledButton, 'Check');
        final before = tester.getCenter(check);
        expect(before.dy, greaterThan(600));
        if (level >= 17) {
          await tester.drag(
            find.byType(SingleChildScrollView),
            const Offset(0, -1000),
          );
          await tester.pumpAndSettle();
        }
        expect(tester.getCenter(check), before);
        final play = find.byTooltip('Play Interval');
        expect(tester.getSize(play), const Size(100, 100));
        expect(tester.getCenter(play).dx, 200);
        expect(find.byType(IntervalPlayButton), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }
  testWidgets(
    'selected answer result overrides selection color and resets with next question',
    (tester) async {
      final c = fixture.training(feedback: const Duration(seconds: 1));
      final store = fixture.MemoryStore();
      await tester.pumpWidget(
        host(
          IntervalTrainingScreen(
            levelNumber: 1,
            store: store,
            progress: c.progress,
            controller: c,
          ),
        ),
      );
      await tester.pumpAndSettle();
      Color? background(TrainingInterval interval) => tester
          .widget<OutlinedButton>(
            find.byKey(ValueKey('interval.option.${interval.id}')),
          )
          .style!
          .backgroundColor
          ?.resolve({WidgetState.disabled});
      final right = c.question.interval;
      c.select(right);
      await tester.pump();
      final scheme = Theme.of(
        tester.element(find.byType(Scaffold)),
      ).colorScheme;
      expect(background(right), scheme.primary.withValues(alpha: .25));
      await c.check();
      await tester.pump();
      expect(background(right), AppColors.success);
      await tester.pump(const Duration(milliseconds: 500));
      expect(background(right), AppColors.success);
      await tester.pump(const Duration(milliseconds: 500));
      expect(background(right), isNull);
      final wrong = c.level.intervals.firstWhere(
        (v) => v != c.question.interval,
      );
      c.select(wrong);
      await c.check();
      await tester.pump();
      expect(background(wrong), scheme.error);
      expect(c.wins, 0);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'gear opens settings; editing both controls and locale preserves current question, selection and wins',
    (tester) async {
      final settings = IntervalAudioSettings();
      final locale = LocaleProvider()..setLocale('en');
      final c = fixture.training(feedback: const Duration(seconds: 1));
      final store = fixture.MemoryStore();
      await tester.pumpWidget(
        host(
          IntervalTrainingScreen(
            levelNumber: 1,
            store: store,
            progress: c.progress,
            controller: c,
            settings: settings,
          ),
          locale: locale,
        ),
      );
      await tester.pumpAndSettle();
      c.select(c.question.interval);
      await c.check();
      await tester.pump(const Duration(seconds: 1));
      final q = c.question;
      c.select(q.interval);
      await tester.pump();
      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();
      expect(find.byType(IntervalSettingsScreen), findsOneWidget);
      expect(find.text('Interval Recognition Settings'), findsOneWidget);
      final slider = tester.widget<Slider>(find.byType(Slider));
      expect(slider.min, 500);
      expect(slider.max, 2000);
      expect(slider.value, 1000);
      expect(slider.divisions, 30);
      slider.onChanged!(750);
      await tester.pumpAndSettle();
      expect(find.text('Note Duration: 750 ms'), findsOneWidget);
      await tester.tap(find.text('Instrument Sound'));
      await tester.pumpAndSettle();
      expect(find.byType(SimpleDialogOption), findsNWidgets(5));
      locale.setLocale('fa');
      await tester.pumpAndSettle();
      expect(find.text('ویولن سل'), findsOneWidget);
      await tester.tap(find.text('ویولن سل'));
      await tester.pumpAndSettle();
      expect(settings.instrument, IntervalInstrument.cello);
      locale.setLocale('fa');
      await tester.pumpAndSettle();
      expect(find.text('تنظیمات تشخیص فاصله'), findsOneWidget);
      expect(find.text('مدت زمان پخش هر نت: ۷۵۰ میلی‌ثانیه'), findsOneWidget);
      expect(
        Directionality.of(tester.element(find.byType(Slider))),
        TextDirection.rtl,
      );
      expect(settings.noteDurationMs, 750);
      expect(settings.instrument, IntervalInstrument.cello);
      await tester.tap(find.byType(BackButton).last);
      await tester.pumpAndSettle();
      expect(c.question, same(q));
      expect(c.selected, q.interval);
      expect(c.wins, 1);
      expect(c.level.number, 1);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      settings.dispose();
    },
  );
}
