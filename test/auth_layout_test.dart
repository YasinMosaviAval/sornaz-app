import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sornaz/helpers/app_data.dart';
import 'package:sornaz/screens/Authentication/providers/auth_session.dart';
import 'package:sornaz/screens/Authentication/ui/pages/authentication.dart';
import 'package:sornaz/components/app_drawer_item.dart';
import 'drawer_accounts_test.dart' as fixtures;

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
  });
  testWidgets('login fills viewport and remains scrollable with keyboard', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpWidget(
      fixtures.host(const SignInScreen(), AppData(), AuthSession()),
    );
    await tester.pumpAndSettle();
    expect(
      tester.getRect(find.text('ادامه بدون ورود')).bottom,
      greaterThan(790),
    );
    await tester.tap(find.text('مرا به خاطر بسپار'));
    await tester.pump();
    expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isTrue);
    tester.view.viewInsets = const FakeViewPadding(bottom: 320);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('ادامه بدون ورود'));
    expect(tester.takeException(), isNull);
  });
  testWidgets('drawer remains open after returning from its destination', (
    tester,
  ) async {
    final scaffold = GlobalKey<ScaffoldState>();
    await tester.pumpWidget(
      fixtures.host(
        Scaffold(
          key: scaffold,
          drawer: const Drawer(
            child: AppDrawerItem(
              icon: Icons.info,
              text: 'destination',
              link: Scaffold(body: Text('opened')),
            ),
          ),
        ),
        AppData(),
        AuthSession(),
      ),
    );
    scaffold.currentState!.openDrawer();
    await tester.pumpAndSettle();
    await tester.tap(find.text('destination'));
    await tester.pumpAndSettle();
    expect(find.text('opened'), findsOneWidget);
    Navigator.of(tester.element(find.text('opened'))).pop();
    await tester.pumpAndSettle();
    expect(scaffold.currentState!.isDrawerOpen, isTrue);
    expect(find.text('destination'), findsOneWidget);
  });
}
