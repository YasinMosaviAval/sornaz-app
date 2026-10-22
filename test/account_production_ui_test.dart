import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sornaz/components/main_tabs.dart';
import 'package:sornaz/screens/Authentication/models/auth_user.dart';
import 'package:sornaz/screens/Authentication/providers/auth_session.dart';
import 'package:sornaz/screens/Home/ui/pages/music_tools.dart';
import 'package:sornaz/screens/Site/panel_api.dart';
import 'package:sornaz/screens/Site/panel_form.dart';
import 'package:sornaz/screens/Social/social_api.dart';
import 'package:sornaz/screens/Social/social_learning.dart';
import 'social_widget_test.dart' as fixture;
import 'native_panel_test.dart' show reply;

const releaseUi = bool.fromEnvironment('RELEASE_UI');

class AccountUiApi extends PanelApi {
  AccountUiApi() : super('token');
  bool failSave = false;
  Json? savedPayload;
  @override
  Future<Json> get(String path, [Map<String, String>? query]) async =>
      path.isEmpty
      ? {
          'sections': [
            {
              'key': 'account',
              'rows': 'profile',
              'actions': {
                'list': {'row': false},
                'privacy': {
                  'fields': [
                    {
                      'key': 'showPublicProfile',
                      'label': 'نمایش عمومی',
                      'type': 'bool',
                    },
                  ],
                },
                'security': {
                  'fields': [
                    {
                      'key': 'password',
                      'label': 'رمز جدید',
                      'type': 'password',
                      'required': true,
                    },
                    {
                      'key': 'passwordConfirmation',
                      'label': 'تکرار رمز',
                      'type': 'password',
                      'required': true,
                    },
                  ],
                },
                'merge': {
                  'label': 'درخواست ادغام',
                  'method': 'POST',
                  'row': false,
                  'fields': [],
                },
              },
            },
          ],
        }
      : {
          'profile': {
            'accountType': 'human',
            'privacy': {'showPublicProfile': true},
          },
          'merges': {'eligible': true, 'requests': []},
        };
  @override
  Future<Json> refresh(String path, [Map<String, String>? query]) =>
      get(path, query);
  @override
  Future<Json> act(
    String section,
    String action, {
    Json values = const {},
    Map<String, String> params = const {},
    Map<String, PlatformFile> files = const {},
  }) async {
    if (failSave) throw const SocialException('آزمون خطای ثبت');
    savedPayload = {'action': action, ...values};
    return {};
  }
}

AuthSession session(int id) => AuthSession()
  ..token = 'token'
  ..user = AuthUser(id: id, username: 'member', fullName: 'Member');
Widget host(AuthSession auth, Widget child) => ChangeNotifierProvider.value(
  value: auth,
  child: fixture.host(Scaffold(body: child)),
);
SocialApi social() => SocialApi(
  'token',
  client: MockClient(
    (request) async => reply({
      'profile': {
        'id': 2,
        'name': 'Member',
        'username': 'member',
        'type': 'human',
      },
      'courses': [],
      'completed_lessons': 0,
    }),
  ),
);
void wide(WidgetTester tester) {
  tester.view.physicalSize = const Size(1000, 3000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  for (final id in [2, 1]) {
    testWidgets('account preview sections follow the audience for $id', (
      tester,
    ) async {
      wide(tester);
      final api = social(), panel = AccountUiApi(), auth = session(id);
      addTearDown(api.dispose);
      addTearDown(panel.dispose);
      addTearDown(auth.dispose);
      await tester.pumpWidget(
        host(auth, AccountDashboardBody(api: api, accountApi: panel)),
      );
      await tester.pumpAndSettle();
      final restricted = releaseUi || id != 1;
      for (final label in ['ذخیره‌شده‌ها', 'دانلودها', 'تنظیمات اعلان'])
        expect(find.text(label), restricted ? findsNothing : findsOneWidget);
      expect(find.text('درخواست ادغام حساب'), restricted ? findsOneWidget : findsNothing);
      expect(find.text('درخواست‌های ادغام'), findsNothing);
      if (restricted) {
        expect(find.text('درخواست‌های ادغام'), findsNothing);
        for (final label in [
          'پیشرفت یادگیری',
          'دوره‌های تکمیل‌شده',
          'دستاوردها',
          'ساخت و مدیریت دوره',
        ])
          expect(find.text(label), findsNothing);
      }
      expect(tester.takeException(), isNull);
    });
    testWidgets('music tools audience for $id', (tester) async {
      wide(tester);
      final auth = session(id);
      addTearDown(auth.dispose);
      await tester.pumpWidget(
        host(
          auth,
          MainTabsScope(
            index: 3,
            select: (_) {},
            setEditorOpen: (_) {},
            setChrome: (_, bar) {},
            child: const MusicToolsPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final restricted = releaseUi || id != 1;
      for (final label in ['نت‌نویسی', 'تمرین سولفژ'])
        expect(find.text(label), restricted ? findsNothing : findsOneWidget);
      expect(find.text('پخش موسیقی'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets(
    'password footer uses theme and retains values after a failed save',
    (tester) async {
      wide(tester);
      final api = social(), panel = AccountUiApi(), auth = session(2);
      addTearDown(api.dispose);
      addTearDown(panel.dispose);
      addTearDown(auth.dispose);
      await tester.pumpWidget(
        host(auth, AccountDashboardBody(api: api, accountApi: panel)),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('تغییر رمز عبور'));
      await tester.pumpAndSettle();
      expect(find.byType(PanelFormPage), findsOneWidget);
      expect(find.byIcon(Icons.save_outlined), findsNothing);
      final button = find.widgetWithText(FilledButton, 'تغییر رمز');
      expect(button, findsOneWidget);
      final theme = Theme.of(tester.element(button)),
          style = tester.widget<FilledButton>(button).style!;
      expect(style.backgroundColor!.resolve({}), theme.colorScheme.primary);
      expect(style.foregroundColor!.resolve({}), theme.colorScheme.onPrimary);
      await tester.enterText(
        find.byType(TextFormField).at(0),
        'example-secret',
      );
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'example-secret',
      );
      panel.failSave = true;
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(find.byType(PanelFormPage), findsOneWidget);
      expect(
        tester
            .widget<TextFormField>(find.byType(TextFormField).first)
            .controller!
            .text,
        'example-secret',
      );
      ScaffoldMessenger.of(
        tester.element(find.byType(PanelFormPage)),
      ).clearSnackBars();
      await tester.pumpAndSettle();
      panel.failSave = false;
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(panel.savedPayload?['password'], 'example-secret');
    },
  );
  testWidgets('privacy footer saves checkbox changes', (tester) async {
    wide(tester);
    final api = social(), panel = AccountUiApi(), auth = session(2);
    addTearDown(api.dispose);
    addTearDown(panel.dispose);
    addTearDown(auth.dispose);
    await tester.pumpWidget(
      host(auth, AccountDashboardBody(api: api, accountApi: panel)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('حریم خصوصی'));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.save_outlined), findsNothing);
    await tester.tap(find.byType(CheckboxListTile));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ذخیره تغییرات'));
    await tester.pumpAndSettle();
    expect(panel.savedPayload?['showPublicProfile'], false);
  });
}
