import 'dart:io';
import 'development_test_host.dart';
import 'interval_test_storage.dart';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sornaz/helpers/app_locale_provider.dart';
import 'package:sornaz/helpers/app_translations.dart';
import 'package:sornaz/screens/Authentication/providers/auth_session.dart';
import 'package:sornaz/screens/IntervalRecognition/access.dart';
import 'package:sornaz/screens/IntervalRecognition/audio.dart';
import 'package:sornaz/screens/IntervalRecognition/controller.dart';
import 'package:sornaz/screens/IntervalRecognition/iranian_curriculum.dart';
import 'package:sornaz/screens/IntervalRecognition/models.dart';
import 'package:sornaz/screens/IntervalRecognition/progress.dart';
import 'package:sornaz/screens/IntervalRecognition/settings.dart';
import 'package:sornaz/screens/IntervalRecognition/settings_screen.dart';
import 'package:sornaz/screens/IntervalRecognition/levels_screen.dart';
import 'package:sornaz/screens/IntervalRecognition/training_screen.dart';
import 'interval_recognition_test.dart' as fixture;
import 'interval_recognition_updates_test.dart' as updates;
import 'interval_curriculum_access_test.dart' as access_tests;

IntervalTrainingController iranian({
  int level = 1,
  IntervalAudioSettings? settings,
  IntervalAudio? audio,
  IntervalProgressStore? store,
  IntervalAccess access = const IntervalAccess(),
}) => IntervalTrainingController(
  levelNumber: level,
  music: IntervalMusic.iranian,
  settings: settings,
  audio: audio ?? fixture.TestAudio(),
  store: store ?? fixture.MemoryStore(),
  access: access,
  feedbackDuration: Duration.zero,
  progress: IntervalProgress(
    music: IntervalMusic.iranian,
    completed: {for (var i = 1; i < level; i++) i},
  ),
);

void main() {
  useIntervalTestStorage();
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test(
    '24 unique quarter-step intervals have exact half-semitone increments and translations',
    () {
      expect(IranianInterval.values, hasLength(24));
      expect(
        IranianInterval.values.map((v) => v.number),
        List.generate(24, (i) => i + 1),
      );
      expect(IranianInterval.values.map((v) => v.id).toSet(), hasLength(24));
      for (final interval in IranianInterval.values) {
        expect(interval.semitones, interval.number / 2);
        for (final language in ['en', 'fa']) {
          final title = AppLocalizations(
            Locale(language),
          ).translate(interval.translationKey);
          expect(title, isNot(interval.translationKey));
          expect(title, isNotEmpty);
        }
      }
      expect(IranianInterval.values.first.semitones, .5);
      expect(IranianInterval.values[1].semitones, 1);
      expect(IranianInterval.values.last.semitones, 12);
    },
  );
  test(
    '45 unique stages generate 180 levels with exact adjacent and cumulative progression',
    () {
      final stages = IranianCurriculum.stages;
      expect(stages, hasLength(45));
      expect(IranianCurriculum.levels, hasLength(180));
      expect(stages.first.map((v) => v.quarterSteps), [1, 2]);
      final signatures = <String>{};
      for (var stage = 0; stage < stages.length; stage++) {
        final steps = stages[stage].map((v) => v.quarterSteps).toList();
        expect(signatures.add(steps.join(',')), isTrue);
        if (stage > 0) {
          final introduced = (stage + 1) ~/ 2 + 2;
          expect(
            steps,
            stage.isOdd
                ? [introduced - 1, introduced]
                : List.generate(introduced, (i) => i + 1),
          );
        }
        for (var offset = 0; offset < 4; offset++) {
          final level = IranianCurriculum.levels[stage * 4 + offset];
          expect(level.number, stage * 4 + offset + 1);
          expect(level.intervals, stages[stage]);
          expect(level.music, IntervalMusic.iranian);
          expect(
            level.direction,
            offset.isEven
                ? IntervalDirection.ascending
                : IntervalDirection.descending,
          );
          expect(level.variableRoot, offset >= 2);
        }
      }
      expect(stages.last, IranianInterval.values);
      expect(IranianCurriculum.levels.last.number, 180);
    },
  );
  test(
    'all Iranian questions retain exact 24-TET frequency ratios and valid piano bounds',
    () {
      final generator = IntervalQuestionGenerator(random: Random(93));
      for (final level in IranianCurriculum.levels) {
        for (var i = 0; i < 100; i++) {
          final q = generator.generate(level);
          final sign = level.direction == IntervalDirection.ascending ? 1 : -1;
          expect(q.targetMidi - q.rootMidi, sign * q.quarterSteps / 2);
          expect(
            q.targetFrequency / q.rootFrequency,
            closeTo(pow(2, sign * q.quarterSteps / 24), 1e-12),
          );
          expect(q.rootMidi, inInclusiveRange(21, 108));
          expect(q.targetMidi, inInclusiveRange(21, 108));
          expect(level.intervals, contains(q.interval));
        }
      }
      final pitches = [
        for (final interval in IranianInterval.values)
          440 * pow(2, interval.quarterSteps / 24),
      ];
      expect(pitches.toSet(), hasLength(24));
    },
  );
  test('controlled repeated draws are allowed in all Iranian levels', () {
    for (final level in IranianCurriculum.levels) {
      final generator = IntervalQuestionGenerator(
        random: updates.ControlledRandom([0]),
      );
      expect(
        List.generate(10, (_) => generator.generate(level).interval).toSet(),
        {level.intervals.first},
      );
    }
  });
  test(
    'fixed starting note works across both branches and random levels ignore it',
    () {
      for (final music in IntervalMusic.values) {
        for (final root in [48, 62, 72]) {
          final levels = IntervalLevel.levelsFor(music);
          for (final level in levels.where((v) => !v.variableRoot)) {
            final q = IntervalQuestionGenerator(
              random: Random(42),
            ).generate(level, startingMidi: root);
            expect(q.rootMidi, root);
            expect(q.targetMidi, inInclusiveRange(21, 108));
          }
          for (final level in levels.where((v) => v.variableRoot)) {
            final a = IntervalQuestionGenerator(
              random: Random(15),
            ).generate(level, startingMidi: 48);
            final b = IntervalQuestionGenerator(
              random: Random(15),
            ).generate(level, startingMidi: 72);
            expect(a.rootMidi, b.rootMidi);
            expect(a.targetMidi, b.targetMidi);
          }
        }
      }
      final q = IntervalQuestionGenerator(
        random: updates.ControlledRandom([0]),
      ).generate(IntervalLevel.all.first, startingMidi: 62);
      expect(q.targetMidi, 69);
      final down = IntervalQuestionGenerator(
        random: updates.ControlledRandom([0]),
      ).generate(IntervalLevel.all[1], startingMidi: 62);
      expect(down.targetMidi, 55);
    },
  );
  test(
    'starting note persists, validates bounds, and old duration/instrument preferences survive',
    () async {
      SharedPreferences.setMockInitialValues({
        IntervalAudioSettings.key: '{"durationMs":1750,"instrument":"viola"}',
      });
      final settings = IntervalAudioSettings();
      await settings.ready;
      expect(settings.startingMidi, 60);
      expect(settings.noteDurationMs, 1750);
      expect(settings.instrument, IntervalInstrument.viola);
      expect(
        IntervalAudioSettings.startingNotes,
        List.generate(25, (i) => 48 + i),
      );
      expect(IntervalAudioSettings.noteName(48), 'C3');
      expect(IntervalAudioSettings.noteName(60), 'C4');
      expect(IntervalAudioSettings.noteName(72), 'C5');
      await settings.setStartingMidi(63);
      expect(() => settings.setStartingMidi(47), throwsArgumentError);
      final restored = IntervalAudioSettings();
      await restored.ready;
      expect(restored.startingMidi, 63);
      expect(restored.noteDurationMs, 1750);
      expect(restored.instrument, IntervalInstrument.viola);
      settings.dispose();
      restored.dispose();
    },
  );
  test(
    'changing root never regenerates a current question; next fixed question uses it in both branches',
    () async {
      for (final music in IntervalMusic.values) {
        final settings = IntervalAudioSettings();
        await settings.ready;
        final c = IntervalTrainingController(
          levelNumber: 1,
          music: music,
          audio: fixture.TestAudio(),
          store: fixture.MemoryStore(),
          progress: IntervalProgress(music: music),
          settings: settings,
          feedbackDuration: Duration.zero,
        );
        final q = c.question;
        c.select(q.interval);
        await settings.setStartingMidi(62);
        expect(c.question, same(q));
        expect(c.selected, q.interval);
        expect(c.wins, 0);
        await c.play();
        expect(c.question, same(q));
        await fixture.answer(c);
        expect(c.question.rootMidi, 62);
        expect(c.wins, 1);
        c.dispose();
        settings.dispose();
      }
    },
  );
  test(
    'preloaded starting note is used before training becomes interactive',
    () async {
      SharedPreferences.setMockInitialValues({
        IntervalAudioSettings.key:
            '{"startingMidi":72,"durationMs":1000,"instrument":"piano"}',
      });
      final settings = IntervalAudioSettings();
      final c = iranian(settings: settings);
      expect(c.initializing, isTrue);
      await settings.ready;
      await Future<void>.delayed(Duration.zero);
      expect(c.initializing, isFalse);
      expect(c.question.rootMidi, 72);
      c.dispose();
      settings.dispose();
    },
  );

  test(
    'revoking access during settings initialization stops loading and cannot replace the question',
    () async {
      final settings = IntervalAudioSettings();
      final c = iranian(settings: settings);
      final q = c.question;
      c.revokeAccess();
      await settings.ready;
      await Future<void>.delayed(Duration.zero);
      expect(c.accessRevoked, isTrue);
      expect(c.initializing, isFalse);
      expect(c.question, same(q));
      await c.play();
      expect(c.wins, 0);
      c.dispose();
      settings.dispose();
    },
  );
  test(
    'quarter replay routes to distinct instrument samples and subsequent Western replay remains unshifted',
    () async {
      final settings = IntervalAudioSettings();
      await settings.ready;
      final output = updates.SampleOutput();
      final audio = InstrumentIntervalAudio(
        settings: settings,
        output: output,
        delay: (_) async {},
      );
      final q = IntervalQuestionGenerator(
        random: updates.ControlledRandom([0]),
      ).generate(IranianCurriculum.levels.first);
      expect(q.targetMidi, 60.5);
      for (final instrument in IntervalInstrument.values) {
        await settings.setInstrument(instrument);
        output.assets.clear();
        for (var i = 0; i < 20; i++) {
          await audio.play(q);
        }
        expect(output.assets, hasLength(40));
        expect(output.assets[1], instrument.asset(60.5));
        expect(output.assets.first, instrument.asset(60));
        final western = IntervalQuestionGenerator(
          random: updates.ControlledRandom([0]),
        ).generate(IntervalLevel.all.first);
        output.assets.clear();
        await audio.play(western);
        expect(output.assets, [instrument.asset(60), instrument.asset(67)]);
      }
      await audio.dispose();
      settings.dispose();
    },
  );
  test(
    '435 quarter-tone files are distinct from adjacent semitones, decoded and correctly pitched in audit',
    () {
      final lines = File(
        'assets/audio/interval_quarter_audit.csv',
      ).readAsLinesSync();
      expect(lines, hasLength(436));
      for (final line in lines.skip(1)) {
        final fields = line.split(',');
        final quarter = int.parse(fields[1]);
        final source = int.parse(fields[2]);
        expect(quarter, source * 2 + 1);
        expect(fields[3], '50');
        expect(double.parse(fields[4]).abs(), lessThan(.01));
        expect(double.parse(fields[5]), greaterThanOrEqualTo(2));
        expect(double.parse(fields[6]), greaterThan(.0001));
        final bytes = File('assets/${fields[0]}').readAsBytesSync();
        expect(bytes.length, greaterThan(1000));
        final folder = fields[0].split('/')[1].replaceAll('_quarter', '');
        expect(
          bytes,
          isNot(File('assets/audio/$folder/$source.mp3').readAsBytesSync()),
        );
        expect(
          bytes,
          isNot(
            File('assets/audio/$folder/${source + 1}.mp3').readAsBytesSync(),
          ),
        );
      }
    },
  );
  test(
    'branch and account progress are isolated and Western migration remains unchanged',
    () async {
      final western = IntervalProgressRepository(userId: 2);
      final iranian = IntervalProgressRepository(
        userId: 2,
        music: IntervalMusic.iranian,
      );
      await western.save(IntervalProgress().complete(1));
      final prefs = await SharedPreferences.getInstance();
      final before = prefs.getString(western.scopedKey);
      expect((await iranian.load()).completed, isEmpty);
      await iranian.save((await iranian.load()).complete(1));
      expect(prefs.getString(western.scopedKey), before);
      expect(
        (await IntervalProgressRepository(
          userId: 3,
          music: IntervalMusic.iranian,
        ).load()).completed,
        isEmpty,
      );
      expect(() => iranian.save(IntervalProgress()), throwsArgumentError);
      await prefs.setString(IntervalProgressRepository.key, '[1,2,3,4]');
      expect(
        (await IntervalProgressRepository(
          music: IntervalMusic.iranian,
        ).load()).completed,
        isEmpty,
      );
      expect((await IntervalProgressRepository().load()).completed, {
        1,
        2,
        3,
        4,
      });
    },
  );
  test(
    'both branches use ten consecutive wins and Iranian level 180 finishes without 181',
    () async {
      final c = iranian();
      await fixture.answer(c);
      expect(c.wins, 1);
      await fixture.answer(c, right: false);
      expect(c.wins, 0);
      for (var i = 0; i < 9; i++) {
        await fixture.answer(c);
      }
      expect(c.level.number, 1);
      await fixture.answer(c);
      expect(c.level.number, 2);
      expect(c.wins, 0);
      c.dispose();
      final last = iranian(level: 180);
      for (var i = 0; i < 10; i++) {
        await fixture.answer(last);
      }
      expect(last.finished, isTrue);
      expect(last.level.number, 180);
      expect(last.progress.completed, hasLength(180));
      expect(last.progress.unlocked, isNot(contains(181)));
      last.dispose();
    },
  );
  test(
    'admin gets 180 Iranian and 44 Western available levels without automatic completion',
    () {
      const admin = IntervalAccess(userId: 1);
      const user = IntervalAccess(userId: 2);
      for (final music in IntervalMusic.values) {
        final progress = IntervalProgress(music: music);
        expect(
          IntervalLevel.levelsFor(
            music,
          ).every((v) => admin.canEnter(v.number, progress, music: music)),
          isTrue,
        );
        expect(progress.completed, isEmpty);
        expect(user.canEnter(2, progress, music: music), isFalse);
      }
    },
  );
  testWidgets(
    '24 long options are vertical, scrollable, localized and keep state on locale change',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final locale = LocaleProvider();
      final c = iranian(level: 177, access: const IntervalAccess(userId: 1));
      final store = fixture.MemoryStore();
      await tester.pumpWidget(
        developmentAdmin(
          updates.host(
            IntervalTrainingScreen(
              levelNumber: 177,
              music: IntervalMusic.iranian,
              store: store,
              progress: c.progress,
              controller: c,
            ),
            locale: locale,
          ),
        ),
      );
      await tester.pumpAndSettle();
      final q = c.question;
      c.select(q.interval);
      await tester.pump();
      expect(find.byType(OutlinedButton), findsNWidgets(24));
      final options = find.byType(OutlinedButton);
      for (var i = 1; i < 24; i++) {
        expect(
          tester.getTopLeft(options.at(i)).dy,
          greaterThan(tester.getBottomLeft(options.at(i - 1)).dy),
        );
      }
      final check = find.widgetWithText(FilledButton, 'بررسی');
      final position = tester.getCenter(check);
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -4000),
      );
      await tester.pumpAndSettle();
      expect(tester.getCenter(check), position);
      expect(tester.takeException(), isNull);
      locale.setLocale('en');
      await tester.pumpAndSettle();
      expect(c.question, same(q));
      expect(c.selected, q.interval);
      expect(c.wins, 0);
      expect(
        find.text('Raised Major Seventh / Lowered Perfect Octave'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'starting-note menu has all 25 notes and level tiles reflect the saved root in LTR',
    (tester) async {
      final settings = IntervalAudioSettings();
      await tester.pumpWidget(
        developmentAdmin(
          updates.host(IntervalSettingsScreen(settings: settings)),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Starting Note'));
      await tester.pumpAndSettle();
      expect(find.byType(SimpleDialogOption), findsNWidgets(25));
      await tester.ensureVisible(find.text('D4'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('D4'));
      await tester.pumpAndSettle();
      expect(settings.startingMidi, 62);
      await tester.pumpWidget(
        developmentAdmin(
          updates.host(
            IntervalLevelsScreen(
              music: IntervalMusic.iranian,
              settings: settings,
              store: fixture.MemoryStore()
                ..progress = IntervalProgress(music: IntervalMusic.iranian),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('D4'), findsWidgets);
      expect(
        tester.widget<Text>(find.text('D4').first).textDirection,
        TextDirection.ltr,
      );
      await tester.pumpWidget(const SizedBox());
      settings.dispose();
    },
  );
  testWidgets(
    'admin completes final Iranian level with the 180-level final message',
    (tester) async {
      final session = AuthSession();
      await access_tests.signIn(session, 1);
      final c = IntervalTrainingController(
        levelNumber: 180,
        music: IntervalMusic.iranian,
        audio: fixture.TestAudio(),
        store: fixture.MemoryStore(),
        progress: IntervalProgress(music: IntervalMusic.iranian),
        access: const IntervalAccess(userId: 1),
        feedbackDuration: const Duration(seconds: 1),
      );
      await tester.pumpWidget(
        access_tests.authenticatedHost(
          session,
          IntervalTrainingScreen(
            levelNumber: 180,
            music: IntervalMusic.iranian,
            store: c.store,
            progress: c.progress,
            controller: c,
            access: c.access,
          ),
        ),
      );
      await tester.pumpAndSettle();
      for (var i = 0; i < 10; i++) {
        c.select(c.question.interval);
        await c.check();
        await tester.pump(const Duration(seconds: 1));
      }
      expect(
        find.text(
          'Congratulations! You have successfully completed all 180 levels of Iranian Music Interval Recognition.',
        ),
        findsOneWidget,
      );
      expect(c.progress.completed, {180});
      await tester.pumpWidget(const SizedBox());
      session.dispose();
    },
  );
}
