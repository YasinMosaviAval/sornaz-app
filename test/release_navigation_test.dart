import 'package:sornaz/screens/Site/panel_navigation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sornaz/components/main_tabs.dart';
import 'package:sornaz/helpers/app_data.dart';
import 'package:sornaz/screens/Authentication/providers/auth_session.dart';
import 'package:sornaz/screens/Social/chat_tab_page.dart';
import 'package:sornaz/screens/Social/my_profile_page.dart';
import 'package:sornaz/screens/Social/user_panel.dart';

import 'drawer_accounts_test.dart' as fixture;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'release panel excludes experimental notation and keeps authorized posts',
    () {
      final menu = websitePanelNavigation({
        'navigationVersion': 1,
        'sections': [
          {
            'key': 'posts',
            'actions': {'list': {}},
          },
        ],
        'navigation': [
          {'key': 'notation', 'destination': 'notation'},
          {'key': 'posts', 'section': 'posts'},
          {'key': 'settings', 'destination': 'settings'},
        ],
      });
      expect(menu.map((item) => item['key']), ['posts']);
      expect(menu.single['pageTabs'], hasLength(1));
      expect(
        () => websitePanelNavigation({'sections': []}),
        throwsA(isA<PanelNavigationUnavailable>()),
      );
    },
  );

  testWidgets('release tabs use existing chat and account destinations', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      fixture.host(const MainTabs(initialIndex: 2), AppData(), AuthSession()),
    );
    await tester.pumpAndSettle();
    expect(find.byType(ChatTabPage), findsOneWidget);
    expect(find.byType(MyProfilePage), findsNothing);
    expect(find.text('گفتگو'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.manage_accounts_outlined));
    await tester.pumpAndSettle();
    expect(find.byType(UserPanelPage), findsOneWidget);
    expect(find.byType(MyProfilePage), findsNothing);
    expect(find.text('حساب کاربری'), findsOneWidget);
  });
}
