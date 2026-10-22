import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sornaz/components/settings_section_header.dart';
import 'package:sornaz/screens/Site/panel_account.dart';
import 'package:sornaz/screens/Site/panel_navigation.dart';
import 'package:sornaz/screens/Social/social_learning.dart';
import 'account_production_ui_test.dart' as fixture;

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test('website panel navigation removes the account destination', () {
    final menu = websitePanelNavigation({
      'navigationVersion': 1,
      'sections': [
        {'key': 'account'},
        {'key': 'dashboard'},
      ],
      'navigation': [
        {'key': 'account', 'section': 'account'},
        {'key': 'dashboard', 'section': 'dashboard'},
      ],
    });
    expect(menu.map((item) => item['key']), ['dashboard']);
  });
  for (final id in [1, 2]) {
    testWidgets('one complete account page for user $id', (tester) async {
      fixture.wide(tester);
      final api = fixture.social(),
          panel = fixture.AccountUiApi(),
          auth = fixture.session(id);
      addTearDown(api.dispose);
      addTearDown(panel.dispose);
      addTearDown(auth.dispose);
      await tester.pumpWidget(
        fixture.host(auth, AccountDashboardBody(api: api, accountApi: panel)),
      );
      await tester.pumpAndSettle();
      expect(find.byType(PanelAccount), findsOneWidget);
      for (final key in [
        'Main information',
        'My invitation link',
        'Link membership records to my account',
        'Privacy and public visibility',
        'Connected devices',
        'Documents',
        'Login and logout history',
        'Security alerts',
      ]) {
        expect(find.byKey(ValueKey('account-section-$key')), findsOneWidget);
      }
      expect(find.text('درخواست ادغام حساب'), findsOneWidget);
      expect(find.text('پیشرفت یادگیری'), findsNothing);
      expect(find.byType(Scaffold), findsOneWidget);
      await tester.ensureVisible(find.text('حریم خصوصی و نمایش عمومی'));
      await tester.tap(find.text('حریم خصوصی و نمایش عمومی'));
      await tester.pumpAndSettle();
      final option = find.byType(CheckboxListTile).first;
      expect(
        (tester.widget<CheckboxListTile>(option).title as Text).style?.fontSize,
        12,
      );
      await tester.ensureVisible(option);
      await tester.tap(option);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('ذخیره تنظیمات حریم خصوصی'));
      await tester.tap(find.text('ذخیره تنظیمات حریم خصوصی'));
      await tester.pumpAndSettle();
      expect(panel.savedPayload?['action'], 'privacy');
      expect(panel.savedPayload?['showPublicProfile'], false);
      expect(tester.takeException(), isNull);
    });
  }
}
