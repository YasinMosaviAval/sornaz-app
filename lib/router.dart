import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sornaz/helpers/app_typography.dart';
import 'package:sornaz/screens/home/home.dart';
import 'package:sornaz/screens/onboarding/splash.dart';
import 'package:sornaz/screens/others/about_us.dart';

final GoRouter router = GoRouter(
  initialLocation: '/notation',
  debugLogDiagnostics: true,
  errorBuilder: (context, state) => Scaffold(
    body: Center(
      child: Text(
        'Page not found: ${state.uri}',
        style: AppTypography.routerPageNotFound,
      ),
    ),
  ),
  /* format: off */
  routes: [
    GoRoute(
      path: '/splash',
      name: 'splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/home',
      name: 'home',
      builder: (context, state) => const HomePage(),
    ),
    GoRoute(
      path: '/about',
      name: 'about',
      builder: (context, state) => const AboutUsPage(),
    ),
  ],
  /* format: on */
);
