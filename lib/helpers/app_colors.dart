// ignore_for_file: constant_identifier_names

import 'package:flutter/material.dart';

class AppColors {
  static const Color clicked_light = Color.fromARGB(30, 31, 31, 31);
  static const Color hovered_light = Color.fromARGB(15, 31, 31, 31);
  static const Color border_light = Color.fromARGB(30, 31, 31, 31);
  static const Color primary_light = Color.fromARGB(255, 0, 100, 251);
  static const Color secondary_light = Color.fromARGB(255, 193, 158, 50);
  static const Color background_light = Color.fromARGB(255, 255, 255, 255);
  static const Color surface_light = Color.fromARGB(155, 241, 241, 241);
  static const Color shadow_light = Color.fromARGB(30, 241, 241, 241);
  static const Color text_primary_light = Color.fromARGB(255, 0, 0, 0);
  static const Color button_text_primary_light = Color.fromARGB(
    255,
    255,
    255,
    255,
  );
  static const Color text_secondary_light = Color.fromARGB(155, 31, 31, 31);
  static const Color unselected_item_light = Color.fromARGB(75, 31, 31, 31);

  static const Color clicked_dark = Color.fromARGB(30, 241, 241, 241);
  static const Color hovered_dark = Color.fromARGB(15, 241, 241, 241);
  static const Color border_dark = Color.fromARGB(30, 241, 241, 241);
  static const Color primary_dark = Color.fromARGB(255, 193, 158, 50);
  static const Color secondary_dark = Color.fromARGB(255, 0, 100, 251);
  static const Color background_dark = Color.fromARGB(255, 0, 0, 0);
  static const Color surface_dark = Color.fromARGB(255, 31, 31, 31);
  static const Color shadow_dark = Color.fromARGB(30, 31, 31, 31);
  static const Color text_primary_dark = Color.fromARGB(255, 255, 255, 255);
  static const Color button_text_primary_dark = Color.fromARGB(255, 0, 0, 0);
  static const Color text_secondary_dark = Color.fromARGB(155, 241, 241, 241);
  static const Color unselected_item_dark = Color.fromARGB(100, 241, 241, 241);

  static const Color error = Color.fromRGBO(244, 67, 54, 1);
  static const Color success = Color.fromRGBO(76, 175, 80, 1);
  static const Color warning = Color.fromRGBO(255, 152, 0, 1);
  static const Color info = Color.fromRGBO(75, 181, 246, 1);

  // static const MaterialColor primary_dark_material = Color.fromARGB(255, 193, 158, 50);

  static LinearGradient bottomGradient(bool isDark) {
    return LinearGradient(
      colors: isDark
          ? [background_light, background_light.withAlpha(100)]
          : [background_dark, background_dark.withAlpha(100)],
      begin: Alignment.bottomCenter,
      end: Alignment.center,
    );
  }

  /*
  static const MaterialColor blue = MaterialColor(_bluePrimaryValue, <int, Color>{
    50: Color(0xFFE3F2FD),
    100: Color(0xFFBBDEFB),
    200: Color(0xFF90CAF9),
    300: Color(0xFF64B5F6),
    400: Color(0xFF42A5F5),
    500: Color(_bluePrimaryValue),
    600: Color(0xFF1E88E5),
    700: Color(0xFF1976D2),
    800: Color(0xFF1565C0),
    900: Color(0xFF0D47A1),
  });
  static const int _bluePrimaryValue = 0xFF2196F3;
*/

  // static LinearGradient successGradient(bool isDark) {
  //   return LinearGradient(
  //     colors: isDark
  //         ? [successDark, successDark.withOpacity(0.7)]
  //         : [success, success.withOpacity(0.7)],
  //     begin: Alignment.topCenter,
  //     end: Alignment.bottomCenter,
  //   );
  // }

  // static BoxShadow defaultShadow(bool isDark) {
  //   return BoxShadow(
  //     color: isDark ? Colors.black.withAlpha(50) : Colors.grey.withAlpha(20),
  //     spreadRadius: 2,
  //     blurRadius: 8,
  //     offset: const Offset(0, 4),
  //   );
  // }

  // static BoxShadow elevatedShadow(bool isDark) {
  //   return BoxShadow(
  //     color: isDark
  //         ? Colors.black.withOpacity(0.7)
  //         : Colors.grey.withOpacity(0.3),
  //     spreadRadius: 4,
  //     blurRadius: 12,
  //     offset: const Offset(0, 6),
  //   );
  // }

  // static Color getPrimary(bool isDark) => isDark ? primaryDark : primary;
  // static Color getSecondary(bool isDark) => isDark ? secondaryDark : secondary;
  // static Color getBackground(bool isDark) =>
  // isDark ? backgroundDark : background;
  // static Color getSurface(bool isDark) => isDark ? surfaceDark : surface;
  // static Color getTextPrimary(bool isDark) =>
  //     isDark ? textPrimaryDark : textPrimary;
  // static Color getTextSecondary(bool isDark) =>
  // isDark ? textSecondaryDark : textSecondary;
  // static Color getError(bool isDark) => isDark ? errorDark : error;
  // static Color getSuccess(bool isDark) => isDark ? successDark : success;
  // static Color getWarning(bool isDark) => isDark ? warningDark : warning;
  // static Color getInfo(bool isDark) => isDark ? infoDark : info;

  // static Color withOpacity(Color color, double opacity) {
  //   return color.withOpacity(opacity.clamp(0.0, 1.0));
  // }

  // static ThemeData customTheme(bool isDark, Color customPrimary) {
  //   return ThemeData(
  //     primaryColor: customPrimary,
  //     brightness: isDark ? Brightness.dark : Brightness.light,
  //   );
  // }
}
