import 'package:sornaz/components/settings_section_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sornaz/screens/Site/panel_resource_page.dart';
import 'package:sornaz/screens/Site/account_membership_request.dart';
import 'package:sornaz/screens/Social/social_api.dart';
import 'account_production_ui_test.dart' as account;

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  testWidgets(
    'release merge form is plain and validates identifiers before saving',
    (tester) async {
      account.wide(tester);
      final api = account.AccountUiApi(), auth = account.session(2);
      addTearDown(api.dispose);
      addTearDown(auth.dispose);
      final section = objects((await api.get(''))['sections']).single;
      await tester.pumpWidget(
        account.host(
          auth,
          PanelResourcePage(
            api: api,
            section: section,
            accountArea: 'merges.requests',
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(AccountMembershipRequest), findsOneWidget);
      expect(find.byType(ExpansionTile), findsNothing);
      expect(find.byType(TextFormField), findsNWidgets(3));
      await tester.tap(find.text('ارسال درخواست ادغام'));
      await tester.pumpAndSettle();
      expect(api.savedPayload, isNull);
      await tester.enterText(find.byType(TextFormField).at(0), '5');
      await tester.enterText(find.byType(TextFormField).at(1), '9');
      await tester.tap(find.text('ارسال درخواست ادغام'));
      await tester.pumpAndSettle();
      expect(api.savedPayload?['action'], 'merge');
      expect(api.savedPayload?['userId'], '5');
    },
  );
  testWidgets('release full account panel restores four section boxes', (tester) async {
    account.wide(tester);
    final api = account.AccountUiApi(), auth = account.session(2);
    addTearDown(api.dispose); addTearDown(auth.dispose);
    final section = objects((await api.get(''))['sections']).single;
    await tester.pumpWidget(account.host(auth, PanelResourcePage(api: api, section: section)));
    await tester.pumpAndSettle();
    final titles = tester.widgetList<SettingsSectionHeader>(find.byType(SettingsSectionHeader)).map((item) => item.title);
    for (final title in ['دستگاه‌ها', 'اسناد', 'تاریخچه ورود', 'هشدارهای امنیتی']) {
      expect(titles, contains(title));
    }
    expect(tester.takeException(), isNull);
  });
  for (final area in [
    'devices',
    'documents',
    'loginHistory',
    'securityAlerts',
  ]) {
    testWidgets('release $area has no section box', (tester) async {
      account.wide(tester);
      final api = account.AccountUiApi(), auth = account.session(2);
      addTearDown(api.dispose);
      addTearDown(auth.dispose);
      final section = objects((await api.get(''))['sections']).single;
      await tester.pumpWidget(
        account.host(
          auth,
          PanelResourcePage(api: api, section: section, accountArea: area),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(ExpansionTile), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
}
