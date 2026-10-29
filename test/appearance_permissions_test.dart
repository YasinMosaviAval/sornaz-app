import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sornaz/helpers/app_data.dart';
import 'package:sornaz/helpers/app_locale_provider.dart';
import 'package:sornaz/helpers/color_palette.dart';
import 'package:sornaz/screens/Authentication/models/auth_user.dart';
import 'package:sornaz/screens/Authentication/providers/auth_session.dart';
import 'package:sornaz/screens/Others/ui/pages/settings.dart';
import 'social_widget_test.dart' as fixture;

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test('original palette retains its light and dark primary colors', () {
    final appearance = AppData();
    expect(appearance.palette, ColorPalette.original);
    expect(appearance.accent, const Color(0xff0064fb));
    appearance.toggleDarkMode(true);
    expect(appearance.accent, const Color(0xffc19e32));
  });
  for (final admin in [false, true]) {
    testWidgets('appearance controls follow site administrator access=$admin', (
      tester,
    ) async {
      final auth = AuthSession()
        ..user = AuthUser(
          id: admin ? 1 : 30,
          username: 'fixture',
          fullName: 'Fixture',
        );
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthSession>.value(value: auth),
            ChangeNotifierProvider(create: (_) => LocaleProvider()),
          ],
          child: fixture.host(const SettingsPage()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(Slider), findsNWidgets(admin ? 3 : 1));
      expect(tester.takeException(), isNull);
    });
  }
}
