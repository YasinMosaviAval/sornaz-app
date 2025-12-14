import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sornaz/helpers/app_data.dart';
import 'package:sornaz/helpers/app_locale_provider.dart';
import 'package:sornaz/helpers/app_strings.dart';
import 'package:sornaz/helpers/app_translations.dart';
import 'package:sornaz/main.dart';
import 'package:sornaz/screens/Onboarding/splash.dart';
import 'package:sornaz/screens/Others/about_us.dart';
import 'package:sornaz/screens/Others/settings.dart';
import 'package:sornaz/screens/Players/music_palyer.dart';
import 'package:sornaz/screens/home/home.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return Consumer2<LocaleProvider, AppData>(
      builder: (context, localeProvider, appData, child) {
        return MaterialApp(
          navigatorKey: navigatorKey,
          debugShowCheckedModeBanner: false,
          title: AppStrings.application_fullname.translate(context),
          locale: localeProvider.locale,
          supportedLocales: const [Locale('en', ''), Locale('fa', '')],
          localeResolutionCallback: (deviceLocale, supportedLocales) {
            return localeProvider.locale;
          },
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: lightTheme(appData),
          darkTheme: darkTheme(appData),
          themeMode: appData.isDark ? ThemeMode.dark : ThemeMode.light,
          home: const SplashScreen(),
          routes: {
            '/home': (_) => const HomePage(),
            '/about': (_) => const AboutUsPage(),
            '/settings': (_) => const SettingsPage(),
            '/music_player': (_) => const MusicPlayerPage(),
          },
        );
      },
    );
  }

  ThemeData darkTheme(AppData appData) {
    return ThemeData(
      fontFamily: appData.fontFamily,
    );
  }

  ThemeData lightTheme(AppData appData) {
    return ThemeData(
      fontFamily: appData.fontFamily,
    );
  }
}

// ==