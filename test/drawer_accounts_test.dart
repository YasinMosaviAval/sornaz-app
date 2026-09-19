import 'dart:io';
import 'package:sornaz/helpers/app_images.dart';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:sornaz/screens/Others/ui/pages/about_us.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sornaz/helpers/app_data.dart';
import 'package:sornaz/helpers/app_locale_provider.dart';
import 'package:sornaz/screens/Authentication/providers/auth_session.dart';
import 'package:sornaz/screens/Authentication/models/auth_user.dart';
import 'package:sornaz/screens/Authentication/services/auth_api_service.dart';
import 'package:sornaz/screens/Home/ui/components/app_drawer.dart';
import 'package:sornaz/screens/Others/ui/pages/support_pages.dart';
import 'package:sornaz/screens/Others/ui/pages/share_app.dart';
import 'package:sornaz/components/settings_section_header.dart';

AuthResult account(int id) => AuthResult(
  token: 'token-$id',
  user: AuthUser(
    id: id,
    username: 'user$id',
    fullName: 'کاربر $id',
    email: 'user$id@example.com',
  ),
);
Widget host(Widget child, AppData data, AuthSession session) => MultiProvider(
  providers: [
    ChangeNotifierProvider.value(value: data),
    ChangeNotifierProvider.value(value: session),
    ChangeNotifierProvider(create: (_) => LocaleProvider()),
  ],
  child: MaterialApp(
    locale: const Locale('fa'),
    supportedLocales: const [Locale('fa')],
    localizationsDelegates: const [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: child,
  ),
);

double textSize(WidgetTester tester, String label) {
  final element = tester.element(find.text(label).first);
  final widget = element.widget as Text;
  return widget.style?.fontSize ?? DefaultTextStyle.of(element).style.fontSize!;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test(
    'migrates legacy session and preserves both accounts across restart and logout',
    () async {
      SharedPreferences.setMockInitialValues({
        'auth_token': 'token-1',
        'auth_user': jsonEncode(account(1).user.toJson()),
      });
      final session = AuthSession();
      await session.restore();
      await session.save(account(2));
      expect(session.accounts.length, 2);
      await session.switchTo(1);
      expect(session.token, 'token-1');
      final restored = AuthSession();
      await restored.restore();
      expect(restored.user!.id, 1);
      expect(restored.accounts.length, 2);
      await restored.clear();
      expect(restored.user!.id, 2);
      expect(restored.token, 'token-2');
      final finalSession = AuthSession();
      await finalSession.restore();
      expect(finalSession.accounts.map((u) => u.id), [2]);
      await finalSession.clear();
      expect(finalSession.isAuthenticated, false);
    },
  );
  test(
    'repeat login updates token without duplicating account; malformed entries are skipped',
    () async {
      SharedPreferences.setMockInitialValues({
        'auth_accounts_v1': jsonEncode([
          {'bad': true},
          {'user': account(1).user.toJson(), 'token': 'old'},
        ]),
      });
      final session = AuthSession();
      await session.restore();
      await session.save(account(1));
      expect(session.accounts.length, 1);
      expect(session.token, 'token-1');
    },
  );
  for (final dark in [false, true]) {
    testWidgets('drawer is scrollable and font reactive in dark=$dark', (
      tester,
    ) async {
      tester.view.resetPhysicalSize();
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final data = AppData()..toggleDarkMode(dark), session = AuthSession();
      await session.save(account(1));
      await tester.pumpWidget(
        host(const Scaffold(body: AppDrawer()), data, session),
      );
      await tester.pumpAndSettle();
      expect(find.text('پنل کاربری و پروفایل'), findsNothing);
      expect(find.text('ارسال بازخورد'), findsNothing);
      final themeSize = textSize(tester, 'درباره ما'),
          shareSize = textSize(tester, 'اشتراک‌گذاری برنامه');
      await data.updateFontSize(2);
      await tester.pumpAndSettle();
      expect(textSize(tester, 'درباره ما'), themeSize + 2);
      expect(textSize(tester, 'اشتراک‌گذاری برنامه'), shareSize + 2);
      await tester.ensureVisible(find.text('ورود با حساب دیگر'));
      await tester.tap(find.text('ورود با حساب دیگر'));
      await tester.pumpAndSettle();
      expect(find.text('حساب‌های کاربری'), findsOneWidget);
      expect(find.text('افزودن حساب کاربری'), findsOneWidget);
      expect(session.user!.id, 1);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets(
    'contact fills remaining height with equal send-button gaps and survives keyboard',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetViewInsets);
      final data = AppData(), session = AuthSession();
      await session.save(account(1));
      await tester.pumpWidget(host(const ContactUsPage(), data, session));
      await tester.pumpAndSettle();
      final box = tester.getRect(find.byKey(const Key('contact-message'))),
          button = tester.getRect(find.byKey(const Key('contact-send')));
      expect(box.height, greaterThan(400));
      expect(button.top - box.bottom, 20);
      expect(844 - button.bottom, 20);
      final before = textSize(tester, 'ارسال پیام');
      await data.updateFontSize(2);
      await tester.pumpAndSettle();
      expect(textSize(tester, 'ارسال پیام'), before + 2);
      tester.view.viewInsets = const FakeViewPadding(bottom: 320);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('contact-send')));
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('FAQ uses About Us accordions and toggles answers', (
    tester,
  ) async {
    await tester.pumpWidget(host(const FaqPage(), AppData(), AuthSession()));
    await tester.pumpAndSettle();
    expect(find.byType(SettingsSectionHeader), findsNWidgets(3));
    await tester.tap(find.text(FaqPage.items.first.$1));
    await tester.pumpAndSettle();
    expect(find.text(FaqPage.items.first.$2).hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'share page contains five links and calls native APK sharesheet',
    (tester) async {
      final calls = <MethodCall>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('sornaz/app_share'),
        (call) async {
          calls.add(call);
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          const MethodChannel('sornaz/app_share'),
          null,
        ),
      );
      await tester.pumpWidget(
        host(const ShareAppPage(), AppData(), AuthSession()),
      );
      await tester.pumpAndSettle();
      expect(find.byType(SocialLinkTile), findsNWidgets(5));
      await tester.ensureVisible(find.text('ارسال فایل نصبی برنامه'));
      await tester.tap(find.text('ارسال فایل نصبی برنامه'));
      await tester.pumpAndSettle();
      expect(calls.single.method, 'shareApk');
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'drawer pages render with real fonts at narrow widths and save previews',
    (tester) async {
      final fonts = FontLoader('iran_sansx_fa')
        ..addFont(rootBundle.load('assets/fonts/iran_sansx_fa/regular.ttf'));
      await fonts.load();
      final icons = FontLoader('MaterialIcons')
        ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
      await icons.load();
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      for (final dark in [false, true]) {
        final data = AppData()..toggleDarkMode(dark);
        await data.updateFontSize(2);
        final session = AuthSession();
        await session.save(account(1));
        tester.view.physicalSize = const Size(375, 844);
        for (final page in <(String, Widget)>[
          ('drawer', const Scaffold(body: AppDrawer())),
          ('contact', const ContactUsPage()),
          ('share', const ShareAppPage()),
          ('faq', const FaqPage()),
          ('about', const AboutUsPage()),
        ]) {
          final key = GlobalKey();
          await tester.pumpWidget(
            host(RepaintBoundary(key: key, child: page.$2), data, session),
          );
          await tester.pumpAndSettle();
          await tester.runAsync(() async {
            final context = key.currentContext!;
            await precacheImage(
              AssetImage(dark ? AppImages.logo_dark : AppImages.logo_light),
              context,
            );
          });
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: page.$1);
          await tester.runAsync(() async {
            final image =
                await (key.currentContext!.findRenderObject()!
                        as RenderRepaintBoundary)
                    .toImage();
            final bytes = await image.toByteData(
              format: ui.ImageByteFormat.png,
            );
            await Directory('build/drawer-previews').create(recursive: true);
            await File(
              'build/drawer-previews/${page.$1}-${dark ? 'dark' : 'light'}.png',
            ).writeAsBytes(bytes!.buffer.asUint8List());
            image.dispose();
          });
          await tester.pumpWidget(const SizedBox());
        }
      }
    },
  );
}
