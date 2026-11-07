import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sornaz/screens/MusicPractice/practice_icons.dart';
import 'package:sornaz/screens/MusicPractice/practice_manage_page.dart';
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
        for (final label in ['Section 1', 'Section 2', 'Section 3']) {
          await tester.ensureVisible(find.text(label));
          await tester.tap(find.text(label));
          await tester.pumpAndSettle();
        }
        expect(find.text('First level'), findsOneWidget);
        expect(find.byIcon(Icons.more_vert), findsNothing);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }

  test(
    'tree mode defaults on and only founder can retain page-by-page mode',
    () async {
      expect(await MusicPracticeSettingsPage.hierarchyMode(1), isTrue);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(MusicPracticeSettingsPage.hierarchyModeKey, false);
      expect(await MusicPracticeSettingsPage.hierarchyMode(1), isFalse);
      expect(await MusicPracticeSettingsPage.hierarchyMode(3), isTrue);
      expect(await MusicPracticeSettingsPage.hierarchyMode(null), isTrue);
    },
  );

  for (final actor in [1, 3]) {
    testWidgets('tree expands all depths on one page for actor $actor', (
      tester,
    ) async {
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
          'nodes' => editing ? 'ویرایش سطح' : 'افزودن سطح',
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
      await tester.tap(find.byKey(const ValueKey('practice-menu-node-3')));
      await tester.pumpAndSettle();
      final edit = tester.widget<PopupMenuItem<VoidCallback>>(
        find.ancestor(
          of: find.text('ویرایش'),
          matching: find.byType(PopupMenuItem<VoidCallback>),
        ),
      );
      expect(edit.enabled, isFalse);
      expect(repo.writes, isEmpty);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

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
