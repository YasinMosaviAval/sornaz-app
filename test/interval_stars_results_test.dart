import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sornaz/screens/IntervalRecognition/controller.dart';
import 'package:sornaz/screens/IntervalRecognition/levels_screen.dart';
import 'package:sornaz/screens/IntervalRecognition/models.dart';
import 'package:sornaz/screens/IntervalRecognition/progress.dart';
import 'package:sornaz/screens/IntervalRecognition/results.dart';
import 'package:sornaz/screens/IntervalRecognition/stars.dart';
import 'package:sornaz/screens/IntervalRecognition/sync.dart';
import 'interval_recognition_test.dart' as fixture;
import 'interval_recognition_updates_test.dart' as widgets;
import 'interval_test_storage.dart';

const runId = '0123456789abcdef0123456789abcdef';
Map<String, dynamic> answer(int sequence, {bool correct = true}) => {
  'sequence': sequence,
  'expectedQuarterSteps': 14,
  'selectedQuarterSteps': correct ? 14 : 24,
  'rootMidi': 60,
  'direction': 'ascending',
  'answeredAt': '2026-10-17T12:00:00.000Z',
  'elapsedMs': 2000,
};
Future<void> appendAnswers(
  IntervalResultJournal journal,
  int count, {
  bool correct = true,
}) async {
  for (var i = 1; i <= count; i++) {
    await journal.append(
      runId: runId,
      level: 1,
      answer: answer(i, correct: correct),
    );
  }
}

http.Response response(Map<String, dynamic> data) => http.Response(
  jsonEncode({
    'status': 200,
    'data': {'success': true, 'data': data},
  }),
  200,
);

class RetryJournal extends IntervalResultJournal {
  RetryJournal() : super(music: IntervalMusic.western, userId: 2);
  bool fail = true;
  @override
  Future<void> append({
    required String runId,
    required int level,
    required Map<String, dynamic> answer,
  }) async {
    if (fail) throw StateError('Fixture local write failure');
    await super.append(runId: runId, level: level, answer: answer);
  }
}

void main() {
  useIntervalTestStorage();
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test(
    'old completion stars are backed up explicitly and restored on another device',
    () async {
      final journal = IntervalResultJournal(
        userId: 2,
        music: IntervalMusic.western,
      );
      final repo = IntervalProgressRepository(userId: 2, journal: journal);
      await repo.save(IntervalProgress(completed: {3}));
      var imports = 0;
      final api = IntervalResultsApi(
        token: () => 'fixture-token',
        client: MockClient((request) async {
          expect(request.followRedirects, false);
          if (request.method == 'POST') {
            expect(
              request.url.path.endsWith('/interval-progress/import'),
              true,
            );
            imports++;
            expect(jsonDecode(request.bodyFields['payload']!)['levels'], [3]);
            return response({'imported': true});
          }
          return response({
            'awards': [],
            'legacyStars': [
              {'level': 3, 'stars': 1},
            ],
          });
        }),
      );
      final sync = IntervalResultsSync(api: api, journal: journal, store: repo);
      await sync.sync(force: true);
      await sync.sync(force: true);
      expect(imports, 1);
      expect((await repo.load()).starsFor(3), 1);
      sync.dispose();
      SharedPreferences.setMockInitialValues({});
      final restoredApi = IntervalResultsApi(
        token: () => 'fixture-token',
        client: MockClient(
          (_) async => response({
            'awards': [],
            'legacyStars': [
              {'level': 3, 'stars': 1},
            ],
          }),
        ),
      );
      final restored = IntervalResultsSync(
        api: restoredApi,
        journal: journal,
        store: repo,
      );
      await restored.sync(force: true);
      expect((await repo.load()).starsFor(3), 1);
      expect(await journal.runs(), isEmpty);
      restored.dispose();
    },
  );
  for (final status in [401, 404, 503]) {
    test(
      'server status $status keeps durable local stars and pending answers',
      () async {
        final journal = IntervalResultJournal(
          userId: 2,
          music: IntervalMusic.western,
        );
        await appendAnswers(journal, 10);
        final repo = IntervalProgressRepository(userId: 2, journal: journal);
        final api = IntervalResultsApi(
          token: () => 'fixture-token',
          client: MockClient((_) async => http.Response('{}', status)),
        );
        final sync = IntervalResultsSync(
          api: api,
          journal: journal,
          store: repo,
        );
        await sync.sync(force: true);
        expect(sync.hasError, true);
        expect((await repo.load()).starsFor(1), 1);
        expect((await journal.runs()).single['syncedSequence'], 0);
        sync.dispose();
      },
    );
  }

  test(
    'one ten-win result gives one star, capped at five without locking the next level',
    () {
      var progress = IntervalProgress();
      for (var i = 1; i <= 7; i++) {
        final id = i.toRadixString(16).padLeft(32, '0');
        progress = progress.complete(1, runId: id);
        expect(progress.starsFor(1), i.clamp(0, 5));
        expect(progress.isUnlocked(2), true);
      }
      expect(progress.awards.length, 7);
      expect(
        progress.complete(1, runId: '7'.padLeft(32, '0')).awards.length,
        7,
      );
    },
  );
  test(
    'v2 completion becomes one star and concurrent scoped saves preserve both wins',
    () async {
      final repo = IntervalProgressRepository(userId: 2);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        repo.legacyScopedKey,
        jsonEncode({
          'schema': 2,
          'completed': [1],
          'unlocked': [1, 2],
        }),
      );
      final migrated = await repo.load();
      expect(migrated.starsFor(1), 1);
      expect(jsonDecode(prefs.getString(repo.legacyScopedKey)!)['schema'], 2);
      await Future.wait([
        repo.save(migrated.complete(1, runId: runId)),
        IntervalProgressRepository(
          userId: 2,
        ).save(migrated.complete(1, runId: 'a'.padLeft(32, '0'))),
      ]);
      expect((await repo.load()).starsFor(1), 3);
      expect(migrated.complete(7, runId: runId).isUnlocked(8), true);
      expect(jsonDecode(prefs.getString(repo.scopedKey)!)['schema'], 3);
      expect(
        (await IntervalProgressRepository(userId: 3).load()).starsFor(1),
        0,
      );
      expect(
        (await IntervalProgressRepository(
          userId: 2,
          music: IntervalMusic.iranian,
        ).load()).starsFor(1),
        0,
      );
    },
  );
  test(
    'durable answers repair an interrupted metadata write and recover stars after reopening',
    () async {
      final journal = IntervalResultJournal(
        userId: 2,
        music: IntervalMusic.western,
      );
      await appendAnswers(journal, 9);
      final box = Hive.box<String>('solfege_interval_results_v1');
      await box.put(
        '${journal.prefix}$runId.answer.10',
        jsonEncode(answer(10)),
      );
      await box.flush();
      await box.close();
      await Hive.openBox<String>('solfege_interval_results_v1');
      final repo = IntervalProgressRepository(userId: 2, journal: journal);
      expect((await repo.load()).starsFor(1), 1);
      expect((await repo.load()).starsFor(1), 1);
      final run = (await journal.runs()).single;
      expect(run['passed'], true);
      expect((run['answers'] as List).length, 10);
      expect(
        await IntervalResultJournal(
          userId: 3,
          music: IntervalMusic.western,
        ).runs(),
        isEmpty,
      );
      expect(
        await IntervalResultJournal(music: IntervalMusic.western).runs(),
        isEmpty,
      );
      expect(
        await IntervalResultJournal(
          userId: 2,
          music: IntervalMusic.iranian,
        ).runs(),
        isEmpty,
      );
    },
  );
  test(
    'wrong answers remain in history and reset the ten-answer streak',
    () async {
      final journal = IntervalResultJournal(
        userId: 2,
        music: IntervalMusic.western,
      );
      final repo = IntervalProgressRepository(userId: 2, journal: journal);
      final controller = IntervalTrainingController(
        levelNumber: 1,
        audio: fixture.TestAudio(),
        store: repo,
        progress: await repo.load(),
        feedbackDuration: Duration.zero,
      );
      for (var i = 0; i < 8; i++) {
        await fixture.answer(controller);
      }
      await fixture.answer(controller, right: false);
      expect(controller.wins, 0);
      expect(controller.progress.starsFor(1), 0);
      for (var i = 0; i < 10; i++) {
        await fixture.answer(controller);
      }
      expect(controller.progress.starsFor(1), 1);
      expect(controller.level.number, 2);
      controller.dispose();
      final run = (await journal.runs()).single;
      expect((run['answers'] as List).length, 19);
      expect((await repo.load()).starsFor(1), 1);
    },
  );
  test(
    'failed local answer persistence retries once and never invents a win',
    () async {
      final journal = RetryJournal();
      final repo = IntervalProgressRepository(userId: 2, journal: journal);
      final controller = IntervalTrainingController(
        levelNumber: 1,
        audio: fixture.TestAudio(),
        store: repo,
        progress: await repo.load(),
        feedbackDuration: Duration.zero,
      );
      controller.select(controller.question.interval);
      await controller.check();
      expect(controller.wins, 0);
      expect(controller.errorKey, 'interval.resultSaveError');
      journal.fail = false;
      await controller.retrySave();
      await Future<void>.delayed(const Duration(milliseconds: 1));
      expect(controller.wins, 1);
      expect(((await journal.runs()).single['answers'] as List).length, 1);
      controller.dispose();
      await journal.runs();
    },
  );
  test(
    'offline results retry idempotently and stay locally readable after upload',
    () async {
      final journal = IntervalResultJournal(
        userId: 2,
        music: IntervalMusic.western,
      );
      await appendAnswers(journal, 10);
      final repo = IntervalProgressRepository(userId: 2, journal: journal);
      var offline = true, posts = 0;
      final api = IntervalResultsApi(
        token: () => 'fixture-token',
        client: MockClient((request) async {
          if (offline) throw const SocketException('Fixture offline');
          if (request.method == 'POST') {
            posts++;
            final body = jsonDecode(request.bodyFields['payload']!) as Map;
            expect(body.containsKey('userId'), false);
            expect(request.headers['Authorization'], 'Bearer fixture-token');
            return response({
              'acceptedThrough': (body['answers'] as List).last['sequence'],
            });
          }
          return response({
            'awards': [
              {'runId': runId, 'level': 1},
            ],
          });
        }),
      );
      final sync = IntervalResultsSync(api: api, journal: journal, store: repo);
      await sync.sync(force: true);
      expect(sync.hasError, true);
      expect((await journal.runs()).single['syncedSequence'], 0);
      expect((await repo.load()).starsFor(1), 1);
      offline = false;
      await sync.sync(force: true);
      await sync.sync(force: true);
      expect(sync.hasError, false);
      expect(posts, 1);
      expect((await journal.runs()).single['syncedSequence'], 10);
      expect(((await journal.runs()).single['answers'] as List).length, 10);
      expect((await repo.load()).starsFor(1), 1);
      sync.dispose();
    },
  );
  test(
    'an answer appended during upload survives the older acknowledgement',
    () async {
      final journal = IntervalResultJournal(
        userId: 2,
        music: IntervalMusic.western,
      );
      await appendAnswers(journal, 3, correct: false);
      final entered = Completer<void>(), release = Completer<void>();
      var posts = 0;
      final api = IntervalResultsApi(
        token: () => 'fixture-token',
        client: MockClient((request) async {
          if (request.method == 'GET') return response({'awards': []});
          final body = jsonDecode(request.bodyFields['payload']!) as Map;
          if (++posts == 1) {
            entered.complete();
            await release.future;
          }
          return response({
            'acceptedThrough': (body['answers'] as List).last['sequence'],
          });
        }),
      );
      final sync = IntervalResultsSync(
        api: api,
        journal: journal,
        store: IntervalProgressRepository(userId: 2, journal: journal),
      );
      final pending = sync.sync(force: true);
      await entered.future;
      await journal.append(
        runId: runId,
        level: 1,
        answer: answer(4, correct: false),
      );
      release.complete();
      await pending;
      var run = (await journal.runs()).single;
      expect((run['answers'] as List).length, 4);
      expect(run['syncedSequence'], 3);
      final queued = (await journal.runs(pendingOnly: true)).single;
      expect(queued['answerOffset'], 3);
      expect((queued['answers'] as List).length, 1);
      await sync.sync(force: true);
      expect((await journal.runs()).single['syncedSequence'], 4);
      sync.dispose();
    },
  );
  test(
    'account change during response leaves the old account queue unacknowledged',
    () async {
      final journal = IntervalResultJournal(
        userId: 2,
        music: IntervalMusic.western,
      );
      await appendAnswers(journal, 1);
      final entered = Completer<void>(), release = Completer<void>();
      var ownerIsCurrent = true, requests = 0;
      final api = IntervalResultsApi(
        token: () => ownerIsCurrent ? 'fixture-token' : null,
        client: MockClient((request) async {
          requests++;
          entered.complete();
          await release.future;
          return response({'acceptedThrough': 1});
        }),
      );
      final sync = IntervalResultsSync(
        api: api,
        journal: journal,
        store: IntervalProgressRepository(userId: 2, journal: journal),
      );
      final pending = sync.sync(force: true);
      await entered.future;
      ownerIsCurrent = false;
      release.complete();
      await pending;
      expect(sync.hasError, true);
      expect((await journal.runs()).single['syncedSequence'], 0);
      await sync.sync(force: true);
      expect(requests, 1);
      sync.dispose();
    },
  );
  testWidgets('level rows show five stars, two yellow and no completion tick', (
    tester,
  ) async {
    final store = fixture.MemoryStore()
      ..progress = IntervalProgress().complete(1).complete(1);
    await tester.pumpWidget(widgets.host(IntervalLevelsScreen(store: store)));
    await tester.pumpAndSettle();
    final stars = find.descendant(
      of: find.byType(IntervalStars).first,
      matching: find.byIcon(Icons.star),
    );
    expect(stars, findsNWidgets(5));
    expect(
      tester
          .widgetList<Icon>(stars)
          .where((icon) => icon.color == Colors.amber)
          .length,
      2,
    );
    expect(find.byIcon(Icons.check_circle_outline), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });
}
