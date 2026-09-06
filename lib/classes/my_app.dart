import 'dart:ui';
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
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 600),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, animation) {
            return AnimatedBuilder(
              animation: animation,
              builder: (context, _) {
                final blurValue = (1 - animation.value) / 4;
                return ImageFiltered(
                  imageFilter: ImageFilter.blur(
                    sigmaX: blurValue,
                    sigmaY: blurValue,
                  ),
                  child: child,
                );
              },
            );
          },
          child: AnimatedTheme(
            key: ValueKey(
              '${localeProvider.locale.languageCode}-${appData.isDark}',
            ),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeInOut,
            data: appData.isDark
                ? darkTheme(appData)
                : lightTheme(appData),
            child: MaterialApp(
              navigatorKey: navigatorKey,
              debugShowCheckedModeBanner: false,
              title: AppStrings.application_fullname.translate(context),
              locale: localeProvider.locale,
              supportedLocales: const [
                Locale('en', ''),
                Locale('fa', ''),
              ],
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              theme: lightTheme(appData),
              darkTheme: darkTheme(appData),
              themeMode:
                  appData.isDark ? ThemeMode.dark : ThemeMode.light,
              home: const SplashScreen(),
              routes: {
                '/profile': (_) => const UserPanelPage(),
                '/home': (_) => const HomePage(),
                '/about': (_) => const AboutUsPage(),
                '/settings': (_) => const SettingsPage(),
                '/music_player': (_) => const MusicPlayerPage(),
              },
            ),
          ),
        );
      },
    );
  }

  ThemeData darkTheme(AppData appData) => ThemeData(fontFamily: appData.fontFamily);
  ThemeData lightTheme(AppData appData) => ThemeData(fontFamily: appData.fontFamily);
}
