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
  for (final type in ['academy', 'branch', 'human']) {
    testWidgets('merge section visibility follows account type $type', (
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
              area: 'merges.requests',
              data: {
                'profile': {'accountType': type},
                'merges': {'eligible': true},
              },
              actions: const {'merge': {}, 'end-session': {}},
              onAction: (_, __) async {},
              onChanged: () async {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.byType(SettingsSectionHeader),
        type == 'human' ? findsOneWidget : findsNothing,
      );
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('remove cover uses destructive colors and retains its action', (
    tester,
  ) async {
    account.wide(tester);
    final api = account.AccountUiApi(), auth = account.session(2);
    addTearDown(api.dispose);
    addTearDown(auth.dispose);
    String? invoked;
    Json? values;
    await tester.pumpWidget(
      account.host(
        auth,
        SingleChildScrollView(
          child: PanelAccount(
            api: api,
            data: const {
              'profile': {'accountType': 'human', 'coverId': 19},
            },
            actions: const {'delete-media': {}, 'cover': {}},
            onAction: (key, row) async {
              invoked = key;
              values = row;
            },
            onChanged: () async {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final finder = find.widgetWithIcon(IconButton, Icons.delete_outline);
    final button = tester.widget<IconButton>(finder);
    final colors = Theme.of(tester.element(finder)).colorScheme;
    expect(button.style!.backgroundColor!.resolve({}), Colors.white);
    expect(button.style!.foregroundColor!.resolve({}), Colors.red);
    expect(button.style!.shape!.resolve({}), isA<CircleBorder>());
    final camera = tester.widget<IconButton>(
      find.byWidgetPredicate(
        (widget) =>
            widget is IconButton && widget.tooltip == 'Change cover' ||
            widget is IconButton && widget.tooltip == 'تغییر کاور',
      ),
    );
    expect(camera.style!.backgroundColor!.resolve({}), Colors.white);
    expect(camera.style!.foregroundColor!.resolve({}), colors.primary);
    expect(camera.style!.shape!.resolve({}), isA<CircleBorder>());
    expect(find.text('Change cover'), findsNothing);
    expect(find.text('Remove cover'), findsNothing);
    await tester.tap(finder);
    expect(invoked, 'delete-media');
    expect(values?['id'], 19);
    expect(tester.takeException(), isNull);
  });
  testWidgets('signed out devices replace logout controls with a gray label', (
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
            area: 'devices',
            data: const {
              'profile': {'accountType': 'human'},
              'devices': [
                {
                  'id': 5,
                  'name': 'Old device',
                  'status': 'ended',
                  'current': false,
                },
              ],
            },
            actions: const {'end-session': {}},
            onAction: (_, __) async {},
            onChanged: () async {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byType(SettingsSectionHeader));
    await tester.pumpAndSettle();
    final label = find.text('خارج شده');
    expect(label, findsOneWidget);
    expect(tester.widget<Text>(label).style!.color, Colors.grey);
    expect(find.byIcon(Icons.logout), findsNothing);
    expect(find.byType(TextButton), findsNothing);
  });
  for (final area in [
    'merges.requests',
    'devices',
    'documents',
    'loginHistory',
    'securityAlerts',
  ]) {
    testWidgets('account $area content is contained in a section box', (
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
      expect(find.byType(SettingsSectionHeader), findsOneWidget);
      await tester.tap(find.byType(SettingsSectionHeader));
      await tester.pumpAndSettle();
      if (area == 'merges.requests') {
        expect(find.byType(TextFormField), findsNWidgets(3));
        expect(find.text('ارسال درخواست ادغام'), findsOneWidget);
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
  testWidgets('full panel account keeps all four section boxes', (
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
            data: const {
              'profile': {'accountType': 'human'},
            },
            actions: const {},
            onAction: (_, __) async {},
            onChanged: () async {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    for (final title in [
      'Connected devices',
      'Documents',
      'Login and logout history',
      'Security alerts',
    ]) {
      expect(find.byKey(ValueKey('account-section-$title')), findsOneWidget);
    }
    expect(tester.takeException(), isNull);
  });
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
    await tester.tap(find.text('درخواست ادغام حساب'));
    await tester.pumpAndSettle();
    expect(find.byType(TextFormField), findsNWidgets(3));
    await tester.enterText(find.byType(TextFormField).at(0), '5');
    await tester.enterText(find.byType(TextFormField).at(1), '9');
    await tester.tap(find.text('ارسال درخواست ادغام'));
    await tester.pumpAndSettle();
    expect(api.savedPayload?['action'], 'merge');
    expect(api.savedPayload?['userId'], '5');
  });
}
