import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sornaz/helpers/app_data.dart';
import 'package:sornaz/helpers/app_locale_provider.dart';
import 'package:sornaz/screens/Authentication/providers/auth_session.dart';
import 'package:sornaz/screens/Others/ui/pages/support_pages.dart';
import 'package:sornaz/screens/Site/panel_section_card.dart';
import 'package:sornaz/screens/Site/panel_account.dart';
import 'package:sornaz/screens/Site/panel_gallery.dart';
import 'package:sornaz/screens/Site/panel_api.dart';
import 'package:sornaz/screens/Social/social_api.dart';
import 'social_widget_test.dart' as fixture;
import 'drawer_accounts_test.dart' as drawer;

class AccountFixture extends PanelApi {
  AccountFixture() : super('fixture');
  final writes = <(String, Json)>[];
  @override
  Future<Json> get(String path, [Map<String, String>? query]) async => {
    'url': 'https://sornaz.com/register?ref=TEST',
    'code': 'TEST',
    'invitedUsers': 3,
  };
  @override
  Future<Json> act(
    String section,
    String action, {
    Json values = const {},
    Map<String, String> params = const {},
    files = const {},
  }) async {
    writes.add((action, values));
    return {};
  }
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  testWidgets(
    'contact uses exact Persian and English strings and shared borders',
    (tester) async {
      final data = AppData(), session = AuthSession();
      await tester.pumpWidget(
        drawer.host(const ContactUsPage(), data, session),
      );
      await tester.pumpAndSettle();
      const note = 'بعد از مشاهده پیام، در اولین فرصت پاسخ شما را می‌دهیم.';
      expect(find.text(note), findsOneWidget);
      expect(find.text('ارتباط با ما — ارسال پیام جدید'), findsNothing);
      final fields = tester
          .widgetList<TextField>(find.byType(TextField))
          .toList();
      expect(fields[2].decoration!.hintText, 'موضوع پیام خود را انتخاب کنید');
      expect(fields[3].decoration!.hintText, 'متن پیام خود را بنویسید...');
      final decoration = fields[2].decoration!;
      expect(decoration.enabledBorder!.borderSide.color, Colors.grey);
      expect(decoration.disabledBorder!.borderSide.color, Colors.grey);
      expect(
        decoration.focusedBorder!.borderSide.color,
        Theme.of(
          tester.element(find.byType(TextField).first),
        ).colorScheme.primary,
      );
      final context = tester.element(find.byType(ContactUsPage));
      context.read<LocaleProvider>().setLocale('en');
      await tester.pumpAndSettle();
      expect(find.text(note), findsNothing);
      expect(
        find.text(
          'We will reply as soon as possible after reviewing your message.',
        ),
        findsOneWidget,
      );
      context.read<LocaleProvider>().setLocale('fa');
      await tester.pumpAndSettle();
      expect(find.text(note), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('section body toggles and collapsed state survives long scroll', (
    tester,
  ) async {
    await tester.pumpWidget(
      fixture.host(
        Scaffold(
          body: ListView(
            children: [
              const PanelSectionCard(
                storageId: 'test',
                title: 'توضیحات',
                children: [
                  Padding(
                    padding: EdgeInsets.all(30),
                    child: Text('متن راهنما'),
                  ),
                ],
              ),
              for (var i = 0; i < 150; i++)
                SizedBox(height: 60, child: Text('row $i')),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('متن راهنما'));
    await tester.pumpAndSettle();
    expect(find.text('متن راهنما').hitTestable(), findsNothing);
    final scroll = tester.state<ScrollableState>(find.byType(Scrollable).first);
    scroll.position.jumpTo(6500);
    await tester.pumpAndSettle();
    scroll.position.jumpTo(0);
    await tester.pumpAndSettle();
    expect(find.text('متن راهنما').hitTestable(), findsNothing);
    await tester.tap(find.text('توضیحات'));
    await tester.pumpAndSettle();
    expect(find.text('متن راهنما').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  for (final type in ['human', 'academy', 'branch']) {
    testWidgets(
      'account website sections and privacy are scoped for $type at 320dp',
      (tester) async {
        tester.view.physicalSize = const Size(320, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final api = AccountFixture();
        addTearDown(api.dispose);
        await tester.pumpWidget(
          fixture.host(
            Scaffold(
              body: SingleChildScrollView(
                child: PanelAccount(
                  api: api,
                  data: {
                    'profile': {
                      'accountType': type,
                      'name': 'کاربر نمونه',
                      'privacy': {'showPublicProfile': true},
                    },
                    'documents': [
                      {'id': 4, 'title': 'مدرک'},
                    ],
                    'merges': {'eligible': true, 'requests': []},
                  },
                  actions: {
                    for (final key in [
                      'invite',
                      'privacy',
                      'security',
                      'profile',
                      'bio',
                      'avatar',
                      'cover',
                      'document',
                      'delete-media',
                      'download-media',
                      'merge',
                    ])
                      key: {},
                  },
                  onAction: (_, row) async {},
                  onChanged: () async {},
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('اطلاعات اصلی'), findsOneWidget);
        expect(find.text('معرفی و بیوگرافی'), findsOneWidget);
        expect(find.text('لینک دعوت من'), findsOneWidget);
        expect(
          find.text('اتصال سوابق عضویت به حساب من'),
          type == 'human' ? findsOneWidget : findsNothing,
        );
        expect(
          find.text('نمایش لیست شعبه‌ها در صفحه عمومی'),
          type == 'academy' ? findsOneWidget : findsNothing,
        );
        expect(
          find.text('نمایش اساتید در صفحه عمومی'),
          type == 'human' ? findsNothing : findsOneWidget,
        );
        expect(find.text('accountType'), findsNothing);
        final privacySection = find.text('حریم خصوصی و نمایش عمومی');
        await tester.ensureVisible(privacySection);
        await tester.tap(privacySection);
        await tester.pumpAndSettle();
        final save = find.text('ذخیره تنظیمات حریم خصوصی');
        await tester.ensureVisible(save);
        await tester.tap(save);
        await tester.pumpAndSettle();
        expect(api.writes.single.$1, 'privacy');
        expect(api.writes.single.$2['showPublicProfile'], true);
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets(
    'gallery groups website categories, toggles details and opens a dialog viewer',
    (tester) async {
      final api = AccountFixture();
      addTearDown(api.dispose);
      await tester.pumpWidget(
        fixture.host(
          Scaffold(
            body: SingleChildScrollView(
              child: PanelGallery(
                api: api,
                rows: [
                  for (final entry in [
                    ('cover', 'کاور تست'),
                    ('cover', 'کاور دوم'),
                    ('gallery', 'عکس تست'),
                  ])
                    {
                      'id': entry.$2,
                      'category': entry.$1,
                      'title': entry.$2,
                      'url': '',
                      'type': 'image',
                      'ownerName': 'آموزشگاه',
                      'summary': 'خلاصه رسانه',
                      'description': 'شرح رسانه',
                    },
                ],
                fields: const [],
                data: const {},
                canEdit: false,
                onChanged: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('کاور'), findsOneWidget);
      expect(find.text('لوگو'), findsOneWidget);
      expect(find.text('خلاصه رسانه'), findsNothing);
      await tester.tap(find.text('توضیحات'));
      await tester.pumpAndSettle();
      expect(find.text('خلاصه رسانه'), findsNWidgets(3));
      await tester.tap(find.byType(GalleryPreview).first);
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsOneWidget);
      await tester.tap(find.byIcon(Icons.chevron_right));
      await tester.pumpAndSettle();
      expect(find.text('کاور دوم'), findsNWidgets(2));
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'account contact changes verify ownership before committing and saving security',
    (tester) async {
      final api = AccountFixture();
      addTearDown(api.dispose);
      await tester.pumpWidget(
        fixture.host(
          Scaffold(
            body: SingleChildScrollView(
              child: PanelAccount(
                api: api,
                area: 'security',
                data: const {
                  'profile': {
                    'accountType': 'human',
                    'email': 'old@example.com',
                    'phone': '',
                  },
                },
                actions: const {
                  'security': {},
                  'contact-send': {},
                  'contact-verify': {},
                  'contact-commit': {},
                },
                onAction: (_, row) async {},
                onChanged: () async {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final securitySection = find.text('تنظیمات امنیتی حساب');
      await tester.ensureVisible(securitySection);
      await tester.tap(securitySection);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('account-email')),
        'new@example.com',
      );
      await tester.enterText(
        find.byKey(const ValueKey('account-password')),
        'newpassword',
      );
      await tester.enterText(
        find.byKey(const ValueKey('account-passwordConfirmation')),
        'newpassword',
      );
      await tester.tap(find.text('ذخیره تغییرات'));
      await tester.pumpAndSettle();
      expect(api.writes.single.$1, 'contact-send');
      expect(api.writes.single.$2, {
        'field': 'email',
        'destination': 'new@example.com',
      });
      await tester.enterText(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byType(TextField),
        ),
        '123456',
      );
      await tester.tap(find.text('تأیید'));
      await tester.pumpAndSettle();
      expect(api.writes.map((e) => e.$1).toList(), [
        'contact-send',
        'contact-verify',
        'contact-commit',
        'security',
      ]);
      expect(api.writes[1].$2['code'], '123456');
      expect(api.writes.last.$2['password'], 'newpassword');
      expect(tester.takeException(), isNull);
    },
  );
}
