import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sornaz/screens/MusicPractice/practice_icons.dart';
import 'package:sornaz/screens/MusicPractice/practice_manage_page.dart';
import 'package:sornaz/screens/MusicPractice/practice_form_field.dart';
import 'package:sornaz/screens/MusicPractice/practice_page.dart';
import 'package:sornaz/screens/MusicPractice/practice_repository.dart';
import 'package:sornaz/screens/MusicPractice/practice_settings_page.dart';
import 'package:sornaz/components/app_hierarchy_row.dart';
import 'package:sornaz/screens/Authentication/models/auth_user.dart';
import 'package:sornaz/screens/Authentication/providers/auth_session.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:sornaz/helpers/app_data.dart';
import 'package:sornaz/screens/Social/social_api.dart';
import 'music_practice_test.dart' show TreePracticeRepository;
import 'social_widget_test.dart' as fixture;

class OfflineCatalog extends TreePracticeRepository {
  bool failRefresh = false;
  bool forbidden = false;
  @override
  Future<PracticeJson> catalog({
    bool manage = false,
    bool allowCached = true,
  }) async {
    if (forbidden) throw const SocialException('Denied', 403);
    offline = true;
    lastSyncError = const SocketException('Network is unreachable');
    if (failRefresh) throw lastSyncError!;
    return await super.catalog(manage: manage, allowCached: allowCached);
  }
}

class PublicCatalog extends TreePracticeRepository {
  @override
  Future<PracticeJson> catalog({
    bool manage = false,
    bool allowCached = true,
  }) async => {
    ...await super.catalog(manage: manage, allowCached: allowCached),
    'capabilities': <String, dynamic>{},
  };
}

class ItemActionCatalog extends TreePracticeRepository {
  ItemActionCatalog({
    this.owned = true,
    this.allowed = true,
    this.deletionReady = true,
    this.levelDeletionReady = true,
  });
  final bool owned, allowed, deletionReady, levelDeletionReady;
  @override
  Future<PracticeJson> catalog({
    bool manage = false,
    bool allowCached = true,
  }) async {
    final data = await super.catalog(manage: manage, allowCached: allowCached);
    return {
      ...data,
      'nodes': [
        for (final node in tree) {...node, 'canManage': owned},
      ],
      'exams': <PracticeJson>[],
      'nodeDeletion': deletionReady,
      'levelDeletion': deletionReady && levelDeletionReady,
      'capabilities': {
        ...data['capabilities'] as Map,
        'edit': allowed,
        'delete': allowed,
      },
    };
  }
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  for (final dark in [false, true]) {
    testWidgets(
      'English tree fits a narrow viewport with theme brightness $dark',
      (tester) async {
        tester.view.physicalSize = const Size(320, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          ChangeNotifierProvider(
            create: (_) => AppData()..toggleDarkMode(dark),
            child: MaterialApp(
              locale: const Locale('en'),
              supportedLocales: const [Locale('en'), Locale('fa')],
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              theme: dark ? ThemeData.dark() : ThemeData.light(),
              home: MusicPracticePage(repository: PublicCatalog()),
            ),
          ),
        );
        await tester.pumpAndSettle();
        for (final label in ['Section 1', 'Section 2']) {
          await tester.ensureVisible(find.text(label));
          await tester.tap(find.text(label));
          await tester.pumpAndSettle();
        }
        expect(find.text('Section 3'), findsOneWidget);
        expect(find.byIcon(Icons.more_vert), findsNothing);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }

  test(
    'page-by-page defaults for everyone; only founder can opt into tree mode',
    () async {
      expect(await MusicPracticeSettingsPage.hierarchyMode(1), isFalse);
      expect(await MusicPracticeSettingsPage.hierarchyMode(3), isFalse);
      expect(await MusicPracticeSettingsPage.hierarchyMode(null), isFalse);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(MusicPracticeSettingsPage.hierarchyModeKey, true);
      expect(await MusicPracticeSettingsPage.hierarchyMode(1), isTrue);
      expect(await MusicPracticeSettingsPage.hierarchyMode(3), isFalse);
      expect(await MusicPracticeSettingsPage.hierarchyMode(null), isFalse);
    },
  );

  for (final actor in [1]) {
    testWidgets('tree expands all depths on one page for actor $actor', (
      tester,
    ) async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(MusicPracticeSettingsPage.hierarchyModeKey, true);
      final repo = TreePracticeRepository();
      final auth = AuthSession()
        ..token = 'test'
        ..user = AuthUser(id: actor, username: 'user', fullName: 'User');
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: auth,
          child: fixture.host(MusicPracticePage(repository: repo)),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('practice-tree-node-1')),
        findsOneWidget,
      );
      expect(find.text('تشخیص فاصله'), findsNothing);
      await tester.tap(find.text('تمرین سولفژ'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('تشخیص فاصله'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('موسیقی ایرانی'));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('practice-tree-exam-10')),
        findsOneWidget,
      );
      final child = find.byKey(const ValueKey('practice-tree-node-3'));
      final row = tester.widget<AppHierarchyRow>(child);
      expect(row.expanded, isTrue);
      expect(row.icon, Icons.folder);
      final childContext = tester.element(child);
      expect(
        AppHierarchyRow.background(childContext, 1),
        isNot(AppHierarchyRow.background(childContext, 2)),
      );
      expect(find.byTooltip('رجوع به صفحه قبل'), findsNothing);
      await tester.tap(find.text('تشخیص فاصله'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('practice-tree-exam-10')), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
      auth.dispose();
    });
  }

  testWidgets('founder can select the retained page-by-page view', (
    tester,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(MusicPracticeSettingsPage.hierarchyModeKey, false);
    final auth = AuthSession()
      ..token = 'test'
      ..user = AuthUser(id: 1, username: 'admin', fullName: 'Admin');
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: auth,
        child: fixture.host(
          MusicPracticePage(repository: TreePracticeRepository()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(AppHierarchyRow), findsNothing);
    expect(find.text('تمرین سولفژ'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    auth.dispose();
  });

  testWidgets(
    'offline catalog and failed refresh show no status or network errors',
    (tester) async {
      final repo = OfflineCatalog();
      await tester.pumpWidget(
        fixture.host(MusicPracticePage(repository: repo, nodeId: 2)),
      );
      await tester.pumpAndSettle();
      expect(find.text('موسیقی ایرانی'), findsOneWidget);
      expect(find.textContaining('آفلاین'), findsNothing);
      expect(find.textContaining('offline'), findsNothing);
      expect(find.textContaining('SocketException'), findsNothing);
      expect(find.byIcon(Icons.more_vert), findsNothing);
      repo.failRefresh = true;
      final refresh = tester.widget<RefreshIndicator>(
        find.byType(RefreshIndicator),
      );
      await refresh.onRefresh();
      await tester.pumpAndSettle();
      expect(find.text('موسیقی ایرانی'), findsOneWidget);
      expect(find.textContaining('Network is unreachable'), findsNothing);
      // Permission failures still clear the old catalog and remain visible.
      repo.forbidden = true;
      repo.offline = false;
      await refresh.onRefresh();
      await tester.pumpAndSettle();
      expect(find.text('موسیقی ایرانی'), findsNothing);
      expect(find.textContaining('Denied'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  for (final editing in [false, true]) {
    for (final kind in ['nodes', 'exams', 'plans/propose']) {
      testWidgets('title follows $kind, editing=$editing', (tester) async {
        final repo = TreePracticeRepository();
        final data = await repo.catalog(manage: true);
        final label = switch (kind) {
          'nodes' => editing ? 'ویرایش سطح' : 'افزودن سطح اول آزمون',
          'exams' => editing ? 'ویرایش آزمون' : 'افزودن آزمون',
          _ => editing ? 'ویرایش پیشنهاد اشتراک' : 'پیشنهاد اشتراک',
        };
        await tester.pumpWidget(
          fixture.host(
            MusicPracticeEditPage(
              repository: repo,
              catalog: data,
              kind: kind,
              item: {
                if (editing) 'id': 8,
                'parentId': 0,
                if (kind == 'exams') 'nodeId': 3,
                'days': 30,
              },
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text(label), findsOneWidget);
        await tester.pumpWidget(const SizedBox.shrink());
        repo.dispose();
      });
    }
  }

  for (final depth in [1, 2, 3]) {
    for (final language in ['fa', 'en']) {
      for (final dark in [false, true]) {
        testWidgets('level $depth form uses $language only, dark=$dark', (
          tester,
        ) async {
          tester.view.physicalSize = const Size(320, 900);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final repo = TreePracticeRepository();
          final data = await repo.catalog(manage: true);
          final en = language == 'en';
          await tester.pumpWidget(
            ChangeNotifierProvider(
              create: (_) => AppData()..toggleDarkMode(dark),
              child: MaterialApp(
                locale: Locale(language),
                supportedLocales: const [Locale('fa'), Locale('en')],
                localizationsDelegates: const [
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                theme: dark ? ThemeData.dark() : ThemeData.light(),
                home: MusicPracticeEditPage(
                  repository: repo,
                  catalog: data,
                  kind: 'nodes',
                  item: depth == 1 ? null : {'parentId': depth - 1},
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(
            find.text(
              en
                  ? 'Add ${['first', 'second', 'third'][depth - 1]} test level'
                  : 'افزودن سطح ${['اول', 'دوم', 'سوم'][depth - 1]} آزمون',
            ),
            findsOneWidget,
          );
          expect(
            find.text(en ? 'Persian title' : 'عنوان انگلیسی'),
            findsNothing,
          );
          final parentField = find.byWidgetPredicate(
            (w) =>
                w is TextField &&
                w.decoration?.labelText == (en ? 'Parent section' : 'بخش والد'),
          );
          expect(parentField, findsNothing);
          expect(find.text(en ? 'Published' : 'انتشار'), findsNothing);
          expect(
            find.text(en ? 'Short English address' : 'نشانی کوتاه انگلیسی'),
            findsNothing,
          );
          await tester.enterText(
            find.byType(TextFormField).first,
            en ? 'First test' : 'آزمون اول',
          );
          await tester.tap(find.byTooltip(en ? 'Save' : 'ذخیره'));
          await tester.pumpAndSettle();
          expect(repo.writes.single['parentId'], depth - 1);
          if (depth == 1) {
            expect(repo.writes.single['firstLevel'], true);
          } else {
            expect(repo.writes.single['level'], depth);
          }
          expect(
            repo.writes.single[en ? 'titleEn' : 'titleFa'],
            en ? 'First test' : 'آزمون اول',
          );
          for (final key in [en ? 'titleFa' : 'titleEn', 'published', 'slug']) {
            expect(repo.writes.single.containsKey(key), false);
          }
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox.shrink());
          repo.dispose();
        });
      }
    }
  }

  for (final depth in [1, 2, 3]) {
    testWidgets(
      'level $depth eye toggles public visibility without opening its menu',
      (tester) async {
        tester.view.physicalSize = const Size(320, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final repo = TreePracticeRepository();
        final auth = AuthSession()
          ..token = 'test'
          ..user = AuthUser(id: 1, username: 'admin', fullName: 'Admin');
        await tester.pumpWidget(
          ChangeNotifierProvider.value(
            value: auth,
            child: fixture.host(
              MusicPracticePage(
                repository: repo,
                nodeId: depth == 1 ? null : depth - 1,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final eye = find.byKey(ValueKey('practice-visibility-$depth'));
        expect(
          find.descendant(
            of: eye,
            matching: find.byIcon(Icons.visibility_outlined),
          ),
          findsOneWidget,
        );
        await tester.tap(eye);
        await tester.pumpAndSettle();
        expect(repo.writes.last, {
          'path': 'publish',
          'kind': 'node',
          'id': depth,
          'version': 1,
          'published': false,
        });
        expect(
          find.descendant(
            of: eye,
            matching: find.byIcon(Icons.visibility_off_outlined),
          ),
          findsOneWidget,
        );
        await tester.tap(eye);
        await tester.pumpAndSettle();
        expect(repo.writes.last['published'], true);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        auth.dispose();
      },
    );
  }

  testWidgets(
    'page-by-page top bar creates only the next level under its current parent',
    (tester) async {
      final repo = TreePracticeRepository()..examNode = 99;
      await tester.pumpWidget(
        fixture.host(MusicPracticePage(repository: repo)),
      );
      await tester.pumpAndSettle();
      expect(find.byType(AppHierarchyRow), findsNothing);
      for (final depth in [2, 3]) {
        await tester.tap(find.text(depth == 2 ? 'تمرین سولفژ' : 'تشخیص فاصله'));
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip('افزودن سطح'));
        await tester.pumpAndSettle();
        expect(
          find.text(
            depth == 2 ? 'افزودن سطح دوم آزمون' : 'افزودن سطح سوم آزمون',
          ),
          findsOneWidget,
        );
        final title = find.byWidgetPredicate(
          (w) => w is TextField && w.decoration?.labelText == 'عنوان فارسی',
        );
        await tester.enterText(title, 'سطح تازه');
        await tester.tap(find.byTooltip('ذخیره'));
        await tester.pumpAndSettle();
        expect(repo.writes.last['parentId'], depth - 1);
        expect(repo.writes.last['level'], depth);
      }
      await tester.tap(find.text('موسیقی ایرانی'));
      await tester.pumpAndSettle();
      expect(find.byTooltip('افزودن سطح'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      repo.dispose();
    },
  );

  for (final language in ['fa', 'en']) {
    for (final dark in [false, true]) {
      testWidgets(
        'new exam binds its section, uses one title and equal digit fields $language/$dark',
        (tester) async {
          tester.view.physicalSize = const Size(320, 900);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final repo = TreePracticeRepository(),
              data = await repo.catalog(manage: true),
              en = language == 'en';
          await tester.pumpWidget(
            ChangeNotifierProvider(
              create: (_) => AppData()..toggleDarkMode(dark),
              child: MaterialApp(
                locale: Locale(language),
                supportedLocales: const [Locale('fa'), Locale('en')],
                localizationsDelegates: const [
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                theme: dark ? ThemeData.dark() : ThemeData.light(),
                home: MusicPracticeEditPage(
                  repository: repo,
                  catalog: data,
                  kind: 'exams',
                  item: const {'nodeId': 3},
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(
            find.text(en ? 'Persian title' : 'عنوان انگلیسی'),
            findsNothing,
          );
          expect(find.text(en ? 'Parent section' : 'بخش والد'), findsNothing);
          expect(find.text(en ? 'Published' : 'انتشار'), findsNothing);
          final title = find.byWidgetPredicate(
            (w) =>
                w is PracticeFormField &&
                w.name == (en ? 'titleEn' : 'titleFa'),
          );
          await tester.enterText(
            find.descendant(of: title, matching: find.byType(TextField)),
            en ? 'New test' : 'آزمون تازه',
          );
          final rectangles = <Rect>[];
          for (final name in ['position', 'stageCount', 'requiredWins']) {
            final field = find.byWidgetPredicate(
              (w) => w is PracticeFormField && w.name == name,
            );
            final input = find.descendant(
              of: field,
              matching: find.byType(TextField),
            );
            expect(
              tester.widget<TextField>(input).decoration?.helperText,
              isNull,
            );
            expect(
              tester.widget<TextField>(input).keyboardType,
              TextInputType.number,
            );
            rectangles.add(tester.getRect(input));
            await tester.enterText(input, '۱x٢.۳-');
            await tester.pumpAndSettle();
            expect(tester.widget<TextField>(input).controller!.text, '123');
            await tester.enterText(input, '2');
            await tester.pumpAndSettle();
            expect(
              tester.widget<TextField>(input).decoration?.helperText,
              isNull,
            );
          }
          for (final rect in rectangles.skip(1)) {
            expect(rect.width, closeTo(rectangles.first.width, .01));
            expect(rect.height, closeTo(rectangles.first.height, .01));
            expect(rect.top, closeTo(rectangles.first.top, .01));
          }
          final search = find.byWidgetPredicate(
            (w) =>
                w is TextField &&
                w.decoration?.labelText ==
                    (en
                        ? 'Search audience usernames'
                        : 'جست‌وجوی نام کاربری مخاطبان'),
          );
          await tester.ensureVisible(search);
          await tester.pumpAndSettle();
          final textField = tester.widget<TextField>(search);
          expect(
            textField.decoration?.labelStyle?.fontSize,
            textField.style?.fontSize,
          );
          expect(
            textField.decoration?.hintStyle?.fontSize,
            textField.style?.fontSize,
          );
          FocusManager.instance.primaryFocus?.unfocus();
          await tester.pumpAndSettle();
          Finder decoration(String label) => find.byWidgetPredicate(
            (w) => w is InputDecorator && w.decoration.labelText == label,
          );
          final mode = decoration(en ? 'Level mode' : 'حالت سطح آزمون');
          await tester.ensureVisible(mode);
          await tester.pumpAndSettle();
          expect(
            tester.getTopLeft(mode).dy - tester.getBottomLeft(search).dy,
            closeTo(16, .1),
          );
          final type = decoration(en ? 'Practice type' : 'نوع تمرین');
          final distances = find.byWidgetPredicate(
            (w) => w is PracticeFormField && w.name == 'quarterSteps',
          );
          await tester.ensureVisible(distances);
          await tester.pumpAndSettle();
          expect(tester.getTopLeft(type).dy, tester.getTopLeft(distances).dy);
          expect(
            tester.getSize(type).width,
            closeTo(tester.getSize(distances).width, .1),
          );
          await tester.tap(find.byTooltip(en ? 'Save' : 'ذخیره'));
          await tester.pumpAndSettle();
          expect(repo.writes.single['nodeId'], 3);
          expect(
            repo.writes.single[en ? 'titleEn' : 'titleFa'],
            en ? 'New test' : 'آزمون تازه',
          );
          expect(
            repo.writes.single.containsKey(en ? 'titleFa' : 'titleEn'),
            false,
          );
          expect(repo.writes.single.containsKey('published'), false);
          for (final name in ['position', 'stageCount', 'requiredWins']) {
            expect(repo.writes.single[name], 2);
          }
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox.shrink());
          repo.dispose();
        },
      );
    }
  }
  for (final engine in ['choice', 'rhythm']) {
    testWidgets(
      '$engine question fields use two columns and preserve saved answers',
      (tester) async {
        tester.view.physicalSize = const Size(320, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final repo = TreePracticeRepository(),
            data = await repo.catalog(manage: true);
        data['notationQuestions'] = true;
        await tester.pumpWidget(
          fixture.host(
            MusicPracticeEditPage(
              repository: repo,
              catalog: data,
              kind: 'exams',
              item: {
                'id': 7,
                'version': 1,
                'nodeId': 3,
                'titleFa': 'پرسش',
                'titleEn': 'Question',
                'config': {
                  'kind': engine,
                  'questions': [
                    {
                      'promptFa': 'پرسش فارسی',
                      'promptEn': 'Question',
                      'choices': ['A', 'B'],
                      'correct': 0,
                      if (engine == 'rhythm') ...{
                        'beats': [1, .5],
                        'bpm': 80,
                      },
                    },
                  ],
                },
              },
            ),
          ),
        );
        await tester.pumpAndSettle();
        for (final names in [
          if (engine == 'rhythm') ...[
            ['promptFa', 'promptEn'],
            ['choices', 'correct'],
          ] else
            ['promptFa', 'choices'],
          if (engine == 'rhythm') ['beats', 'bpm'],
        ]) {
          final left = find.byWidgetPredicate(
            (w) => w is PracticeFormField && w.name == names[0],
          );
          final right = find.byWidgetPredicate(
            (w) => w is PracticeFormField && w.name == names[1],
          );
          await tester.scrollUntilVisible(
            left,
            200,
            scrollable: find.byType(Scrollable).first,
          );
          expect(
            tester.getTopLeft(left).dy,
            closeTo(tester.getTopLeft(right).dy, .1),
          );
          expect(
            tester.getSize(left).width,
            closeTo(tester.getSize(right).width, .1),
          );
        }
        await tester.tap(find.byTooltip('ذخیره'));
        await tester.pumpAndSettle();
        expect(repo.writes.single['config']['kind'], engine);
        expect(repo.writes.single['config']['questions'][0]['choices'], [
          'A',
          'B',
        ]);
        expect(repo.writes.single['config']['questions'][0]['correct'], 0);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        repo.dispose();
      },
    );
  }
  testWidgets('exam visibility uses its own eye and publication endpoint', (
    tester,
  ) async {
    final repo = TreePracticeRepository();
    await tester.pumpWidget(
      fixture.host(
        MusicPracticePage(repository: repo, nodeId: 3, showLevels: true),
      ),
    );
    await tester.pumpAndSettle();
    final eye = find.byKey(const ValueKey('practice-visibility-exam-10'));
    await tester.ensureVisible(eye);
    await tester.tap(eye);
    await tester.pumpAndSettle();
    expect(repo.writes.last, {
      'path': 'publish',
      'kind': 'exam',
      'id': 10,
      'version': 1,
      'published': false,
    });
    expect(
      find.descendant(
        of: eye,
        matching: find.byIcon(Icons.visibility_off_outlined),
      ),
      findsOneWidget,
    );
    await tester.tap(eye);
    await tester.pumpAndSettle();
    expect(repo.writes.last['published'], true);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    repo.dispose();
  });

  for (final depth in [1, 2, 3]) {
    testWidgets('creator can choose and save a music icon at depth $depth', (
      tester,
    ) async {
      final repo = TreePracticeRepository();
      final data = await repo.catalog(manage: true);
      await tester.pumpWidget(
        fixture.host(
          MusicPracticeEditPage(
            repository: repo,
            catalog: data,
            kind: 'nodes',
            item: {
              'parentId': depth == 1 ? 0 : depth - 1,
              'titleFa': 'بخش جدید',
              'titleEn': 'New section',
              'slug': 'new-section',
              'iconKey': 'mic',
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      final picker = find.byKey(const ValueKey('practice-icon-picker'));
      await tester.ensureVisible(picker);
      await tester.tap(picker);
      await tester.pumpAndSettle();
      await tester.tap(find.text('پیانو').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('ذخیره'));
      await tester.pumpAndSettle();
      expect(repo.writes.last['path'], 'nodes');
      expect(repo.writes.last['iconKey'], 'piano');
      expect(repo.writes.last['parentId'], depth == 1 ? 0 : depth - 1);
      await tester.pumpWidget(const SizedBox.shrink());
      repo.dispose();
    });
  }

  testWidgets(
    'custom icon renders with no card and unavailable actions stay disabled',
    (tester) async {
      final repo = TreePracticeRepository();
      repo.tree.firstWhere((n) => n['id'] == 3)['iconKey'] = 'headphones';
      repo.tree.firstWhere((n) => n['id'] == 1)['published'] = false;
      await tester.pumpWidget(
        fixture.host(MusicPracticePage(repository: repo, nodeId: 2)),
      );
      await tester.pumpAndSettle();
      expect(find.byType(Card), findsNothing);
      expect(find.byIcon(Icons.headphones_outlined), findsOneWidget);
      final edit = tester.widget<IconButton>(
        find.byKey(const ValueKey('practice-edit-node-3')),
      );
      expect(edit.onPressed, isNull);
      expect(
        tester
            .widget<IconButton>(
              find.byKey(const ValueKey('practice-delete-node-3')),
            )
            .onPressed,
        isNull,
      );
      expect(repo.writes, isEmpty);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  for (final language in ['fa', 'en']) {
    for (final level in [1, 2, 3, 0]) {
      testWidgets(
        'item $level has pencil/trash outside its menu at 320px ($language)',
        (tester) async {
          tester.view.physicalSize = const Size(320, 900);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final repo = TreePracticeRepository(),
              isExam = level == 0,
              id = isExam ? 10 : level;
          final kind = isExam ? 'exam' : 'node', itemKey = '$kind-$id';
          await tester.pumpWidget(
            ChangeNotifierProvider(
              create: (_) => AppData(),
              child: MaterialApp(
                locale: Locale(language),
                supportedLocales: const [Locale('fa'), Locale('en')],
                localizationsDelegates: const [
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                theme: language == 'en' ? ThemeData.dark() : ThemeData.light(),
                home: MusicPracticePage(
                  repository: repo,
                  nodeId: isExam
                      ? 3
                      : level == 1
                      ? null
                      : level - 1,
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          final pencil = find.byKey(ValueKey('practice-edit-$itemKey')),
              trash = find.byKey(ValueKey('practice-delete-$itemKey'));
          expect(pencil, findsOneWidget);
          expect(trash, findsOneWidget);
          expect(tester.widget<IconButton>(pencil).color, Colors.black);
          expect(tester.widget<IconButton>(trash).color, Colors.red);
          await tester.ensureVisible(pencil);
          final tile = tester.widget<ListTile>(
            find.ancestor(of: pencil, matching: find.byType(ListTile)).first,
          );
          final iconRect = tester.getRect(find.byWidget(tile.leading!));
          final titleRect = tester.getRect(find.byWidget(tile.title!));
          expect(
            language == 'en'
                ? titleRect.left - iconRect.right
                : iconRect.left - titleRect.right,
            closeTo(8, .01),
          );
          await tester.tap(pencil);
          await tester.pumpAndSettle();
          final editor = tester.widget<MusicPracticeEditPage>(
            find.byType(MusicPracticeEditPage),
          );
          expect(editor.item?['id'], id);
          expect(editor.kind, isExam ? 'exams' : 'nodes');
          Navigator.of(
            tester.element(find.byType(MusicPracticeEditPage)),
          ).pop();
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(ValueKey('practice-menu-$itemKey')));
          await tester.pumpAndSettle();
          for (final label in [
            'افزودن زیرسطح',
            'سطح‌های آزمون',
            'ویرایش',
            'حذف سطح',
            'Add subsection',
            'Test levels',
            'Edit',
            'Delete level',
          ]) {
            expect(find.text(label), findsNothing);
          }
          await tester.tapAt(const Offset(1, 1));
          await tester.pumpAndSettle();
          await tester.tap(trash);
          await tester.pumpAndSettle();
          expect(find.byType(AlertDialog), findsOneWidget);
          await tester.tap(
            find
                .descendant(
                  of: find.byType(AlertDialog),
                  matching: find.byType(TextButton),
                )
                .first,
          );
          await tester.pumpAndSettle();
          expect(repo.writes, isEmpty);
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox.shrink());
          repo.dispose();
        },
      );
    }
  }
  for (final scenario in [
    'permission',
    'ownership',
    'schema',
    'partial-schema',
  ]) {
    testWidgets('item edit/delete obey $scenario restrictions', (tester) async {
      final repo = ItemActionCatalog(
        allowed: scenario != 'permission',
        owned: scenario != 'ownership',
        deletionReady: scenario != 'schema',
        levelDeletionReady: scenario != 'partial-schema',
      );
      await tester.pumpWidget(
        fixture.host(MusicPracticePage(repository: repo, nodeId: 2)),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('practice-delete-node-3')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('practice-edit-node-3')),
        ['schema', 'partial-schema'].contains(scenario)
            ? findsOneWidget
            : findsNothing,
      );
      expect(repo.writes, isEmpty);
      await tester.pumpWidget(const SizedBox.shrink());
      repo.dispose();
    });
  }
  testWidgets('node trash confirms the existing node deletion endpoint', (
    tester,
  ) async {
    final repo = TreePracticeRepository()..examNode = 99;
    await tester.pumpWidget(
      fixture.host(MusicPracticePage(repository: repo, nodeId: 2)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('practice-delete-node-3')));
    await tester.pumpAndSettle();
    await tester.tap(
      find
          .descendant(
            of: find.byType(AlertDialog),
            matching: find.byType(TextButton),
          )
          .last,
    );
    await tester.pumpAndSettle();
    expect(repo.writes.single, {'path': 'nodes/delete', 'id': 3, 'version': 1});
    await tester.pumpWidget(const SizedBox.shrink());
    repo.dispose();
  });

  test('unknown server icon falls back safely', () {
    expect(
      PracticeIcons.forNode({'depth': 1, 'iconKey': 'future-icon'}),
      Icons.library_music_outlined,
    );
    expect(
      PracticeIcons.forNode({'depth': 3, 'slug': 'iranian'}),
      Icons.music_note,
    );
  });
}
