// ignore_for_file: unnecessary_underscores

import 'package:flutter/material.dart';

/// متدی برای رفتن به صفحه با انیمیشن Fade (محو شدن)
void navigateWithFade(BuildContext context, Widget page) {
  Navigator.push(
    context,
    PageRouteBuilder(
      pageBuilder: (_, __, ___) => page,
      transitionDuration: const Duration(milliseconds: 250),
      transitionsBuilder: (_, animation, __, child) =>
          FadeTransition(opacity: animation, child: child),
    ),
  );
}


/*
Animation Change

transitionsBuilder: (_, animation, __, child) => SlideTransition(
  position: Tween<Offset>(
    begin: const Offset(1.0, 0.0), // از راست وارد شود
    end: Offset.zero,
  ).animate(animation),
  child: child,
),

*/