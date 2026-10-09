import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sornaz/helpers/app_data.dart';
import 'package:sornaz/components/app_logo.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sornaz/screens/Site/panel_api.dart';
import 'package:sornaz/screens/Site/panel_navigation.dart';
import 'package:sornaz/screens/Site/site_panel_page.dart';

http.Response reply(Object data) => http.Response(
  jsonEncode({
    'status': 200,
    'data': {'success': true, 'data': data},
  }),
  200,
);

void main() {
  test('panel navigation excludes the three top-bar destinations', () {
    final sections = panelNavigation([
      for (final key in ['notifications', 'messages', 'points', 'posts'])
        {'key': key, 'label': key},
    ]);
    expect(sections.map((section) => section['key']), ['posts']);
  });

  testWidgets('panel top bar shows authorized actions and unread badges', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final api = PanelApi(
      'token',
      client: MockClient((request) async {
        if (request.url.path.endsWith('/messages/list')) {
          return reply({
            'unread': {'messages': 2, 'notifications': 3},
          });
        }
        return reply({
          'sections': [
            for (final key in ['notifications', 'messages', 'points', 'posts'])
              {
                'key': key,
                'label': key,
                'en': key,
                'actions': {'list': {}},
              },
          ],
        });
      }),
    );
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppData(),
        child: MaterialApp(
          locale: const Locale('fa'),
          supportedLocales: const [Locale('fa'), Locale('en')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: NativePanel(token: 'token', api: api),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.notifications_none), findsOneWidget);
    expect(find.byIcon(Icons.mail_outline), findsOneWidget);
    expect(find.byType(SvgPicture), findsOneWidget);
    final searchX = tester.getCenter(find.byIcon(Icons.search)).dx;
    final notificationsX = tester
        .getCenter(find.byIcon(Icons.notifications_none))
        .dx;
    final messagesX = tester.getCenter(find.byIcon(Icons.mail_outline)).dx;
    final pointsX = tester.getCenter(find.byType(SvgPicture)).dx;
    expect(
      searchX > pointsX && pointsX > messagesX && messagesX > notificationsX,
      isTrue,
    );
    expect(find.byType(AppLogo), findsNothing);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('notifications'), findsNothing);
    expect(find.text('messages'), findsNothing);
    expect(find.text('points'), findsNothing);
    expect(find.text('posts'), findsOneWidget);
    api.dispose();
  });
}
