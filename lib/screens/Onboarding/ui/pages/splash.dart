import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sornaz/helpers/app_colors.dart';
import 'package:sornaz/helpers/app_data.dart';
import 'package:sornaz/helpers/app_images.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sornaz/screens/Authentication/ui/pages/authentication.dart';
import 'package:sornaz/screens/Authentication/providers/auth_session.dart';
import 'package:sornaz/screens/Home/ui/pages/home.dart';
import 'package:sornaz/screens/Onboarding/ui/pages/onboarding.dart';
import 'package:sornaz/screens/Onboarding/ui/pages/startup_preferences.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 1), _continueToApp);
  }

  Future<void> _continueToApp() async {
    final preferences = await SharedPreferences.getInstance();
    final onboardingCompleted =
        preferences.getBool(OnboardingScreen.completedPreferenceKey) ?? false;
    if (!mounted) return;
    final authenticated =
        context.read<AuthSession?>()?.isAuthenticated ?? false;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => !onboardingCompleted
            ? const StartupPreferencesScreen()
            : authenticated
            ? const HomePage()
            : const SignInScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appData = Provider.of<AppData>(context);
    final isDark = appData.isDark;
    return Scaffold(
      backgroundColor: AppColors.splash_background_color(isDark: isDark),
      body: Center(
        child: Image.asset(
          isDark ? AppImages.logo_dark : AppImages.logo_light,
          fit: BoxFit.contain,
          width: 90,
          height: 154,
        ),
      ),
    );
  }
}
