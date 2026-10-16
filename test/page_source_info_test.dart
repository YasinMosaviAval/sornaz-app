import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sornaz/components/page_source_info.dart';
import 'package:sornaz/components/page_source_catalog.dart';
import 'package:sornaz/components/app_text.dart';
import 'package:sornaz/components/app_top_bar_direction.dart';
import 'package:sornaz/components/expanding_search_bar.dart';
import 'package:sornaz/components/app_logo.dart';
import 'package:sornaz/screens/Authentication/models/auth_user.dart';
import 'package:sornaz/screens/Authentication/providers/auth_session.dart';

AuthSession session(int id) => AuthSession()
  ..token = 'test-only'
  ..user = AuthUser(id: id, username: 'test', fullName: 'Test');

class TestSession extends AuthSession {
  void changeAccount(int? id) {
    token = id == null ? null : 'test-only';
    user = id == null
        ? null
        : AuthUser(id: id, username: 'test', fullName: 'Test');
    notifyListeners();
  }
}

void main() {
  test('requires an authenticated account with exactly id 1', () {
    expect(canInspectPage(null), isFalse);
    expect(canInspectPage(session(2)), isFalse);
    expect(canInspectPage(session(1)..token = null), isFalse);
    expect(canInspectPage(session(1)), isTrue);
  });

  test('catalog identifies real page widgets and their local imports', () {
    expect(
      pageSourceClasses['HomePage'],
      contains('lib/screens/Home/ui/pages/learning_home.dart'),
    );
    expect(
      pageSourceImports['lib/components/home_top_bar.dart'],
      contains('lib/components/expanding_search_bar.dart'),
    );
    expect(
      pageSourceResources['lib/screens/Notation/music_sheets_page.dart'],
      contains('assets/notation/index.html'),
    );
  });

  testWidgets(
    'account switching updates icon and nested toolbars do not duplicate it',
    (tester) async {
      final auth = TestSession();
      await tester.pumpWidget(
        ChangeNotifierProvider<AuthSession>.value(
          value: auth,
          child: MaterialApp(
            home: Scaffold(
              appBar: PreferredSize(
                preferredSize: const Size.fromHeight(48),
                child: PageSourceToolbar(
                  child: PageSourceToolbar(
                    child: AppBar(title: const Text('Page')),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      expect(find.byKey(const ValueKey('page-source-info')), findsNothing);
      auth.changeAccount(1);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('page-source-info')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('page-source-info')));
      await tester.pumpAndSettle();
      expect(find.text('Page implementation'), findsOneWidget);
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
      auth.changeAccount(2);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('page-source-info')), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'dialog lists visible source files and closes on logout without closing page',
    (tester) async {
      final auth = TestSession()..changeAccount(1);
      await tester.pumpWidget(
        ChangeNotifierProvider<AuthSession>.value(
          value: auth,
          child: MaterialApp(
            home: Scaffold(
              appBar: AppTopBarDirection.standard(
                title: const Text('Source test'),
              ),
              body: const Column(
                children: [
                  AppText('Visible text'),
                  Offstage(child: AppLogo(isDark: false)),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.byKey(const ValueKey('page-source-info')));
      await tester.pumpAndSettle();
      expect(find.text('lib/components/app_text.dart'), findsOneWidget);
      expect(find.text('lib/components/app_logo.dart'), findsNothing);
      auth.changeAccount(null);
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.text('Visible text'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'search toolbar keeps admin action available on a narrow screen',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        ChangeNotifierProvider<AuthSession>.value(
          value: session(1),
          child: MaterialApp(
            home: Scaffold(
              appBar: ExpandingSearchBar(
                title: const Text('Page title'),
                onChanged: (_) {},
                onSettings: () {},
                actions: [
                  IconButton(onPressed: () {}, icon: const Icon(Icons.add)),
                ],
              ),
            ),
          ),
        ),
      );
      expect(find.byKey(const ValueKey('page-source-info')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('open-search')));
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byKey(const ValueKey('page-source-info')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('extra video controls stay reachable without overflowing', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ChangeNotifierProvider<AuthSession>.value(
        value: session(1),
        child: MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 52,
              child: PageSourceControlRow(
                children: [
                  const PageSourceInfoButton(),
                  for (var i = 0; i < 8; i++)
                    IconButton(
                      key: ValueKey('control-$i'),
                      onPressed: () {},
                      icon: const Icon(Icons.play_arrow),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(-400, 0),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('control-7')).hitTestable(),
      findsOneWidget,
    );
  });
}
