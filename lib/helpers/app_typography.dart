// ignore_for_file: constant_identifier_names

import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:provider/provider.dart';
import 'package:sornaz/helpers/app_colors.dart';
import 'package:sornaz/helpers/app_data.dart';
// import 'package:provider/provider.dart';
// import 'package:sornaz/helpers/app_data.dart';

/*
/// ----------------------------
/// FONT FAMILY LIST
/// ----------------------------
class AppFonts {
  static const String defaultFont = iran_sansx_fn;

  static const String iran_sansx_fn = 'iran_sansx_fn';
  static const String iran_sansx = 'iran_sansx';
  static const String iran_yekan_fn = 'iran_yekan_fn';
  static const String iran_yekan = 'iran_yekan';
  static const String kalameh_fn = 'kalameh_fn';
  static const String kalameh = 'kalameh';
  static const String peyda = 'peyda';
  static const String tahrir = 'tahrir';
  static const String sahel_fn = 'sahel_fn';
  static const String sahel = 'sahel';
  static const String vazir_fn = 'vazir_fn';
  static const String vazir = 'vazir';

  /// 🟦 لیست فونت‌ها برای دراپ‌داون
  static const List<String> allFonts = [
    iran_sansx_fn,
    iran_sansx,
    iran_yekan_fn,
    iran_yekan,
    kalameh_fn,
    kalameh,
    peyda,
    tahrir,
    sahel_fn,
    sahel,
    vazir_fn,
    vazir,
  ];
}

/// --------------------------------------------------------
///  DYNAMIC TYPOGRAPHY SYSTEM
/// --------------------------------------------------------
class AppTypography {
  /// گرفتن فونت انتخاب شده از Provider
  static String getFontFamily(BuildContext context) {
    return context.watch<AppData>().selectedFontFamily;
  }

  /// گرفتن سایز متنی انتخاب شده
  static double scale(BuildContext context) {
    return context.watch<AppData>().textSize / 16; // نسبت‌دهی
  }

  /// رنگ داینامیک
  static Color primaryColor(BuildContext context) {
    final isDark = context.watch<AppData>().isDark;
    return isDark ? AppColors.text_primary_dark : AppColors.text_primary_light;
  }

  static Color secondaryColor(BuildContext context) {
    final isDark = context.watch<AppData>().isDark;
    return isDark ? AppColors.text_secondary_dark : AppColors.text_secondary_light;
  }

  /// --------------------
  /// HEADLINES
  /// --------------------

  static TextStyle headline1(BuildContext context) => TextStyle(
        fontFamily: getFontFamily(context),
        color: primaryColor(context),
        fontSize: 32 * scale(context),
        fontWeight: FontWeight.w900,
      );

  static TextStyle headline2(BuildContext context) => TextStyle(
        fontFamily: getFontFamily(context),
        color: primaryColor(context),
        fontSize: 28 * scale(context),
        fontWeight: FontWeight.w800,
      );

  static TextStyle headline3(BuildContext context) => TextStyle(
        fontFamily: getFontFamily(context),
        color: primaryColor(context),
        fontSize: 24 * scale(context),
        fontWeight: FontWeight.w700,
      );

  static TextStyle headline4(BuildContext context) => TextStyle(
        fontFamily: getFontFamily(context),
        color: primaryColor(context),
        fontSize: 20 * scale(context),
        fontWeight: FontWeight.w600,
      );

  /// --------------------
  /// BODY TEXT
  /// --------------------

  static TextStyle body1(BuildContext context) => TextStyle(
        fontFamily: getFontFamily(context),
        color: primaryColor(context),
        fontSize: 16 * scale(context),
      );

  static TextStyle body2(BuildContext context) => TextStyle(
        fontFamily: getFontFamily(context),
        color: primaryColor(context),
        fontSize: 14 * scale(context),
      );

  /// --------------------
  /// SUBTITLES
  /// --------------------

  static TextStyle subtitle1(BuildContext context) => TextStyle(
        fontFamily: getFontFamily(context),
        color: secondaryColor(context),
        fontSize: 16 * scale(context),
        fontWeight: FontWeight.w500,
      );

  static TextStyle subtitle2(BuildContext context) => TextStyle(
        fontFamily: getFontFamily(context),
        color: secondaryColor(context),
        fontSize: 14 * scale(context),
        fontWeight: FontWeight.w500,
      );

  /// --------------------
  /// SMALL TEXTS
  /// --------------------

  static TextStyle caption(BuildContext context) => TextStyle(
        fontFamily: getFontFamily(context),
        color: secondaryColor(context),
        fontSize: 12 * scale(context),
      );

  static TextStyle overline(BuildContext context) => TextStyle(
        fontFamily: getFontFamily(context),
        color: secondaryColor(context),
        fontSize: 10 * scale(context),
        letterSpacing: 1.5,
      );

  /// --------------------
  /// BUTTON
  /// --------------------

  static TextStyle button(BuildContext context) => TextStyle(
        fontFamily: getFontFamily(context),
        color: primaryColor(context),
        fontSize: 14 * scale(context),
        fontWeight: FontWeight.w600,
      );
}

*/
class AppTypography {
  static final isDark = Provider.of<AppData>(context as BuildContext).isDark;
  static const String default_font_family = 'iran_sansx_fn';
  static const String iran_sansx_fn = 'iran_sansx_fn';
  static const String iran_sansx = 'iran_sansx';
  static const String iran_yekan_fn = 'iran_yekan_fn';
  static const String iran_yekan = 'iran_yekan';
  static const String kalameh_fn = 'kalameh_fn';
  static const String kalameh = 'kalameh';
  static const String peyda = 'peyda';
  static const String tahrir = 'tahrir';
  static const String sahel_fn = 'sahel_fn';
  static const String sahel = 'sahel';
  static const String vazir_fn = 'vazir_fn';
  static const String vazir = 'vazir';

  static TextStyle headline1() {
    return TextStyle(
      fontFamily: default_font_family,
      fontSize: _responsiveSize(32),
      fontWeight: FontWeight.w900,
      color: isDark
          ? AppColors.text_primary_dark
          : AppColors.text_primary_light,
      wordSpacing: 1,
      letterSpacing: 0.5,
      fontStyle: FontStyle.normal,
      textBaseline: TextBaseline.alphabetic,
      overflow: TextOverflow.visible,
    );
  }

  static TextStyle headline2() {
    return TextStyle(
      fontFamily: default_font_family,
      fontSize: _responsiveSize(28),
      fontWeight: FontWeight.w800,
      color: isDark
          ? AppColors.text_primary_dark
          : AppColors.text_primary_light,
      wordSpacing: 1,
      letterSpacing: 0.5,
      fontStyle: FontStyle.normal,
      textBaseline: TextBaseline.alphabetic,
      overflow: TextOverflow.visible,
    );
  }

  static TextStyle headline3() {
    return TextStyle(
      fontFamily: default_font_family,
      fontSize: _responsiveSize(24),
      fontWeight: FontWeight.w700,
      color: isDark
          ? AppColors.text_primary_dark
          : AppColors.text_primary_light,
      wordSpacing: 1,
      letterSpacing: 0.5,
      fontStyle: FontStyle.normal,
      textBaseline: TextBaseline.alphabetic,
      overflow: TextOverflow.visible,
    );
  }

  static TextStyle headline4() {
    return TextStyle(
      fontFamily: default_font_family,
      fontSize: _responsiveSize(20),
      fontWeight: FontWeight.w600,
      color: isDark
          ? AppColors.text_primary_dark
          : AppColors.text_primary_light,
      wordSpacing: 1,
      letterSpacing: 0.5,
      fontStyle: FontStyle.normal,
      textBaseline: TextBaseline.alphabetic,
      overflow: TextOverflow.visible,
    );
  }

  static TextStyle headline5() {
    return TextStyle(
      fontFamily: default_font_family,
      fontSize: _responsiveSize(18),
      fontWeight: FontWeight.w500,
      color: isDark
          ? AppColors.text_primary_dark
          : AppColors.text_primary_light,
      wordSpacing: 1,
      letterSpacing: 0.5,
      fontStyle: FontStyle.normal,
      textBaseline: TextBaseline.alphabetic,
      overflow: TextOverflow.visible,
    );
  }

  static TextStyle headline6() {
    return TextStyle(
      fontFamily: default_font_family,
      fontSize: _responsiveSize(16),
      fontWeight: FontWeight.w500,
      color: isDark
          ? AppColors.text_primary_dark
          : AppColors.text_primary_light,
      wordSpacing: 1,
      letterSpacing: 0.5,
      fontStyle: FontStyle.normal,
      textBaseline: TextBaseline.alphabetic,
      overflow: TextOverflow.visible,
    );
  }

  static TextStyle body1() {
    return TextStyle(
      fontFamily: default_font_family,
      fontSize: _responsiveSize(16),
      fontWeight: FontWeight.normal,
      color: isDark
          ? AppColors.text_primary_dark
          : AppColors.text_primary_light,
      wordSpacing: 1,
      letterSpacing: 0.5,
      fontStyle: FontStyle.normal,
      textBaseline: TextBaseline.alphabetic,
      overflow: TextOverflow.visible,
    );
  }

  static TextStyle body2() {
    return TextStyle(
      fontFamily: default_font_family,
      fontSize: _responsiveSize(14),
      fontWeight: FontWeight.normal,
      color: isDark
          ? AppColors.text_primary_dark
          : AppColors.text_primary_light,
      wordSpacing: 1,
      letterSpacing: 0.5,
      fontStyle: FontStyle.normal,
      textBaseline: TextBaseline.alphabetic,
      overflow: TextOverflow.visible,
    );
  }

  static TextStyle subtitle1() {
    return TextStyle(
      fontFamily: default_font_family,
      fontSize: _responsiveSize(16),
      fontWeight: FontWeight.w500,
      color: isDark
          ? AppColors.text_primary_dark
          : AppColors.text_primary_light,
      wordSpacing: 1,
      letterSpacing: 0.5,
      fontStyle: FontStyle.normal,
      textBaseline: TextBaseline.alphabetic,
      overflow: TextOverflow.visible,
    );
  }

  static TextStyle subtitle2() {
    return TextStyle(
      fontFamily: default_font_family,
      fontSize: _responsiveSize(14),
      fontWeight: FontWeight.w500,
      color: isDark
          ? AppColors.text_primary_dark
          : AppColors.text_primary_light,
      wordSpacing: 1,
      letterSpacing: 0.5,
      fontStyle: FontStyle.normal,
      textBaseline: TextBaseline.alphabetic,
      overflow: TextOverflow.visible,
    );
  }

  static TextStyle caption() {
    return TextStyle(
      fontFamily: default_font_family,
      fontSize: _responsiveSize(12),
      fontWeight: FontWeight.normal,
      color: isDark
          ? AppColors.text_primary_dark
          : AppColors.text_primary_light,
      wordSpacing: 1,
      letterSpacing: 0.5,
      fontStyle: FontStyle.normal,
      textBaseline: TextBaseline.alphabetic,
      overflow: TextOverflow.visible,
    );
  }

  static TextStyle overline() {
    return TextStyle(
      fontFamily: default_font_family,
      fontSize: _responsiveSize(10),
      fontWeight: FontWeight.normal,
      color: isDark
          ? AppColors.text_primary_dark
          : AppColors.text_primary_light,
      wordSpacing: 1,
      letterSpacing: 1.5,
      fontStyle: FontStyle.normal,
      textBaseline: TextBaseline.alphabetic,
      overflow: TextOverflow.visible,
    );
  }

  static TextStyle button() {
    return TextStyle(
      fontFamily: default_font_family,
      fontSize: _responsiveSize(14),
      fontWeight: FontWeight.w600,
      color: isDark
          ? AppColors.text_primary_dark
          : AppColors.text_primary_light,
      wordSpacing: 1,
      letterSpacing: 0.5,
      fontStyle: FontStyle.normal,
      textBaseline: TextBaseline.alphabetic,
      overflow: TextOverflow.visible,
    );
  }

  static double _responsiveSize(double baseSize) {
    // مثلاً بر اساس MediaQuery (در ویجت استفاده کن)
    // return baseSize * (MediaQuery.of(context).size.width / 375); // 375 = iPhone SE
    return baseSize; // ساده – می‌تونی responsive کنی
  }

  static void changeGlobalFont(String newFontFamily) {
    // نیاز به rebuild اپ داره – می‌تونی در AppData ذخیره کنی
  }

  static TextStyle musicTitle() {
    return TextStyle(
      fontFamily: default_font_family,
      fontSize: _responsiveSize(18),
      fontWeight: FontWeight.w600,
      color: isDark
          ? AppColors.text_primary_dark
          : AppColors.text_primary_light,
      wordSpacing: 1,
      letterSpacing: 0.5,
      fontStyle: FontStyle.normal,
      textBaseline: TextBaseline.alphabetic,
      overflow: TextOverflow.visible,
    );
  }
}
