import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/testing.dart';
import 'package:sornaz/components/app_top_bar_direction.dart';
import 'package:sornaz/screens/Social/social_profile.dart';
import 'package:sornaz/screens/Social/social_api.dart';
import 'package:sornaz/screens/Site/panel_api.dart';
import 'social_widget_test.dart' as fixture;
import 'native_panel_test.dart' show reply;

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  for (final type in ['human', 'academy']) {
    testWidgets(
      'profile loads private $type contacts and separate public email',
      (tester) async {
        tester.view.physicalSize = const Size(800, 3000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        var requests = 0;
        final panel = PanelApi(
          'token',
          client: MockClient((r) async {
            requests++;
            return reply({
              'profile': {
                'accountType': type,
                'email': 'private@example.com',
                'phone': '09121234567',
                'founded': '2000-01-01',
                'address': 'Address',
                'shortIntro': 'Introduction',
              },
            });
          }),
        );
        final social = SocialApi(
          'token',
          client: MockClient(
            (r) async => throw StateError('Unexpected social request'),
          ),
        );
        await tester.pumpWidget(
          fixture.host(
            EditProfilePage(
              api: social,
              accountApi: panel,
              profile: {
                'id': 2,
                'name': 'Member',
                'links': {'email': 'public@example.com'},
              },
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(requests, 1);
        final fields = tester
            .widgetList<TextFormField>(find.byType(TextFormField))
            .toList();
        expect(
          fields.map((f) => f.controller?.text),
          containsAll([
            'private@example.com',
            'public@example.com',
            '09121234567',
            'Address',
            'Introduction',
          ]),
        );
        expect(
          find.text(type == 'human' ? 'تاریخ تولد' : 'تاریخ تأسیس'),
          findsOneWidget,
        );
        await tester.pump();
        expect(requests, 1);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        panel.dispose();
        social.dispose();
      },
    );
  }
  testWidgets('failed private profile load cannot submit blank contact data', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final panel = PanelApi(
      'token',
      client: MockClient((r) async => reply({}, 503)),
    );
    final social = SocialApi('token');
    await tester.pumpWidget(
      fixture.host(
        EditProfilePage(
          api: social,
          accountApi: panel,
          profile: {'id': 2, 'name': 'Member'},
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
    await tester.pumpWidget(const SizedBox());
    panel.dispose();
    social.dispose();
  });
  testWidgets('Persian page title uses shared size and back spacing', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      fixture.host(
        Scaffold(
          appBar: AppTopBarDirection(
            child: AppBar(
              leading: const BackButton(),
              title: const Text('Title'),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final bar = tester.widget<AppBar>(find.byType(AppBar));
    expect(bar.titleSpacing, 0);
    expect((bar.title as Text).style?.fontSize, 14);
    expect(
      tester.getCenter(find.byType(BackButton)).dx,
      greaterThan(tester.getCenter(find.text('Title')).dx),
    );
  });
}
