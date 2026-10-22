import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sornaz/components/settings_section_header.dart';
import 'package:sornaz/screens/Site/panel_account.dart';
import 'package:sornaz/screens/Site/panel_resource_page.dart';
import 'package:sornaz/screens/Social/social_api.dart';
import 'account_production_ui_test.dart' as account;

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  for (final area in [
    'merges.requests',
    'devices',
    'documents',
    'loginHistory',
    'securityAlerts',
  ]) {
    testWidgets('ordinary account $area content has no section box', (
      tester,
    ) async {
      account.wide(tester);
      final api = account.AccountUiApi(), auth = account.session(2);
      addTearDown(api.dispose);
      addTearDown(auth.dispose);
      await tester.pumpWidget(
        account.host(
          auth,
          SingleChildScrollView(
            child: PanelAccount(
              api: api,
              area: area,
              data: const {
                'profile': {'accountType': 'human'},
                'merges': {'eligible': true, 'requests': []},
                'devices': [
                  {'id': 1, 'name': 'Fixture device'},
                ],
                'documents': [
                  {'id': 2, 'title': 'Fixture document'},
                ],
                'loginHistory': [
                  {'action': 'Fixture login', 'date': '2026-10-22'},
                ],
                'securityAlerts': [
                  {'title': 'Fixture alert'},
                ],
              },
              actions: const {'merge': {}},
              onAction: (_, __) async {},
              onChanged: () async {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(SettingsSectionHeader), findsNothing);
      if (area == 'merges.requests') {
        expect(find.byType(TextFormField), findsNWidgets(3));
        expect(find.text('ارسال درخواست بررسی'), findsOneWidget);
      } else if (area == 'devices')
        expect(find.text('Fixture device '), findsOneWidget);
      else if (area == 'documents')
        expect(find.text('Fixture document'), findsOneWidget);
      else if (area == 'loginHistory')
        expect(find.textContaining('Fixture login'), findsOneWidget);
      else
        expect(find.text('Fixture alert'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('merge requests submit through the single account section', (
    tester,
  ) async {
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
    expect(find.byType(TextFormField), findsNWidgets(3));
    await tester.enterText(find.byType(TextFormField).at(0), '5');
    await tester.enterText(find.byType(TextFormField).at(1), '9');
    await tester.tap(find.text('ارسال درخواست بررسی'));
    await tester.pumpAndSettle();
    expect(api.savedPayload?['action'], 'merge');
    expect(api.savedPayload?['userId'], '5');
  });
}
