import 'package:sornaz/screens/Social/social_api.dart';
import 'package:sornaz/helpers/app_colors.dart';
import 'package:sornaz/screens/Social/user_panel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sornaz/helpers/app_data.dart';
import 'package:sornaz/helpers/app_locale_provider.dart';
import 'package:sornaz/helpers/app_strings.dart';
import 'package:sornaz/helpers/app_translations.dart';
import 'package:sornaz/main.dart';
import 'package:sornaz/screens/Home/ui/pages/home.dart';
import 'package:sornaz/screens/Onboarding/ui/pages/splash.dart';
import 'package:sornaz/screens/Others/ui/pages/about_us.dart';
import 'package:sornaz/screens/Others/ui/pages/settings.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:sornaz/screens/Players/ui/pages/music_palyer.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return Consumer2<LocaleProvider, AppData>(
      builder: (context, localeProvider, appData, _) {
        SocialApi.locale = localeProvider.locale.languageCode;
        return MaterialApp(
          navigatorKey: navigatorKey,
          debugShowCheckedModeBanner: false,
          title: AppStrings.application_fullname.translate(context),
          locale: localeProvider.locale,
          supportedLocales: const [Locale('en', ''), Locale('fa', '')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: lightTheme(appData),
          darkTheme: darkTheme(appData),
          themeMode: appData.isDark ? ThemeMode.dark : ThemeMode.light,
          builder: (context, child) {
            final media = MediaQuery.of(context);
            final scale =
                media.textScaler.scale(1) * (1 + appData.fontSize / 16);
            return MediaQuery(
              data: media.copyWith(textScaler: TextScaler.linear(scale)),
              child: child ?? const SizedBox.shrink(),
            );
          },
          home: const SplashScreen(),
          routes: {
            '/profile': (_) => const UserPanelPage(),
            '/home': (_) => const HomePage(),
            '/about': (_) => const AboutUsPage(),
            '/settings': (_) => const SettingsPage(),
            '/music_player': (_) => const MusicPlayerPage(),
          },
        );
      },
    );
  }

  ThemeData darkTheme(AppData appData) => _theme(appData, true);
  ThemeData lightTheme(AppData appData) => _theme(appData, false);

  ThemeData _theme(AppData appData, bool dark) {
    final background = dark
        ? AppColors.background_dark
        : AppColors.background_light;
    final surface = dark ? const Color(0xff171717) : const Color(0xfff6f6f6);
    final foreground = dark ? Colors.white : Colors.black;
    final accent = dark ? AppColors.primary_dark : AppColors.primary_light;
    final scheme =
        ColorScheme.fromSeed(
          seedColor: accent,
          brightness: dark ? Brightness.dark : Brightness.light,
        ).copyWith(
          primary: accent,
          onPrimary: dark ? Colors.black : Colors.white,
          surface: surface,
          onSurface: foreground,
        );
    final radius = BorderRadius.circular(appData.cornerRadius);
    final shape = RoundedRectangleBorder(borderRadius: radius);
    final baseText =
        ThemeData(
          brightness: scheme.brightness,
          fontFamily: appData.fontFamily,
        ).textTheme.apply(
          fontFamily: appData.fontFamily,
          fontSizeDelta: appData.fontSize,
        );
    TextStyle? weighted(TextStyle? style) =>
        style?.apply(fontWeightDelta: appData.fontWeight.round());
    final textTheme = baseText.copyWith(
      displayLarge: weighted(baseText.displayLarge),
      displayMedium: weighted(baseText.displayMedium),
      displaySmall: weighted(baseText.displaySmall),
      headlineLarge: weighted(baseText.headlineLarge),
      headlineMedium: weighted(baseText.headlineMedium),
      headlineSmall: weighted(baseText.headlineSmall),
      titleLarge: weighted(baseText.titleLarge),
      titleMedium: weighted(baseText.titleMedium),
      titleSmall: weighted(baseText.titleSmall),
      bodyLarge: weighted(baseText.bodyLarge),
      bodyMedium: weighted(baseText.bodyMedium),
      bodySmall: weighted(baseText.bodySmall),
      labelLarge: weighted(baseText.labelLarge),
      labelMedium: weighted(baseText.labelMedium),
      labelSmall: weighted(baseText.labelSmall),
    );
    return ThemeData(
      brightness: scheme.brightness,
      fontFamily: appData.fontFamily,
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      cardTheme: CardThemeData(
        color: surface,
        surfaceTintColor: Colors.transparent,
        shape: shape,
      ),
      dialogTheme: DialogThemeData(shape: shape),
      popupMenuTheme: PopupMenuThemeData(shape: shape),
      bottomSheetTheme: BottomSheetThemeData(shape: shape),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(shape: shape),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(shape: shape),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(shape: shape),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(shape: shape),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: radius),
        enabledBorder: OutlineInputBorder(borderRadius: radius),
        focusedBorder: OutlineInputBorder(borderRadius: radius),
      ),
      appBarTheme: AppBarTheme(
        toolbarHeight: 48,
        backgroundColor: background,
        foregroundColor: foreground,
      ),
      dividerColor: dark ? const Color(0xff333333) : const Color(0xffdddddd),
    );
  }
}
