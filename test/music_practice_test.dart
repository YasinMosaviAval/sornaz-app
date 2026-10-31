import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:sornaz/screens/MusicPractice/practice_player_page.dart';
import 'package:sornaz/screens/MusicPractice/practice_journey_page.dart';
import 'package:sornaz/screens/MusicPractice/practice_settings_page.dart';
import 'package:sornaz/screens/Authentication/providers/auth_session.dart';
import 'package:sornaz/screens/Authentication/models/auth_user.dart';
import 'package:provider/provider.dart';
import 'package:sornaz/screens/IntervalRecognition/play_button.dart';
import 'package:sornaz/screens/IntervalRecognition/stars.dart';
import 'package:sornaz/screens/MusicPractice/practice_manage_page.dart';
import 'package:sornaz/screens/MusicPractice/practice_page.dart';
import 'package:sornaz/screens/MusicPractice/practice_sync.dart';
import 'package:sornaz/screens/IntervalRecognition/progress.dart';
import 'package:sornaz/screens/IntervalRecognition/models.dart';
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
  Future<List<PracticeJson>> progress({bool refresh = true}) async => [];
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

class SyncPracticeRepository extends WidgetPracticeRepository {
  int refreshes = 0;
  Completer<void>? gate;
  @override
  Future<PracticeJson> catalog({
    bool manage = false,
    bool allowCached = true,
  }) async {
    refreshes++;
    await gate?.future;
    return {'nodes': [], 'exams': []};
  }

  @override
  Future<List<PracticeJson>> progress({bool refresh = true}) async => [];
}

class TreePracticeRepository extends WidgetPracticeRepository {
  int examNode = 3;
  final writes = <PracticeJson>[];
  final tree = <PracticeJson>[
    for (final row in [
      (1, null, 1, 'تمرین سولفژ'),
      (2, 1, 2, 'تشخیص فاصله'),
      (3, 2, 3, 'موسیقی ایرانی'),
      (4, 2, 3, 'موسیقی جهانی'),
    ])
      {
        'id': row.$1,
        'parentId': row.$2,
        'depth': row.$3,
        'titleFa': row.$4,
        'titleEn': 'Section ${row.$1}',
        'published': true,
        'canManage': true,
        'version': 1,
        'position': row.$1,
        'slug': 'section-${row.$1}',
      },
  ];
  @override
  Future<PracticeJson> catalog({
    bool manage = false,
    bool allowCached = true,
  }) async => {
    'sectionSubscriptions': true,
    'levelDeletion': true,
    'nodeDeletion': true,
    'nodes': tree,
    'exams': [
      {
        ...exam(),
        'id': 10,
        'nodeId': examNode,
        'titleFa': 'سطح اول',
        'titleEn': 'First level',
        'published': true,
        'audience': 'public',
      },
    ],
    'capabilities': {
      'create': true,
      'edit': true,
      'publish': true,
      'delete': true,
      'approvePlans': false,
    },
  };
  @override
  Future<PracticeJson> request(String path, [PracticeJson? payload]) async {
    if (path == 'plans') return {'plans': [], 'revenue': []};
    writes.add({'path': path, ...?payload});
    if (path == 'publish') {
      tree.firstWhere((n) => n['id'] == payload!['id'])['published'] =
          payload!['published'];
    }
    return {'id': 99};
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
      await tester.scrollUntilVisible(
        search,
        250,
        scrollable: find
            .descendant(
              of: find.byType(ListView),
              matching: find.byType(Scrollable),
            )
            .first,
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
    'online interval practice uses the legacy play button, stars and vertical answers',
    (tester) async {
      final repo = WidgetPracticeRepository();
      await tester.pumpWidget(
        fixture.host(
          MusicPracticePlayerPage(
            repository: repo,
            exam: {...exam(), 'titleFa': 'سطح ۱', 'titleEn': 'Level 1'},
            stage: 1,
            stars: 3,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(IntervalPlayButton), findsOneWidget);
      expect(tester.widget<IntervalStars>(find.byType(IntervalStars)).count, 3);
      final options = find.byType(OutlinedButton);
      expect(options, findsNWidgets(2));
      final first = tester.getRect(options.first),
          second = tester.getRect(options.last);
      expect(first.left, second.left);
      expect(first.width, second.width);
      expect(first.height, greaterThanOrEqualTo(56));
      expect(second.top, greaterThanOrEqualTo(first.bottom + 8));
      expect(find.byType(FilledButton), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      repo.dispose();
    },
  );
  testWidgets(
    'group advances levels without interim completion and finishes one complete round',
    (tester) async {
      final repo = WidgetPracticeRepository();
      PracticeJson choice(int id) => {
        ...exam(stages: 5),
        'id': id,
        'position': id,
        'access': true,
        'titleFa': 'سطح $id',
        'titleEn': 'Level $id',
        'requiredWins': 1,
        'config': {
          'kind': 'choice',
          'questions': [
            {
              'promptFa': 'پرسش',
              'promptEn': 'Question',
              'choices': ['درست', 'نادرست'],
              'correct': 0,
            },
          ],
        },
      };
      await tester.pumpWidget(
        fixture.host(
          MusicPracticeJourneyPage(
            repository: repo,
            exams: [choice(10), choice(11)],
            progress: const [],
            title: 'تشخیص فاصله موسیقی ایرانی',
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.settings_outlined), findsNothing);
      for (final id in [10, 11]) {
        expect(
          tester
              .widget<MusicPracticePlayerPage>(
                find.byType(MusicPracticePlayerPage),
              )
              .exam['id'],
          id,
        );
        expect(
          tester
              .widget<MusicPracticePlayerPage>(
                find.byType(MusicPracticePlayerPage),
              )
              .stage,
          1,
        );
        await tester.tap(find.text('درست'));
        await tester.pumpAndSettle();
        await tester.tap(find.byType(FilledButton));
        await tester.pumpAndSettle();
        if (id == 10) {
          expect(find.text('بازگشت به آزمون‌ها'), findsNothing);
        }
      }
      expect(
        find.text('آزمون تشخیص فاصله موسیقی ایرانی کامل شد'),
        findsOneWidget,
      );
      expect(tester.widget<IntervalStars>(find.byType(IntervalStars)).count, 1);
      expect(repo.saved, hasLength(2));
      await tester.pumpWidget(const SizedBox.shrink());
      repo.dispose();
    },
  );
  for (final count in [5, 6, 7]) {
    testWidgets('answer layout preserves every option for $count choices', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repo = WidgetPracticeRepository();
      await tester.pumpWidget(
        fixture.host(
          MusicPracticePlayerPage(
            repository: repo,
            exam: {
              ...exam(),
              'titleFa': 'Test',
              'titleEn': 'Test',
              'config': {
                'kind': 'choice',
                'questions': [
                  {
                    'promptFa': 'Question',
                    'promptEn': 'Question',
                    'choices': List.generate(count, (i) => 'Option $i'),
                    'correct': 0,
                  },
                ],
              },
            },
            stage: 1,
          ),
        ),
      );
      await tester.pumpAndSettle();
      final options = find.byType(OutlinedButton);
      expect(options, findsNWidgets(count));
      final first = tester.getRect(options.at(0)),
          second = tester.getRect(options.at(1));
      if (count > 5) {
        expect(first.top, second.top);
        expect(first.width, second.width);
        expect(
          tester.getRect(options.at(2)).top,
          greaterThanOrEqualTo(first.bottom + 8),
        );
      } else {
        expect(first.left, second.left);
        expect(second.top, greaterThanOrEqualTo(first.bottom + 8));
      }
      await tester.tap(options.first);
      await tester.pump();
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNotNull,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      repo.dispose();
    });
  }
  test('level list is opt-in and only the founder can enable it', () async {
    expect(await MusicPracticeSettingsPage.listMode(1), false);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(MusicPracticeSettingsPage.listModeKey, true);
    expect(await MusicPracticeSettingsPage.listMode(1), true);
    expect(await MusicPracticeSettingsPage.listMode(3), false);
    expect(await MusicPracticeSettingsPage.listMode(null), false);
  });
  for (final actor in [1, 3]) {
    testWidgets('settings expose the mode switch only for founder: $actor', (
      tester,
    ) async {
      final auth = AuthSession()
        ..token = 'test'
        ..user = AuthUser(id: actor, username: 'user', fullName: 'User');
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: auth,
          child: fixture.host(const MusicPracticeSettingsPage()),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.byType(SwitchListTile),
        actor == 1 ? findsOneWidget : findsNothing,
      );
      if (actor == 1) {
        await tester.tap(find.byType(SwitchListTile));
        await tester.pumpAndSettle();
        expect(await MusicPracticeSettingsPage.listMode(1), true);
      }
      await tester.pumpWidget(const SizedBox.shrink());
      auth.dispose();
    });
  }
  testWidgets('active play icon is white in both theme modes', (tester) async {
    for (final dark in [false, true]) {
      await tester.pumpWidget(
        fixture.host(
          const IntervalPlayButton(
            playing: true,
            label: 'Play',
            onPressed: null,
          ),
          dark: dark,
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<IconButton>(find.byType(IconButton))
            .style!
            .foregroundColor!
            .resolve({}),
        Colors.white,
      );
      expect(
        tester
            .widget<IconButton>(find.byType(IconButton))
            .style!
            .foregroundColor!
            .resolve({WidgetState.disabled}),
        Colors.white,
      );
      expect(
        tester.widget<Icon>(find.byIcon(Icons.play_arrow)).color,
        Colors.white,
      );
    }
  });
  testWidgets(
    'level deletion requires confirmation and sends the current version',
    (tester) async {
      final repo = TreePracticeRepository();
      await tester.pumpWidget(
        fixture.host(
          MusicPracticePage(
            repository: repo,
            nodeId: 3,
            nodeTitle: 'Levels',
            showLevels: true,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester.widget<Icon>(find.byIcon(Icons.delete_outline).last).color,
        Colors.red,
      );
      await tester.ensureVisible(find.byIcon(Icons.delete_outline).last);
      await tester.tap(find.byIcon(Icons.delete_outline).last);
      await tester.pumpAndSettle();
      expect(repo.writes, isEmpty);
      final confirmation = find.byType(AlertDialog);
      await tester.tap(
        find
            .descendant(of: confirmation, matching: find.byType(TextButton))
            .last,
      );
      await tester.pumpAndSettle();
      expect(repo.writes.last, containsPair('path', 'exams/delete'));
      expect(repo.writes.last, containsPair('id', 10));
      expect(repo.writes.last, containsPair('version', 1));
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  for (final section in [1, 2, 3]) {
    testWidgets(
      'section $section only shows its own practice card when tests are attached directly',
      (tester) async {
        final repo = TreePracticeRepository();
        await tester.pumpWidget(
          fixture.host(
            MusicPracticePage(
              repository: repo,
              nodeId: section,
              nodeTitle: 'Current section',
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          find.byIcon(Icons.play_circle_outline),
          section == 3 ? findsOneWidget : findsNothing,
        );
        expect(find.byIcon(Icons.chevron_right), findsNothing);
        if (section < 3) {
          await tester.pumpWidget(const SizedBox.shrink());
          final direct = TreePracticeRepository()..examNode = section;
          await tester.pumpWidget(
            fixture.host(
              MusicPracticePage(
                repository: direct,
                nodeId: section,
                nodeTitle: 'Current section',
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(find.byIcon(Icons.play_circle_outline), findsOneWidget);
          expect(
            tester
                .widget<Text>(
                  find.descendant(
                    of: find.ancestor(
                      of: find.byIcon(Icons.play_circle_outline),
                      matching: find.byType(ListTile),
                    ),
                    matching: find.text('Current section'),
                  ),
                )
                .style
                ?.fontSize,
            14,
          );
        }
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }
  testWidgets('management controls live in section cards and top bar', (
    tester,
  ) async {
    final repo = TreePracticeRepository();
    await tester.pumpWidget(
      fixture.host(
        MusicPracticePage(repository: repo, nodeId: 2, nodeTitle: 'Section'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(TabBar), findsNothing);
    expect(find.byIcon(Icons.edit_note), findsNothing);
    expect(
      find.byIcon(Icons.edit_outlined).evaluate().length,
      greaterThanOrEqualTo(2),
    );
    expect(
      find.byIcon(Icons.card_membership).evaluate().length,
      greaterThanOrEqualTo(2),
    );
    expect(
      find.byIcon(Icons.playlist_add).evaluate().length,
      greaterThanOrEqualTo(2),
    );
    await tester.tap(find.byIcon(Icons.playlist_add).first);
    await tester.pumpAndSettle();
    expect(
      tester
          .widgetList<DropdownButtonFormField<String>>(
            find.byType(DropdownButtonFormField<String>),
          )
          .first
          .initialValue,
      '3',
    );
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets(
    'VIP proposal duration uses standard periods and sends the chosen days',
    (tester) async {
      final repo = TreePracticeRepository(),
          data = await repo.catalog(manage: true);
      await tester.pumpWidget(
        fixture.host(
          MusicPracticeEditPage(
            repository: repo,
            catalog: data,
            kind: 'plans/propose',
            item: const {'title': 'اشتراک', 'days': 30, '_rootNodeId': 1},
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('ماهانه'));
      await tester.tap(find.text('ماهانه'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('سه ماهه').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('ذخیره'));
      await tester.pumpAndSettle();
      expect(repo.writes.last['days'], 90);
      expect(repo.writes.last['nodeId'], 1);
      expect(repo.writes.last['examId'], 0);
      await tester.pumpWidget(const SizedBox.shrink());
      repo.dispose();
    },
  );
  testWidgets(
    'scoped offer cannot be silently sent to a server without section support',
    (tester) async {
      final repo = TreePracticeRepository(),
          data = await repo.catalog(manage: true);
      data['sectionSubscriptions'] = false;
      await tester.pumpWidget(
        fixture.host(
          MusicPracticeEditPage(
            repository: repo,
            catalog: data,
            kind: 'plans/propose',
            item: const {'title': 'اشتراک', 'days': 30, '_rootNodeId': 1},
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('ذخیره'));
      await tester.pumpAndSettle();
      expect(repo.writes, isEmpty);
      await tester.pumpWidget(const SizedBox.shrink());
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
      final options = tester
          .widgetList<OutlinedButton>(find.byType(OutlinedButton))
          .toList();
      expect(options, hasLength(2));
      final first = tester.getRect(find.byType(OutlinedButton).first),
          second = tester.getRect(find.byType(OutlinedButton).last);
      expect(first.left, second.left);
      expect(first.width, second.width);
      expect(second.top, greaterThanOrEqualTo(first.bottom));
      await tester.tap(find.text('پاسخ درست'));
      await tester.pumpAndSettle();
      expect(repo.saved, isEmpty);
      await tester.tap(find.byType(FilledButton));
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
    'reconnection refreshes without opening the tests tab and coalesces overlapping notifications',
    () async {
      final connections = StreamController<bool>(),
          repo = SyncPracticeRepository();
      repo.gate = Completer<void>();
      final sync = MusicPracticeSync(repo, connections: connections.stream);
      connections.add(true);
      connections.add(true);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(repo.refreshes, 1);
      repo.gate!.complete();
      repo.gate = null;
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(repo.refreshes, 2);
      connections.add(true);
      connections.add(true);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(
        repo.refreshes,
        2,
        reason:
            'Repeated capabilities notifications must not trigger another catalog request',
      );
      connections.add(false);
      connections.add(true);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(repo.refreshes, 3);
      sync.dispose();
      connections.add(true);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(repo.refreshes, 3);
      await connections.close();
    },
  );
  test(
    'downloaded versions, old stars and answers survive refresh and reopening local storage',
    () async {
      var version = 1;
      final repo = MusicPracticeRepository(
        userId: 3,
        token: () => 'token-3',
        client: MockClient(
          (_) async => response({
            'viewerId': 3,
            'nodes': [
              {'id': 1, 'titleFa': 'سولفژ'},
            ],
            'exams': [
              {
                ...exam(stages: 5),
                'version': version,
                'access': true,
                'legacyKey': 'iranian:1',
                'audience': 'public',
                'ownerId': 1,
              },
            ],
          }),
        ),
      );
      await IntervalProgressRepository(
        userId: 3,
        music: IntervalMusic.iranian,
      ).save(IntervalProgress(music: IntervalMusic.iranian, stars: {1: 3}));
      await repo.catalog();
      expect((await repo.progress(refresh: false)).single['stars'], 3);
      final runId = repo.newRunId();
      await repo.append(
        id: runId,
        exam: exam(stages: 5),
        stage: 1,
        answer: answer(1),
      );
      version = 2;
      await repo.catalog();
      final b = await repo.box;
      expect(b.containsKey('user.3.definition.10.1'), isTrue);
      expect(b.containsKey('user.3.definition.10.2'), isTrue);
      repo.dispose();
      await b.close();
      final offline = MusicPracticeRepository(
        userId: 3,
        token: () => 'token-3',
        client: MockClient((_) async => throw const SocketException('offline')),
      );
      expect((await offline.catalog())['exams'].single['version'], 2);
      expect((await offline.runs()).single['answerCount'], 1);
      expect((await offline.box).containsKey('user.3.definition.10.1'), isTrue);
      // Legacy stars remain in their original store and do not complete a revised definition.
      expect(
        (await IntervalProgressRepository(
          userId: 3,
          music: IntervalMusic.iranian,
        ).load()).starsFor(1),
        3,
      );
      expect(await offline.progress(refresh: false), isEmpty);
      offline.dispose();
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
    'manual refresh reports the real server error and preserves a valid catalog',
    () async {
      var fail = false;
      final repo = MusicPracticeRepository(
        userId: 3,
        token: () => 'token',
        client: MockClient((_) async {
          if (fail) {
            return http.Response(
              jsonEncode({
                'data': {
                  'success': false,
                  'message': 'Offline signing key unavailable',
                },
              }),
              503,
            );
          }
          return response({
            'viewerId': 3,
            'nodes': [
              {'id': 1, 'parentId': null, 'titleFa': 'سولفژ'},
            ],
            'exams': [],
          });
        }),
      );
      await repo.catalog();
      fail = true;
      await expectLater(
        repo.catalog(allowCached: false),
        throwsA(isA<SocialException>().having((e) => e.status, 'status', 503)),
      );
      expect((await repo.cachedCatalog())!['nodes'], hasLength(1));
      expect((await repo.catalog())['nodes'], hasLength(1));
      expect(repo.offline, isTrue);
      expect(repo.lastSyncError, isA<SocialException>());
      repo.dispose();
    },
  );
  test(
    'malformed payload cannot replace durable catalog and an empty cache cannot hide errors',
    () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'music.practice.catalog.user.3',
        jsonEncode({'viewerId': 3, 'nodes': [], 'exams': []}),
      );
      final repo = MusicPracticeRepository(
        userId: 3,
        token: () => 'token',
        client: MockClient((_) async => response({'viewerId': 3, 'nodes': []})),
      );
      await expectLater(
        repo.catalog(),
        throwsA(isA<SocialException>().having((e) => e.status, 'status', 502)),
      );
      expect((await repo.cachedCatalog())!['exams'], isEmpty);
      repo.dispose();
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
