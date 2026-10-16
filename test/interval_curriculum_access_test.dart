import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sornaz/helpers/app_translations.dart';
import 'package:sornaz/screens/Authentication/models/auth_user.dart';
import 'package:sornaz/screens/Authentication/providers/auth_session.dart';
import 'package:sornaz/screens/Authentication/services/auth_api_service.dart';
import 'package:sornaz/screens/Home/ui/pages/solfege_practice_page.dart';
import 'package:sornaz/screens/IntervalRecognition/access.dart';
import 'package:sornaz/screens/IntervalRecognition/controller.dart';
import 'package:sornaz/screens/IntervalRecognition/levels_screen.dart';
import 'package:sornaz/screens/IntervalRecognition/models.dart';
import 'package:sornaz/screens/IntervalRecognition/music_selection_screen.dart';
import 'package:sornaz/screens/IntervalRecognition/progress.dart';
import 'package:sornaz/screens/IntervalRecognition/training_screen.dart';
import 'interval_recognition_test.dart' as fixture;
import 'interval_recognition_updates_test.dart' as updates;

Future<void> signIn(AuthSession session, int id) => session.save(
  AuthResult(
    token: 'test-token-$id',
    user: AuthUser(id: id, username: 'admin', fullName: 'Test User'),
  ),
);
Widget authenticatedHost(AuthSession session, Widget page) =>
    ChangeNotifierProvider.value(value: session, child: updates.host(page));

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    '44 unique sequential levels, eleven precise sets and no duplicated enharmonic choices',
    () {
      expect(
        IntervalLevel.all.map((v) => v.number),
        List.generate(44, (i) => i + 1),
      );
      const expected = [
        [7, 12],
        [3, 4],
        [3, 4, 7, 12],
        [2, 5],
        [2, 3, 4, 5, 7, 12],
        [9, 11],
        [2, 3, 4, 5, 7, 9, 11, 12],
        [1, 10],
        [1, 2, 3, 4, 5, 7, 9, 10, 11, 12],
        [6, 8],
        [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12],
      ];
      for (final level in IntervalLevel.all) {
        expect(
          level.intervals.map((v) => v.semitones),
          expected[(level.number - 1) ~/ 4],
        );
        expect(level.intervals.toSet().length, level.intervals.length);
      }
    },
  );

  test(
    'only authenticated ID 1 has full access; usernames and incomplete sessions do not grant it',
    () async {
      final session = AuthSession();
      final progress = IntervalProgress();
      session.user = const AuthUser(id: 1, username: 'admin', fullName: 'Test');
      expect(IntervalAccess.fromSession(session).isAdministrator, isFalse);
      session.token = '';
      expect(IntervalAccess.fromSession(session).isAdministrator, isFalse);
      await signIn(session, 1);
      final access = IntervalAccess.fromSession(session);
      expect(
        IntervalLevel.all.every(
          (level) => access.canEnter(level.number, progress),
        ),
        isTrue,
      );
      expect(progress.completed, isEmpty);
      expect(access.canEnter(45, progress), isFalse);
      expect(access.canEnter(0, progress), isFalse);
      await signIn(session, 2);
      final ordinary = IntervalAccess.fromSession(session);
      expect(ordinary.isAdministrator, isFalse);
      expect(ordinary.canEnter(1, progress), isTrue);
      expect(ordinary.canEnter(44, progress), isFalse);
      session.dispose();
    },
  );

  test(
    'controller blocks direct entry for ordinary users and allows admin level 44 without fake completion',
    () async {
      final store = fixture.MemoryStore();
      expect(
        () => IntervalTrainingController(
          levelNumber: 44,
          audio: fixture.TestAudio(),
          store: store,
          progress: IntervalProgress(),
        ),
        throwsArgumentError,
      );
      final c = IntervalTrainingController(
        levelNumber: 44,
        audio: fixture.TestAudio(),
        store: store,
        progress: IntervalProgress(),
        access: const IntervalAccess(userId: 1),
        feedbackDuration: Duration.zero,
      );
      expect(c.level.number, 44);
      expect(c.progress.completed, isEmpty);
      for (var i = 0; i < 10; i++) {
        await fixture.answer(c);
      }
      expect(c.finished, isTrue);
      expect(c.progress.completed, {44});
      expect(c.progress.unlocked, isNot(contains(45)));
      c.dispose();
    },
  );

  test(
    'normal unlocks follow real completion through level 44; level 20 advances to 21',
    () async {
      final c = fixture.training(level: 20);
      for (var i = 0; i < 10; i++) {
        await fixture.answer(c);
      }
      expect(c.level.number, 21);
      expect(c.finished, isFalse);
      expect(c.wins, 0);
      c.dispose();
      var progress = IntervalProgress();
      for (var level = 1; level <= 44; level++) {
        expect(progress.isUnlocked(level), isTrue);
        if (level < 44) expect(progress.isUnlocked(level + 1), isFalse);
        progress = progress.complete(level);
      }
      expect(progress.completed, hasLength(44));
      expect(progress.isUnlocked(45), isFalse);
    },
  );

  test(
    'migration compares interval sets, direction and root type rather than level number',
    () {
      expect(
        IntervalProgressMigration.exactMatches({
          for (var i = 1; i <= 20; i++) i,
        }),
        {1, 2, 3, 4, 9, 10, 11, 12, 41, 42, 43, 44},
      );
      for (var i = 1; i <= 4; i++) {
        expect(IntervalProgressMigration.exactMatches({i}), {i});
        expect(IntervalProgressMigration.exactMatches({i + 4}), {i + 8});
        expect(IntervalProgressMigration.exactMatches({i + 16}), {i + 40});
      }
      expect(
        IntervalProgressMigration.exactMatches({
          9,
          10,
          11,
          12,
          13,
          14,
          15,
          16,
          0,
          21,
        }),
        isEmpty,
      );
    },
  );

  test(
    'legacy record remains intact; guest migration runs once and never infers unlocked gaps',
    () async {
      final prefs = await SharedPreferences.getInstance();
      const legacy = '[1,2,3,4,5,6,7,8,9,17,18,19,20]';
      await prefs.setString(IntervalProgressRepository.key, legacy);
      final repo = IntervalProgressRepository();
      final migrated = await repo.load();
      expect(migrated.completed, {1, 2, 3, 4, 9, 10, 11, 12, 41, 42, 43, 44});
      expect(migrated.isUnlocked(5), isTrue);
      expect(migrated.isUnlocked(6), isFalse);
      expect(migrated.isUnlocked(9), isTrue);
      expect(migrated.isUnlocked(13), isFalse);
      expect(prefs.getString(IntervalProgressRepository.key), legacy);
      await prefs.setString(IntervalProgressRepository.key, '[]');
      expect(
        (await IntervalProgressRepository().load()).completed,
        migrated.completed,
      );
      final record = jsonDecode(prefs.getString(repo.scopedKey)!) as Map;
      expect(record['schema'], 2);
    },
  );

  test(
    'unowned legacy progress is never copied into accounts, and scoped progress stays independent',
    () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(IntervalProgressRepository.key, '[1,2,3,4,5,17]');
      final admin = IntervalProgressRepository(userId: 1);
      final normal = IntervalProgressRepository(userId: 2);
      expect((await admin.load()).completed, isEmpty);
      expect((await normal.load()).completed, isEmpty);
      await admin.save(IntervalProgress().complete(44));
      await normal.save(IntervalProgress().complete(1));
      expect((await IntervalProgressRepository(userId: 1).load()).completed, {
        44,
      });
      expect((await IntervalProgressRepository(userId: 2).load()).completed, {
        1,
      });
      expect(
        (await IntervalProgressRepository(userId: 3).load()).completed,
        isEmpty,
      );
      expect((await IntervalProgressRepository().load()).completed, {
        1,
        2,
        3,
        4,
        9,
        41,
      });
      expect(prefs.getString(IntervalProgressRepository.key), '[1,2,3,4,5,17]');
    },
  );
  test(
    'concurrent initialization and malformed legacy data cannot repeat or corrupt migration',
    () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(IntervalProgressRepository.key, 'broken');
      final repo = IntervalProgressRepository();
      final results = await Future.wait([
        repo.load(),
        IntervalProgressRepository().load(),
      ]);
      expect(results.every((v) => v.completed.isEmpty), isTrue);
      expect(prefs.getString(IntervalProgressRepository.key), 'broken');
      await repo.save(results.first.complete(1));
      await prefs.setString(IntervalProgressRepository.key, '[1,2,3]');
      expect((await repo.load()).completed, {1});
    },
  );

  test('branch labels and final level message exist in both languages', () {
    for (final locale in ['en', 'fa']) {
      final t = AppLocalizations(Locale(locale));
      for (final key in [
        'iranianMusic',
        'westernMusic',
        'iranianTitle',
        'westernTitle',
        'iranianComingSoon',
        'accountChanged',
      ]) {
        expect(t.translate('interval.$key'), isNot('interval.$key'));
      }
      expect(
        t.translate('interval.finished'),
        contains(locale == 'fa' ? '۴۴' : '44'),
      );
    }
  });

  testWidgets('Solfege routes to Iranian 180 levels and Western 44 levels', (
    tester,
  ) async {
    await tester.pumpWidget(updates.host(const SolfegePracticePage()));
    await tester.tap(find.text('Interval Recognition'));
    await tester.pumpAndSettle();
    expect(find.byType(IntervalMusicSelectionScreen), findsOneWidget);
    expect(find.text('Iranian Music'), findsOneWidget);
    expect(find.text('Western Music'), findsOneWidget);
    await tester.tap(find.text('Iranian Music'));
    await tester.pumpAndSettle();
    expect(find.byType(IranianIntervalScreen), findsOneWidget);
    expect(find.byType(IntervalLevelsScreen), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, -25000));
    await tester.pumpAndSettle();
    expect(find.text('Level 180'), findsOneWidget);
    expect(find.byType(OutlinedButton), findsNothing);
    await tester.tap(find.byType(BackButton).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Western Music'));
    await tester.pumpAndSettle();
    expect(find.byType(IntervalLevelsScreen), findsOneWidget);
    await tester.drag(find.byType(ListView).last, const Offset(0, -7000));
    await tester.pumpAndSettle();
    expect(find.text('Level 44'), findsOneWidget);
    await tester.tap(find.byType(BackButton).last);
    await tester.pumpAndSettle();
    expect(find.text('Western Music'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'admin list shows all levels available but none completed; account switch immediately locks them',
    (tester) async {
      final session = AuthSession();
      await signIn(session, 1);
      await tester.pumpWidget(
        authenticatedHost(session, const IntervalLevelsScreen()),
      );
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.lock_outline), findsNothing);
      expect(find.byIcon(Icons.check_circle_outline), findsNothing);
      await tester.drag(find.byType(ListView), const Offset(0, -7000));
      await tester.pumpAndSettle();
      final last = find.ancestor(
        of: find.text('Level 44'),
        matching: find.byType(ListTile),
      );
      expect(tester.widget<ListTile>(last).onTap, isNotNull);
      await signIn(session, 2);
      await tester.pumpAndSettle();
      await tester.drag(find.byType(ListView), const Offset(0, -7000));
      await tester.pumpAndSettle();
      expect(tester.widget<ListTile>(last).onTap, isNull);
      expect(find.byIcon(Icons.check_circle_outline), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      session.dispose();
    },
  );

  testWidgets('direct locked entry displays denial and cannot play or answer', (
    tester,
  ) async {
    await tester.pumpWidget(
      updates.host(
        IntervalTrainingScreen(
          levelNumber: 44,
          store: fixture.MemoryStore(),
          progress: IntervalProgress(),
          audio: fixture.TestAudio(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Locked'), findsOneWidget);
    expect(find.byType(OutlinedButton), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'changing accounts revokes a running admin training session without saving into the new user',
    (tester) async {
      final session = AuthSession();
      await signIn(session, 1);
      final store = IntervalProgressRepository(userId: 1);
      final progress = await store.load();
      final c = IntervalTrainingController(
        levelNumber: 44,
        audio: fixture.TestAudio(),
        store: store,
        progress: progress,
        access: const IntervalAccess(userId: 1),
      );
      await tester.pumpWidget(
        authenticatedHost(
          session,
          IntervalTrainingScreen(
            levelNumber: 44,
            store: store,
            progress: progress,
            controller: c,
            access: const IntervalAccess(userId: 1),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(OutlinedButton), findsNWidgets(12));
      final q = c.question;
      c.select(q.interval);
      await signIn(session, 2);
      await tester.pumpAndSettle();
      expect(c.accessRevoked, isTrue);
      expect(find.byType(OutlinedButton), findsNothing);
      await c.check();
      expect(c.wins, 0);
      expect(c.question, same(q));
      expect(
        (await IntervalProgressRepository(userId: 2).load()).completed,
        isEmpty,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      session.dispose();
    },
  );

  testWidgets('admin level 44 completes with final message and no level 45', (
    tester,
  ) async {
    final session = AuthSession();
    await signIn(session, 1);
    final store = fixture.MemoryStore();
    final c = IntervalTrainingController(
      levelNumber: 44,
      audio: fixture.TestAudio(),
      store: store,
      progress: IntervalProgress(),
      access: const IntervalAccess(userId: 1),
      feedbackDuration: const Duration(seconds: 1),
    );
    await tester.pumpWidget(
      authenticatedHost(
        session,
        IntervalTrainingScreen(
          levelNumber: 44,
          store: store,
          progress: c.progress,
          controller: c,
          access: const IntervalAccess(userId: 1),
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
        'Congratulations! You have successfully completed all 44 levels of Western Music Interval Recognition.',
      ),
      findsOneWidget,
    );
    expect(find.text('Back to Levels'), findsOneWidget);
    expect(c.level.number, 44);
    expect(store.progress.completed, {44});
    await tester.pumpWidget(const SizedBox());
    session.dispose();
  });
}
