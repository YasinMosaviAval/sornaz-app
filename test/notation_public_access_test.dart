import 'package:sornaz/helpers/app_locale_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sornaz/components/main_tabs.dart';
import 'package:sornaz/screens/Authentication/providers/auth_session.dart';
import 'package:sornaz/screens/Authentication/models/auth_user.dart';
import 'package:sornaz/screens/Home/ui/pages/music_tools.dart';
import 'package:sornaz/screens/Notation/music_sheets_page.dart';
import 'package:sornaz/screens/Notation/desktop_notation_host.dart';
import 'social_widget_test.dart' as fixture;

void main() {
  for (final id in <int?>[null, 2, 1]) {
    testWidgets('notation visible and directly accessible for user $id', (
      tester,
    ) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      SharedPreferences.setMockInitialValues({});
      final session = AuthSession();
      if (id != null) {
        session.user = AuthUser(id: id, username: 'user$id', fullName: 'User');
        session.token = 'test-$id';
      }
      Widget host(Widget child) => ChangeNotifierProvider.value(
        value: session,
        child: ChangeNotifierProvider(
          create: (_) => LocaleProvider(),
          child: fixture.host(child),
        ),
      );
      await tester.pumpWidget(
        host(
          MainTabsScope(
            index: 3,
            select: (_) {},
            setEditorOpen: (_) {},
            setChrome: (_, bar) {},
            child: const MusicToolsPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Notation'), findsNothing);
      expect(find.byIcon(Icons.music_note_outlined), findsOneWidget);
      await tester.pumpWidget(host(const MusicSheetsPage()));
      await tester.pumpAndSettle();
      expect(find.byType(DesktopNotationHost), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      debugDefaultTargetPlatformOverride = null;
    });
  }
}
