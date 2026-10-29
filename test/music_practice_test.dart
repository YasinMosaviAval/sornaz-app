import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:sornaz/screens/MusicPractice/practice_player_page.dart';
import 'package:sornaz/screens/MusicPractice/practice_manage_page.dart';
import 'social_widget_test.dart' as fixture;
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sornaz/screens/MusicPractice/practice_repository.dart';
import 'package:sornaz/screens/Social/social_api.dart';

http.Response response(Map<String, dynamic> data) => http.Response(
  jsonEncode({
    'data': {'success': true, 'data': data},
  }),
  200,
  headers: {'content-type': 'application/json; charset=utf-8'},
);
PracticeJson exam({int stages = 3}) => {
  'id': 10,
  'version': 1,
  'stageCount': stages,
  'requiredWins': 2,
  'permitExpiresAt': 4102444800,
  'downloadPermit': 'fixture',
  'config': {
    'kind': 'interval',
    'quarterSteps': [14, 24],
    'direction': 'ascending',
    'variableRoot': false,
  },
};
PracticeJson answer(int sequence, {bool correct = true}) => {
  'sequence': sequence,
  'expected': 14,
  'selected': correct ? 14 : 24,
  'rootMidi': 60,
  'elapsedMs': 100,
  'answeredAt': '2026-10-29T10:00:00.000Z',
};

class WidgetPracticeRepository extends MusicPracticeRepository {
  WidgetPracticeRepository()
    : super(
        userId: null,
        token: () => null,
        client: MockClient(
          (_) async => throw StateError('Unexpected network call'),
        ),
      );
  final saved = <PracticeJson>[];
  bool closed = false;
  @override
  Future<PracticeJson> append({
    required String id,
    required PracticeJson exam,
    required int stage,
    required PracticeJson answer,
  }) async {
    saved.add({...answer, 'stage': stage});
    return {'streak': 1, 'passed': true};
  }

  @override
  Future<void> closeRun(String id) async {
    closed = true;
  }
}

class AuthorWidgetRepository extends WidgetPracticeRepository {
  final queries = <String>[];
  @override
  Future<PracticeJson> request(String path, [PracticeJson? payload]) async {
    queries.add(path);
    return {
      'users': [
        {'id': 3, 'username': 'student'},
      ],
      'viewerId': 2,
    };
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;
  setUpAll(() async {
    directory = await Directory.systemTemp.createTemp(
      'sornaz-music-practice-test-',
    );
    Hive.init(directory.path);
    await Hive.openBox<String>('music_practice_v1');
  });
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await Hive.box<String>('music_practice_v1').clear();
  });
  tearDownAll(() async {
    await Hive.close();
    final target = directory.absolute.path,
        root = Directory.systemTemp.absolute.path;
    if (!target.startsWith('$root${Platform.pathSeparator}') ||
        !directory.uri.pathSegments
            .where((s) => s.isNotEmpty)
            .last
            .startsWith('sornaz-music-practice-test-')) {
      throw StateError('Unsafe fixture cleanup');
    }
    await directory.delete(recursive: true);
  });
  testWidgets(
    'author selects recipients by username and can remove a selected recipient',
    (tester) async {
      final repo = AuthorWidgetRepository();
      await tester.pumpWidget(
        fixture.host(
          MusicPracticeEditPage(
            repository: repo,
            kind: 'exams',
            catalog: {
              'nodes': [
                {'id': 1, 'depth': 1, 'titleFa': 'ریتم', 'titleEn': 'Rhythm'},
              ],
              'exams': [],
              'capabilities': {'publish': true},
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      final search = find.byWidgetPredicate(
        (w) =>
            w is TextField &&
            w.decoration?.labelText == 'جست‌وجوی نام کاربری مخاطبان',
      );
      await tester.ensureVisible(search);
      await tester.pumpAndSettle();
      await Scrollable.ensureVisible(tester.element(search), alignment: .3);
      await tester.pumpAndSettle();
      await tester.tap(search);
      await tester.enterText(search, 'st');
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();
      expect(repo.queries, ['people?q=st']);
      expect(
        find.text('@student'),
        findsOneWidget,
        reason: tester
            .widgetList<Text>(find.byType(Text))
            .map((w) => w.data)
            .join(' | '),
      );
      await tester.tap(find.text('@student').last);
      await tester.pumpAndSettle();
      expect(find.widgetWithText(InputChip, '@student'), findsOneWidget);
      await tester.tap(
        find.descendant(
          of: find.byType(InputChip),
          matching: find.byTooltip(
            MaterialLocalizations.of(
              tester.element(find.byType(InputChip)),
            ).deleteButtonTooltip,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(InputChip), findsNothing);
      await tester.pumpWidget(const SizedBox());
      repo.dispose();
    },
  );
  testWidgets(
    'choice practice saves an answer and returns through native navigation',
    (tester) async {
      final repo = WidgetPracticeRepository();
      final definition = <String, dynamic>{
        ...exam(stages: 1),
        'titleFa': 'آزمون نمونه',
        'titleEn': 'Example test',
        'requiredWins': 1,
        'config': {
          'kind': 'choice',
          'questions': [
            {
              'promptFa': 'پرسش',
              'promptEn': 'Question',
              'choices': ['پاسخ درست', 'پاسخ نادرست'],
              'correct': 0,
            },
          ],
        },
      };
      await tester.pumpWidget(
        fixture.host(
          Builder(
            builder: (context) => Scaffold(
              body: FilledButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => MusicPracticePlayerPage(
                      repository: repo,
                      exam: definition,
                      stage: 1,
                    ),
                  ),
                ),
                child: const Text('Open test'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open test'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('پاسخ درست'));
      await tester.pumpAndSettle();
      expect(
        find.text('مرحله کامل شد.'),
        findsOneWidget,
        reason: tester
            .widgetList<Text>(find.byType(Text))
            .map((w) => w.data)
            .join(' | '),
      );
      await tester.tap(find.text('بازگشت به آزمون‌ها'));
      await tester.pumpAndSettle();
      expect(find.text('Open test'), findsOneWidget);
      expect(tester.takeException(), isNull);
      expect(repo.saved.single['selected'], 0);
      expect(repo.saved.single['stage'], 1);
      expect(repo.closed, isTrue);
      repo.dispose();
    },
  );
  test(
    'catalog is server driven, cached for the same account, and never falls back across accounts',
    () async {
      final first = MusicPracticeRepository(
        userId: 3,
        token: () => 'token-3',
        client: MockClient((request) async {
          expect(request.headers['Authorization'], 'Bearer token-3');
          return response({
            'viewerId': 3,
            'nodes': [
              {'id': 1, 'parentId': null, 'titleFa': 'تمرین سولفژ'},
            ],
            'exams': [],
          });
        }),
      );
      expect((await first.catalog())['nodes'], hasLength(1));
      first.dispose();
      final offline = MusicPracticeRepository(
        userId: 3,
        token: () => 'token-3',
        client: MockClient((_) async => throw const SocketException('offline')),
      );
      expect((await offline.catalog())['nodes'], hasLength(1));
      expect(offline.offline, isTrue);
      offline.dispose();
      final other = MusicPracticeRepository(
        userId: 4,
        token: () => 'token-4',
        client: MockClient((_) async => throw const SocketException('offline')),
      );
      await expectLater(other.catalog(), throwsA(isA<SocketException>()));
      other.dispose();
    },
  );
  test(
    'unauthorized response cannot silently reuse a private cached catalog',
    () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'music.practice.catalog.user.3',
        jsonEncode({
          'nodes': [
            {'titleFa': 'private'},
          ],
        }),
      );
      final repo = MusicPracticeRepository(
        userId: 3,
        token: () => 'bad',
        client: MockClient(
          (_) async => http.Response(jsonEncode({'message': 'Denied'}), 403),
        ),
      );
      await expectLater(repo.catalog(), throwsA(isA<SocialException>()));
      repo.dispose();
    },
  );
  test(
    'each answer is durable and stages award at most five stars for a configurable stage count',
    () async {
      final repo = MusicPracticeRepository(
        userId: null,
        token: () => null,
        client: MockClient((_) async => throw const SocketException('offline')),
      );
      for (var stage = 1; stage <= 3; stage++) {
        final id = '$stage'.padLeft(32, '0');
        await repo.append(
          id: id,
          exam: exam(),
          stage: stage,
          answer: answer(1),
        );
        final run = await repo.append(
          id: id,
          exam: exam(),
          stage: stage,
          answer: answer(2),
        );
        expect(run['passed'], isTrue);
      }
      final p = await repo.progress();
      expect(p.single['completedStages'], [1, 2, 3]);
      expect(p.single['stars'], 5);
      expect((await repo.runs()).every((r) => r['answerCount'] == 2), isTrue);
      await expectLater(
        repo.append(
          id: '1'.padLeft(32, '0'),
          exam: exam(),
          stage: 1,
          answer: answer(3),
        ),
        throwsStateError,
      );
      repo.dispose();
    },
  );
  test(
    'lost acknowledgements retry immutable answers and another account cannot upload them',
    () async {
      var fail = true, uploads = 0;
      final repo = MusicPracticeRepository(
        userId: 3,
        token: () => 'token',
        client: MockClient((request) async {
          uploads++;
          final payload = jsonDecode(request.bodyFields['payload']!) as Map;
          expect(payload['downloadPermit'], 'fixture');
          expect(payload['answers'], hasLength(2));
          if (fail) throw const SocketException('lost response');
          return response({'acceptedThrough': 2, 'status': 'passed'});
        }),
      );
      await repo.append(
        id: 'a' * 32,
        exam: exam(),
        stage: 1,
        answer: answer(1),
      );
      await repo.append(
        id: 'a' * 32,
        exam: exam(),
        stage: 1,
        answer: answer(2),
      );
      await expectLater(repo.upload(), throwsA(isA<SocketException>()));
      expect((await repo.runs()).single['ack'], 0);
      fail = false;
      await repo.upload();
      await repo.upload();
      expect(uploads, 2);
      expect((await repo.runs()).single['ack'], 2);
      final other = MusicPracticeRepository(
        userId: 4,
        token: () => 'other',
        client: MockClient(
          (_) async => throw StateError('Must not send another user history'),
        ),
      );
      expect(await other.runs(), isEmpty);
      await other.upload();
      other.dispose();
      repo.dispose();
    },
  );
  test(
    'background acknowledgement cannot overwrite a newly saved answer',
    () async {
      final sent = Completer<void>(), release = Completer<void>();
      var calls = 0;
      final repo = MusicPracticeRepository(
        userId: 3,
        token: () => 'token',
        client: MockClient((request) async {
          final payload = jsonDecode(request.bodyFields['payload']!) as Map;
          calls++;
          if (calls == 1) {
            sent.complete();
            await release.future;
          }
          final answers = payload['answers'] as List;
          return response({
            'acceptedThrough': answers.last['sequence'],
            'status': payload['closed'] == true ? 'passed' : 'in_progress',
          });
        }),
      );
      await repo.append(
        id: 'b' * 32,
        exam: exam(),
        stage: 1,
        answer: answer(1),
      );
      final uploading = repo.upload();
      await sent.future;
      await repo.append(
        id: 'b' * 32,
        exam: exam(),
        stage: 1,
        answer: answer(2),
      );
      release.complete();
      await uploading;
      final run = (await repo.runs()).single;
      expect(run['answerCount'], 2);
      expect(run['ack'], 2);
      expect(run['passed'], isTrue);
      repo.dispose();
    },
  );
  test(
    'interrupted metadata write is recovered from the independently persisted answer',
    () async {
      final repo = MusicPracticeRepository(userId: null, token: () => null);
      await repo.append(
        id: 'c' * 32,
        exam: exam(),
        stage: 1,
        answer: answer(1),
      );
      final box = Hive.box<String>('music_practice_v1');
      await box.put('user.0.run.${'c' * 32}.answer.2', jsonEncode(answer(2)));
      final run = (await repo.runs()).single;
      expect(run['answerCount'], 2);
      expect(run['passed'], isTrue);
      repo.dispose();
    },
  );
  test(
    'account changes while a response is in flight prevent acknowledgement',
    () async {
      String? credential = 'first';
      final done = Completer<void>(), sent = Completer<void>();
      final repo = MusicPracticeRepository(
        userId: 3,
        token: () => credential,
        client: MockClient((_) async {
          sent.complete();
          await done.future;
          return response({'acceptedThrough': 1});
        }),
      );
      await repo.append(
        id: 'd' * 32,
        exam: exam(),
        stage: 1,
        answer: answer(1),
      );
      final pending = repo.upload();
      await sent.future;
      credential = 'second';
      done.complete();
      await expectLater(pending, throwsA(isA<SocialException>()));
      expect((await repo.runs()).single['ack'], 0);
      repo.dispose();
    },
  );
}
