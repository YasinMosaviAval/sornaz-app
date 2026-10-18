import 'dart:async';
import 'interval_test_storage.dart';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sornaz/helpers/app_locale_provider.dart';
import 'package:sornaz/helpers/app_translations.dart';
import 'package:sornaz/screens/IntervalRecognition/audio.dart';
import 'package:sornaz/screens/IntervalRecognition/controller.dart';
import 'package:sornaz/screens/IntervalRecognition/models.dart';
import 'package:sornaz/screens/IntervalRecognition/progress.dart';
import 'package:sornaz/screens/IntervalRecognition/levels_screen.dart';
import 'package:sornaz/screens/IntervalRecognition/training_screen.dart';
import 'package:sornaz/screens/Home/ui/pages/solfege_practice_page.dart';

class TestAudio implements IntervalAudio {
  final List<IntervalQuestion> played = [];
  bool disposed = false;
  int stops = 0;
  bool hold = false;
  int active = 0;
  int maximumActive = 0;
  Completer<void>? pending;
  @override
  Future<void> play(IntervalQuestion question) async {
    played.add(question);
    active++;
    maximumActive = max(maximumActive, active);
    if (hold) pending = Completer<void>();
    await pending?.future;
    active--;
  }

  @override
  Future<void> stop() async {
    stops++;
    if (pending != null && !pending!.isCompleted) pending!.complete();
  }

  @override
  Future<void> dispose() async {
    disposed = true;
    await stop();
  }
}

class MemoryStore implements IntervalProgressStore {
  IntervalProgress progress = IntervalProgress();
  bool fail = false;
  @override
  Future<IntervalProgress> load() async => progress;
  @override
  Future<void> save(IntervalProgress value) async {
    if (fail) throw StateError('Test save failure');
    progress = value;
  }
}

IntervalTrainingController training({
  int level = 1,
  TestAudio? audio,
  MemoryStore? store,
  Duration feedback = Duration.zero,
}) => IntervalTrainingController(
  levelNumber: level,
  audio: audio ?? TestAudio(),
  store: store ?? MemoryStore(),
  progress: IntervalProgress(completed: {for (var i = 1; i < level; i++) i}),
  generator: IntervalQuestionGenerator(random: Random(42)),
  feedbackDuration: feedback,
);

Future<void> answer(IntervalTrainingController c, {bool right = true}) async {
  c.select(
    right
        ? c.question.interval
        : c.level.intervals.firstWhere((v) => v != c.question.interval),
  );
  await c.check();
  await Future<void>.delayed(const Duration(milliseconds: 1));
}

void main() {
  useIntervalTestStorage();
  test('all 44 level configurations and 12 semitone categories are exact', () {
    final groups = [
      [MusicalInterval.perfectFifth, MusicalInterval.perfectOctave],
      [MusicalInterval.minorThird, MusicalInterval.majorThird],
      [
        MusicalInterval.minorThird,
        MusicalInterval.majorThird,
        MusicalInterval.perfectFifth,
        MusicalInterval.perfectOctave,
      ],
      [MusicalInterval.majorSecond, MusicalInterval.perfectFourth],
      [
        MusicalInterval.majorSecond,
        MusicalInterval.minorThird,
        MusicalInterval.majorThird,
        MusicalInterval.perfectFourth,
        MusicalInterval.perfectFifth,
        MusicalInterval.perfectOctave,
      ],
      [MusicalInterval.majorSixth, MusicalInterval.majorSeventh],
      [
        MusicalInterval.majorSecond,
        MusicalInterval.minorThird,
        MusicalInterval.majorThird,
        MusicalInterval.perfectFourth,
        MusicalInterval.perfectFifth,
        MusicalInterval.majorSixth,
        MusicalInterval.majorSeventh,
        MusicalInterval.perfectOctave,
      ],
      [MusicalInterval.minorSecond, MusicalInterval.minorSeventh],
      [
        MusicalInterval.minorSecond,
        MusicalInterval.majorSecond,
        MusicalInterval.minorThird,
        MusicalInterval.majorThird,
        MusicalInterval.perfectFourth,
        MusicalInterval.perfectFifth,
        MusicalInterval.majorSixth,
        MusicalInterval.minorSeventh,
        MusicalInterval.majorSeventh,
        MusicalInterval.perfectOctave,
      ],
      [MusicalInterval.tritone, MusicalInterval.augmentedFifth],
      MusicalInterval.values,
    ];
    expect(IntervalLevel.all, hasLength(44));
    expect(IntervalLevel.middleC, 60);
    expect(IntervalLevel.requiredWins, 10);
    expect(
      MusicalInterval.values.map((v) => v.semitones),
      List.generate(12, (i) => i + 1),
    );
    for (var i = 0; i < 44; i++) {
      final level = IntervalLevel.all[i];
      expect(level.number, i + 1);
      expect(level.intervals, groups[i ~/ 4]);
      expect(
        level.direction,
        i.isEven ? IntervalDirection.ascending : IntervalDirection.descending,
      );
      expect(level.variableRoot, i % 4 >= 2);
    }
  });

  test(
    'questions preserve exact distances, bounds, fixed roots and random exposure',
    () {
      final generator = IntervalQuestionGenerator(random: Random(123));
      final ids = <int>{};
      for (final level in IntervalLevel.all) {
        final roots = <int>{};
        final seen = <TrainingInterval>{};
        for (var i = 0; i < 1000; i++) {
          final q = generator.generate(level);
          expect(ids.add(q.id), isTrue);
          expect(q.level, level.number);
          expect(q.direction, level.direction);
          expect(level.intervals, contains(q.interval));
          expect(q.rootMidi, inInclusiveRange(21, 108));
          expect(q.targetMidi, inInclusiveRange(21, 108));
          expect(
            q.targetMidi - q.rootMidi,
            q.semitones *
                (level.direction == IntervalDirection.ascending ? 1 : -1),
          );
          if (!level.variableRoot) expect(q.rootMidi, 60);
          roots.add(q.rootMidi);
          seen.add(q.interval);
        }
        expect(seen, level.intervals.toSet());
        if (level.variableRoot) expect(roots.length, greaterThan(30));
      }
    },
  );

  test(
    'unlimited replay preserves question, selection, answer and streak',
    () async {
      final audio = TestAudio();
      final c = training(audio: audio);
      await answer(c);
      final q = c.question;
      c.select(q.interval);
      for (var i = 0; i < 25; i++) {
        await c.play();
      }
      expect(audio.played, hasLength(25));
      expect(audio.played.every((p) => identical(p, q)), isTrue);
      expect(c.question, same(q));
      expect(c.selected, q.interval);
      expect(c.wins, 1);
      expect(c.playing, isFalse);
      c.dispose();
      expect(audio.disposed, isTrue);
    },
  );

  test(
    'rapid play cannot overlap and stopping invalidates late completion',
    () async {
      final audio = TestAudio()..hold = true;
      final c = training(audio: audio);
      final q = c.question;
      final first = c.play();
      await Future<void>.delayed(Duration.zero);
      expect(audio.played, hasLength(1));
      expect(c.playing, isTrue);
      final second = c.play();
      final third = c.play();
      await Future<void>.delayed(Duration.zero);
      expect(audio.played, hasLength(2));
      expect(c.playing, isTrue);
      expect(audio.maximumActive, 1);
      expect(c.question, same(q));
      await c.stopPlayback();
      await Future.wait([first, second, third]);
      expect(c.playing, isFalse);
      audio.hold = false;
      audio.pending = null;
      await c.play();
      expect(audio.played, hasLength(3));
      c.dispose();
    },
  );

  test(
    'selection does not score, duplicate checks blocked, wrong resets streak',
    () async {
      final c = training(feedback: const Duration(milliseconds: 20));
      final q = c.question;
      c.select(q.interval);
      expect(c.wins, 0);
      expect(c.question, same(q));
      await c.check();
      await c.check();
      expect(c.wins, 1);
      expect(c.question, same(q));
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(c.question.id, isNot(q.id));
      expect(c.selected, isNull);
      expect(c.playing, isFalse);
      await answer(c, right: false);
      expect(c.wins, 0);
      expect(c.correct, isFalse);
      c.dispose();
    },
  );

  test('ten wins save, unlock, advance and reset without autoplay', () async {
    final store = MemoryStore();
    final audio = TestAudio();
    final c = training(store: store, audio: audio);
    for (var i = 0; i < 9; i++) {
      await answer(c);
    }
    expect(c.level.number, 1);
    expect(c.wins, 9);
    expect(store.progress.completed, isEmpty);
    await answer(c);
    expect(c.level.number, 2);
    expect(c.wins, 0);
    expect(c.selected, isNull);
    expect(c.level.direction, IntervalDirection.descending);
    expect(store.progress.completed, {1});
    expect(store.progress.highestUnlocked, 2);
    expect(audio.played, isEmpty);
    c.dispose();
  });

  test(
    'level 8 advances into four options and level 44 finishes without level 45',
    () async {
      final c = training(level: 8);
      for (var i = 0; i < 10; i++) {
        await answer(c);
      }
      expect(c.level.number, 9);
      expect(c.level.intervals, hasLength(4));
      expect(c.question.rootMidi, 60);
      c.dispose();
      final last = training(level: 44);
      for (var i = 0; i < 10; i++) {
        await answer(last);
      }
      expect(last.finished, isTrue);
      expect(last.level.number, 44);
      expect(last.progress.completed, hasLength(44));
      last.dispose();
    },
  );

  test(
    'failed persistence is retryable before advancing; dispose cancels transition',
    () async {
      final store = MemoryStore()..fail = true;
      final c = training(store: store);
      for (var i = 0; i < 10; i++) {
        await answer(c);
      }
      expect(c.errorKey, 'interval.saveError');
      expect(c.level.number, 1);
      expect(c.checking, isTrue);
      store.fail = false;
      await c.retrySave();
      await Future<void>.delayed(const Duration(milliseconds: 1));
      expect(c.level.number, 2);
      c.dispose();
      final delayed = training(feedback: const Duration(milliseconds: 10));
      final q = delayed.question;
      delayed.select(q.interval);
      await delayed.check();
      delayed.dispose();
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(delayed.question, same(q));
    },
  );

  test('progress survives repository reload; corrupt data handled', () async {
    SharedPreferences.setMockInitialValues({});
    final repository = IntervalProgressRepository();
    expect((await repository.load()).highestUnlocked, 1);
    await repository.save(IntervalProgress(completed: {1, 2, 3}));
    final restored = await IntervalProgressRepository().load();
    expect(restored.completed, {1, 2, 3});
    expect(restored.highestUnlocked, 4);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(repository.scopedKey, 'broken');
    expect((await repository.load()).completed, isEmpty);
  });

  test('all 88 offline samples exist, contain audio and attribution', () {
    for (var midi = 21; midi <= 108; midi++) {
      final bytes = File(
        'assets/audio/interval_piano/$midi.mp3',
      ).readAsBytesSync();
      expect(bytes.length, greaterThan(1000));
      expect(
        bytes[0] == 0xff || String.fromCharCodes(bytes.take(3)) == 'ID3',
        isTrue,
      );
    }
    expect(
      File('assets/audio/interval_piano/NOTICE.md').readAsStringSync(),
      contains('Creative Commons Attribution 3.0'),
    );
  });

  test(
    'all interval names and interface messages have Persian and English translations',
    () {
      final fa = AppLocalizations(const Locale('fa'));
      final en = AppLocalizations(const Locale('en'));
      for (final key in [
        ...MusicalInterval.values.map((v) => v.translationKey),
        for (final name in [
          'title',
          'level',
          'trainingTitle',
          'ascending',
          'descending',
          'fixedRoot',
          'variableRoot',
          'count',
          'locked',
          'completed',
          'available',
          'wins',
          'play',
          'playing',
          'check',
          'correct',
          'incorrect',
          'answer',
          'levelComplete',
          'finished',
          'back',
          'audioError',
          'saveError',
          'loadError',
          'retry',
        ])
          'interval.$name',
      ]) {
        expect(fa.translate(key), isNot(key));
        expect(en.translate(key), isNot(key));
        expect(fa.translate(key), isNot(en.translate(key)));
      }
      expect(fa.translate('interval.perfectFifth'), 'پنجم درست');
      expect(en.translate('interval.perfectFifth'), 'Perfect Fifth');
    },
  );

  testWidgets(
    'only interval item is activated and first level alone is unlocked',
    (tester) async {
      final store = MemoryStore();
      await tester.pumpWidget(const MaterialApp(home: SolfegePracticePage()));
      final tiles = tester.widgetList<ListTile>(find.byType(ListTile)).toList();
      expect(tiles, hasLength(6));
      expect(tiles.where((t) => t.onTap != null), hasLength(1));
      await tester.pumpWidget(
        MaterialApp(home: IntervalLevelsScreen(store: store)),
      );
      await tester.pumpAndSettle();
      final levels = tester
          .widgetList<ListTile>(find.byType(ListTile))
          .toList();
      expect(levels.first.onTap, isNotNull);
      expect(levels.skip(1).every((v) => v.onTap == null), isTrue);
      await tester.drag(find.byType(ListView), const Offset(0, -5000));
      await tester.pumpAndSettle();
      expect(find.text('Level 44'), findsOneWidget);
    },
  );

  testWidgets(
    'answer controls require selection, show feedback and reset for next question',
    (tester) async {
      final store = MemoryStore();
      final audio = TestAudio();
      final c = training(
        audio: audio,
        store: store,
        feedback: const Duration(seconds: 1),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: IntervalTrainingScreen(
            levelNumber: 1,
            store: store,
            progress: c.progress,
            controller: c,
          ),
        ),
      );
      FilledButton checkButton() => tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Check'),
      );
      expect(checkButton().onPressed, isNull);
      final q = c.question;
      final wrong = c.level.intervals.firstWhere((v) => v != q.interval);
      final localization = AppLocalizations(const Locale('en'));
      await tester.tap(find.text(localization.translate(wrong.translationKey)));
      await tester.pump();
      expect(checkButton().onPressed, isNotNull);
      expect(c.wins, 0);
      await tester.tap(find.byTooltip('Play Interval'));
      await tester.pump();
      expect(c.question, same(q));
      expect(c.selected, wrong);
      await tester.tap(find.text('Check'));
      await tester.pump();
      expect(checkButton().onPressed, isNull);
      expect(
        find.text(
          'Incorrect answer.\nCorrect Answer: ${localization.translate(q.interval.translationKey)}',
        ),
        findsOneWidget,
      );
      await tester.pump(const Duration(seconds: 1));
      expect(c.selected, isNull);
      expect(c.question.id, isNot(q.id));
      expect(checkButton().onPressed, isNull);
      await tester.tap(
        find.text(localization.translate(c.question.interval.translationKey)),
      );
      await tester.pump();
      await tester.tap(find.text('Check'));
      await tester.pump();
      expect(find.text('Correct! Well done.'), findsOneWidget);
      expect(c.wins, 1);
      await tester.pumpWidget(const SizedBox());
      expect(audio.disposed, isTrue);
    },
  );

  testWidgets(
    'language and theme rebuild preserve question, streak and selected answer, RTL/LTR and small layout',
    (tester) async {
      final locale = LocaleProvider();
      final store = MemoryStore();
      final c = training(level: 41, store: store);
      c.select(c.question.interval);
      await c.check();
      await tester.pump(const Duration(milliseconds: 1));
      final q = c.question;
      c.select(q.interval);
      await tester.binding.setSurfaceSize(const Size(320, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final themeMode = ValueNotifier(false);
      addTearDown(themeMode.dispose);
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: locale,
          child: ValueListenableBuilder<bool>(
            valueListenable: themeMode,
            builder: (context, dark, _) => Consumer<LocaleProvider>(
              builder: (context, p, _) => MaterialApp(
                locale: p.locale,
                supportedLocales: const [Locale('fa'), Locale('en')],
                localizationsDelegates: GlobalMaterialLocalizations.delegates,
                theme: ThemeData(
                  brightness: dark ? Brightness.dark : Brightness.light,
                ),
                home: IntervalTrainingScreen(
                  levelNumber: 41,
                  store: store,
                  progress: c.progress,
                  controller: c,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('تشخیص فاصله - سطح ۴۱'), findsOneWidget);
      expect(
        Directionality.of(tester.element(find.text('بردهای پیاپی: ۱ از ۱۰'))),
        TextDirection.rtl,
      );
      locale.setLocale('en');
      themeMode.value = true;
      await tester.pumpAndSettle();
      expect(find.text('Interval Recognition - Level 41'), findsOneWidget);
      expect(
        Directionality.of(
          tester.element(find.text('Consecutive Wins: 1 / 10')),
        ),
        TextDirection.ltr,
      );
      expect(c.question, same(q));
      expect(c.wins, 1);
      expect(c.selected, q.interval);
      expect(c.progress.completed, hasLength(40));
      expect(find.byType(OutlinedButton), findsNWidgets(12));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
