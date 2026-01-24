import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sornaz/helpers/app_colors.dart';
import 'package:sornaz/helpers/app_data.dart';
import 'package:sornaz/helpers/app_images.dart';
import 'package:sornaz/helpers/app_spacing.dart';
import 'dart:async';

import 'package:sornaz/screens/Articles/ui/pages/articles_page.dart';


class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 2), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const ArticlesPage()),
      );
    });
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
          width: AppSpacing.space_300,
          height: AppSpacing.space_300,
        ),
      ),
    );
  }
}
