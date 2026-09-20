import 'package:provider/provider.dart';
import 'package:sornaz/helpers/app_data.dart';
import 'package:sornaz/components/drawer_theme.dart';
import 'package:sornaz/components/app_top_bar_direction.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sornaz/screens/Social/social_api.dart';
import 'package:sornaz/screens/Social/social_learning.dart';
import 'package:sornaz/screens/Site/panel_api.dart';
import 'package:sornaz/screens/Site/panel_form.dart';
import 'package:sornaz/screens/Site/panel_resource_page.dart';
import 'native_panel_test.dart' show reply;
import 'social_widget_test.dart' as fixture;

const privacyKeys = [
  'showPublicProfile',
  'showBranches',
  'showTeachers',
  'showContact',
  'showStats',
  'indexable',
];
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  for (final offset in [-2.0, 0.0, 2.0]) {
    testWidgets(
      'page title matches original Contact theme at font offset ' +
          offset.toString(),
      (tester) async {
        await tester.pumpWidget(
          fixture.host(
            Builder(
              builder: (context) {
                context.read<AppData>().fontSize = offset;
                return DrawerThemeScope(
                  child: Column(
                    children: [
                      Expanded(
                        child: Scaffold(
                          appBar: AppBar(title: const Text('Original contact')),
                        ),
                      ),
                      Expanded(
                        child: Scaffold(
                          appBar: AppTopBarDirection(
                            child: AppBar(
                              title: const Text(
                                'New title',
                                style: TextStyle(fontSize: 40),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
        await tester.pumpAndSettle();
        final original = DefaultTextStyle.of(
          tester.element(find.text('Original contact')),
        ).style.fontSize;
        expect(
          tester.widget<Text>(find.text('New title')).style?.fontSize,
          original,
        );
      },
    );
  }
  testWidgets(
    'failed direct submission retains entered fields and allows retry',
    (tester) async {
      var attempts = 0;
      await tester.pumpWidget(
        fixture.host(
          PanelFormPage(
            title: 'Password',
            fields: const [
              {'key': 'password', 'label': 'Password', 'type': 'password'},
            ],
            data: const {},
            onSubmit: (result) async {
              attempts++;
              throw const SocialException('Try again');
            },
          ),
        ),
      );
      await tester.enterText(find.byType(TextFormField), 'example-secret');
      await tester.tap(find.byIcon(Icons.save_outlined));
      await tester.pumpAndSettle();
      expect(find.byType(PanelFormPage), findsOneWidget);
      expect(
        tester
            .widget<TextFormField>(find.byType(TextFormField))
            .controller
            ?.text,
        'example-secret',
      );
      expect(
        tester
            .widget<IconButton>(
              find.widgetWithIcon(IconButton, Icons.save_outlined),
            )
            .onPressed,
        isNotNull,
      );
      expect(attempts, 1);
    },
  );
  for (final type in ['human', 'academy', 'branch']) {
    testWidgets(
      'account forms open directly and merge visibility follows $type',
      (tester) async {
        tester.view.physicalSize = const Size(800, 2600);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final writes = <String, Json>{};
        var catalogReads = 0;
        final panel = PanelApi(
          'token',
          client: MockClient((request) async {
            if (request.method == 'POST') {
              final encoded = request.body
                  .split('name="payload_b64"')
                  .last
                  .trim()
                  .split(RegExp(r'\s'))
                  .first;
              writes[request.url.path.split('/').last] = object(
                jsonDecode(utf8.decode(base64Decode(encoded))),
              );
              return reply({});
            }
            if (request.url.path.endsWith('/account/list'))
              return reply({
                'profile': {
                  'privacy': {for (final key in privacyKeys) key: true},
                },
              });
            catalogReads++;
            return reply({
              'sections': [
                {
                  'key': 'account',
                  'actions': {
                    'privacy': {
                      'fields': [
                        for (final key in privacyKeys)
                          {'key': key, 'label': key, 'type': 'bool'},
                      ],
                    },
                    'security': {
                      'fields': [
                        {
                          'key': 'password',
                          'label': 'رمز عبور جدید',
                          'type': 'password',
                          'required': true,
                        },
                        {
                          'key': 'passwordConfirmation',
                          'label': 'تکرار رمز عبور',
                          'type': 'password',
                          'required': true,
                        },
                      ],
                    },
                    'merge': {
                      'fields': [
                        {
                          'key': 'userId',
                          'label': 'شناسه کاربر',
                          'type': 'number',
                        },
                      ],
                    },
                  },
                },
              ],
            });
          }),
        );
        final social = SocialApi(
          'token',
          client: MockClient(
            (r) async => reply({
              'profile': {
                'id': 2,
                'name': 'Member',
                'username': 'member',
                'type': type,
              },
              'courses': [],
            }),
          ),
        );
        await tester.pumpWidget(
          fixture.host(
            Scaffold(
              body: AccountDashboardBody(api: social, accountApi: panel),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          find.text('درخواست ادغام حساب'),
          type == 'human' ? findsOneWidget : findsNothing,
        );
        await tester.tap(find.text('حریم خصوصی'));
        await tester.pumpAndSettle();
        expect(find.byType(PanelResourcePage), findsNothing);
        expect(find.byType(CheckboxListTile), findsNWidgets(6));
        expect(find.byType(SwitchListTile), findsNothing);
        final tile = tester.widget<CheckboxListTile>(
          find.byType(CheckboxListTile).first,
        );
        expect((tile.title as Text).style?.fontSize, 14);
        await tester.tap(find.byType(CheckboxListTile).first);
        await tester.pumpAndSettle();
        await tester.tap(find.byIcon(Icons.save_outlined));
        await tester.pumpAndSettle();
        expect(writes['privacy']?['showPublicProfile'], false);
        expect(writes['privacy']?['showContact'], true);
        expect(find.byType(PanelFormPage), findsNothing);
        await tester.tap(find.text('تغییر رمز عبور'));
        await tester.pumpAndSettle();
        expect(find.byType(TextFormField), findsNWidgets(2));
        expect(find.byType(PanelResourcePage), findsNothing);
        await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle();
        if (type == 'human') {
          await tester.tap(find.text('درخواست ادغام حساب'));
          await tester.pumpAndSettle();
          expect(find.byType(TextFormField), findsOneWidget);
          expect(find.byType(PanelResourcePage), findsNothing);
          await tester.tap(find.byType(BackButton));
          await tester.pumpAndSettle();
        }
        expect(catalogReads, 1);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        panel.dispose();
        social.dispose();
      },
    );
  }
}
