import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sornaz/helpers/development_access.dart';
import 'package:sornaz/components/bottom_nav.dart';
import 'package:sornaz/components/main_tabs.dart';
import 'package:sornaz/screens/Authentication/providers/auth_session.dart';
import 'package:sornaz/screens/Authentication/models/auth_user.dart';
import 'package:sornaz/screens/Authentication/services/auth_api_service.dart';
import 'package:sornaz/screens/Home/ui/pages/music_tools.dart';
import 'package:sornaz/screens/Home/ui/pages/solfege_practice_page.dart';
import 'package:sornaz/screens/Notation/music_sheets_page.dart';
import 'package:sornaz/screens/Home/ui/pages/rhythm_practice_page.dart';
import 'package:sornaz/screens/Notation/music_analysis_test_page.dart';
import 'package:sornaz/screens/Notation/omr_review_page.dart';
import 'package:sornaz/screens/IntervalRecognition/music_selection_screen.dart';
import 'package:sornaz/screens/IntervalRecognition/levels_screen.dart';
import 'package:sornaz/screens/IntervalRecognition/progress.dart';
import 'package:sornaz/screens/IntervalRecognition/stars.dart';
import 'package:sornaz/screens/IntervalRecognition/settings.dart';
import 'package:sornaz/screens/IntervalRecognition/settings_screen.dart';
import 'social_widget_test.dart' as fixture;
import 'interval_recognition_test.dart' as interval;

AuthSession sessionFor(int? id, {String type = 'human', String? token}) {
  final session = AuthSession();
  if (id != null) {
    session.user = AuthUser(
      id: id,
      username: 'admin',
      fullName: 'User',
      type: type,
    );
    session.token = token ?? 'test-$id';
  }
  return session;
}

Widget host(AuthSession session, Widget child) =>
    ChangeNotifierProvider.value(value: session, child: fixture.host(child));
Widget scope(Widget child) => MainTabsScope(
  index: 3,
  select: (_) {},
  setEditorOpen: (_) {},
  setChrome: (_, bar) {},
  child: child,
);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test('only active ID 1 with a nonempty token can use development UI', () {
    expect(DevelopmentAccess.allows(null), false);
    expect(DevelopmentAccess.allows(sessionFor(null)), false);
    expect(DevelopmentAccess.allows(sessionFor(1, token: '')), false);
    expect(DevelopmentAccess.allows(sessionFor(1, token: '   ')), false);
    for (final type in ['human', 'admin', 'academy', 'branch', 'manager']) {
      expect(DevelopmentAccess.allows(sessionFor(2, type: type)), false);
    }
    expect(DevelopmentAccess.allows(sessionFor(1)), true);
  });
  for (final id in <int?>[null, 2, 1]) {
    testWidgets('navigation matches its release/development audience for $id', (
      tester,
    ) async {
      final session = sessionFor(id);
      await tester.pumpWidget(
        host(
          session,
          const Scaffold(bottomNavigationBar: BottomNavBarWidget()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('صحنه'), id == 1 ? findsOneWidget : findsNothing);
      expect(find.text('پروفایل'), id == 1 ? findsOneWidget : findsNothing);
      expect(find.text('گفتگو'), id == 1 ? findsNothing : findsOneWidget);
      expect(find.text('حساب کاربری'), id == 1 ? findsNothing : findsOneWidget);
      expect(tester.takeException(), isNull);
    });
    testWidgets('music tools hide unreleased sections for $id', (tester) async {
      await tester.pumpWidget(
        host(sessionFor(id), scope(const MusicToolsPage())),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('آزمایش تحلیل اجرا'),
        id == 1 ? findsOneWidget : findsNothing,
      );
      expect(find.text('تمرین ریتم'), id == 1 ? findsOneWidget : findsNothing);
      expect(find.text('تمرین سولفژ'), id == 1 ? findsOneWidget : findsNothing);
      expect(find.text('نت‌نویسی'), id == 1 ? findsOneWidget : findsNothing);
      expect(tester.takeException(), isNull);
    });
    testWidgets(
      'interval appearance follows release for $id without discarding progress',
      (tester) async {
        final session = sessionFor(id);
        final store = interval.MemoryStore()
          ..progress = IntervalProgress().complete(1).complete(1);
        await tester.pumpWidget(
          host(session, IntervalLevelsScreen(store: store)),
        );
        await tester.pumpAndSettle();
        expect(
          find.byType(IntervalStars),
          id == 1 ? findsWidgets : findsNothing,
        );
        expect(store.progress.starsFor(1), 2);
        if (id != 1) expect(find.byIcon(Icons.check_circle), findsOneWidget);
        final settings = IntervalAudioSettings();
        await tester.pumpWidget(
          host(session, IntervalSettingsScreen(settings: settings)),
        );
        await tester.pumpAndSettle();
        expect(find.text('نت مبدا'), id == 1 ? findsOneWidget : findsNothing);
        await tester.pumpWidget(const SizedBox());
        settings.dispose();
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets(
    'switching accounts and logging out immediately revokes development widgets',
    (tester) async {
      final session = sessionFor(1);
      var built = 0;
      await tester.pumpWidget(
        host(
          session,
          Scaffold(
            body: Column(
              children: [
                const BottomNavBarWidget(),
                Expanded(
                  child: DevelopmentGate(
                    builder: (_) {
                      built++;
                      return const Text('development content');
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('development content'), findsOneWidget);
      await session.save(
        AuthResult(
          token: 'ordinary',
          user: AuthUser(
            id: 2,
            username: 'admin',
            fullName: 'User',
            type: 'admin',
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('development content'), findsNothing);
      expect(find.text('صحنه'), findsNothing);
      expect(find.text('گفتگو'), findsOneWidget);
      final previous = built;
      await session.save(
        AuthResult(
          token: 'founder',
          user: AuthUser(id: 1, username: 'founder', fullName: 'Founder'),
        ),
      );
      await tester.pumpAndSettle();
      expect(built, greaterThan(previous));
      await session.clear();
      await tester.pumpAndSettle();
      expect(find.text('development content'), findsNothing);
    },
  );
  testWidgets(
    'direct experimental routes do not construct their content for ordinary accounts',
    (tester) async {
      final session = sessionFor(2, type: 'admin');
      for (final page in [
        const MusicAnalysisTestPage(),
        OmrReviewPage(imageBytes: Uint8List(0)),
        const RhythmPracticePage(),
        const IranianIntervalScreen(),
        const MusicSheetsPage(),
        const SolfegePracticePage(),
      ]) {
        await tester.pumpWidget(host(session, page));
        await tester.pumpAndSettle();
        expect(find.byType(TextField), findsNothing);
        expect(find.byIcon(Icons.auto_fix_high), findsNothing);
        expect(find.text('Analyze'), findsNothing);
        expect(tester.takeException(), isNull);
      }
    },
  );
}
