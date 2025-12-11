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
    // final GoRouter router = GoRouter(
    //   routes: [GoRoute(path: '/', builder: (context, state) => HomePage())],
    // );

    // MaterialApp.router(routerConfig: router);

    return Consumer2<LocaleProvider, AppData>(
      builder: (context, localeProvider, appData, child) {
        // final GoRouter router = GoRouter(
        //   routes: [
        //     GoRoute(
        //       path: '/',
        //       builder: (context, state) => const SplashScreen(),
        //     ),
        //     GoRoute(
        //       path: '/home',
        //       builder: (context, state) => const HomePage(),
        //     ),
        //     GoRoute(
        //       path: '/settings',
        //       builder: (context, state) => const SettingsPage(),
        //     ),
        //     GoRoute(
        //       path: '/about',
        //       builder: (context, state) => const AboutUsPage(),
        //     ),
        //     GoRoute(
        //       path: '/music_player',
        //       builder: (context, state) => const MusicPlayerPage(),
        //     ),
        //   ],
        // );
        return MaterialApp(
          navigatorKey: navigatorKey,
          // routerConfig: router,
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
      // primarySwatch: Colors.yellow,
      // secondaryHeaderColor: AppColors.secondary_dark,
      // brightness: Brightness.dark,
      // scaffoldBackgroundColor: AppColors.background_dark,
      // cardColor: AppColors.background_dark,
      fontFamily: appData.fontFamily,
    );
  }

  ThemeData lightTheme(AppData appData) {
    return ThemeData(
      // primarySwatch: Colors.blue,
      // secondaryHeaderColor: AppColors.secondary_light,
      // brightness: Brightness.light,
      // scaffoldBackgroundColor: AppColors.background_light,
      // cardColor: AppColors.background_light,
      fontFamily: appData.fontFamily,
    );
  }
}
