import 'package:flutter/material.dart';

// فونت پیش‌فرض (فرض بر نصب Vazir در pubspec.yaml)
const String defaultFontFamily = 'Vazir'; // یا 'Roboto' اگر فونت ندارید
const String secondaryFontFamily = 'Roboto'; // فونت دوم برای تنوع

// کلاس اصلی تایپوگرافی
class AppTypography {
  // Headline styles (عنوان‌های بزرگ - H1 تا H6)
  static TextStyle headline1(
    bool isDark, {
    double size = 32,
    FontWeight weight = FontWeight.bold,
    String fontFamily = defaultFontFamily,
  }) {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: _responsiveSize(size),
      fontWeight: weight,
      color: isDark ? Colors.white : Colors.black,
    );
  }

  static TextStyle headline2(
    bool isDark, {
    double size = 28,
    FontWeight weight = FontWeight.bold,
    String fontFamily = defaultFontFamily,
  }) {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: _responsiveSize(size),
      fontWeight: weight,
      color: isDark ? Colors.white : Colors.black,
    );
  }

  static TextStyle headline3(
    bool isDark, {
    double size = 24,
    FontWeight weight = FontWeight.bold,
    String fontFamily = defaultFontFamily,
  }) {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: _responsiveSize(size),
      fontWeight: weight,
      color: isDark ? Colors.white : Colors.black,
    );
  }

  static TextStyle headline4(
    bool isDark, {
    double size = 20,
    FontWeight weight = FontWeight.w700,
    String fontFamily = defaultFontFamily,
  }) {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: _responsiveSize(size),
      fontWeight: weight,
      color: isDark ? Colors.white : Colors.black,
    );
  }

  static TextStyle headline5(
    bool isDark, {
    double size = 18,
    FontWeight weight = FontWeight.w600,
    String fontFamily = defaultFontFamily,
  }) {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: _responsiveSize(size),
      fontWeight: weight,
      color: isDark ? Colors.white : Colors.black,
    );
  }

  static TextStyle headline6(
    bool isDark, {
    double size = 16,
    FontWeight weight = FontWeight.w600,
    String fontFamily = defaultFontFamily,
  }) {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: _responsiveSize(size),
      fontWeight: weight,
      color: isDark ? Colors.white : Colors.black,
    );
  }

  // Body styles (متن اصلی)
  static TextStyle body1(
    bool isDark, {
    double size = 16,
    FontWeight weight = FontWeight.normal,
    String fontFamily = defaultFontFamily,
  }) {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: _responsiveSize(size),
      fontWeight: weight,
      color: isDark ? Colors.white70 : Colors.black87,
    );
  }

  static TextStyle body2(
    bool isDark, {
    double size = 14,
    FontWeight weight = FontWeight.normal,
    String fontFamily = defaultFontFamily,
  }) {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: _responsiveSize(size),
      fontWeight: weight,
      color: isDark ? Colors.white70 : Colors.black87,
    );
  }

  // Subtitle / Caption / Overline / Button
  static TextStyle subtitle1(
    bool isDark, {
    double size = 16,
    FontWeight weight = FontWeight.w500,
    String fontFamily = defaultFontFamily,
  }) {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: _responsiveSize(size),
      fontWeight: weight,
      color: isDark ? Colors.grey[400]! : Colors.grey[700]!,
    );
  }

  static TextStyle subtitle2(
    bool isDark, {
    double size = 14,
    FontWeight weight = FontWeight.w500,
    String fontFamily = defaultFontFamily,
  }) {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: _responsiveSize(size),
      fontWeight: weight,
      color: isDark ? Colors.grey[400]! : Colors.grey[700]!,
    );
  }

  static TextStyle caption(
    bool isDark, {
    double size = 12,
    FontWeight weight = FontWeight.normal,
    String fontFamily = defaultFontFamily,
  }) {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: _responsiveSize(size),
      fontWeight: weight,
      color: isDark ? Colors.grey[500]! : Colors.grey[600]!,
    );
  }

  static TextStyle overline(
    bool isDark, {
    double size = 10,
    FontWeight weight = FontWeight.normal,
    String fontFamily = defaultFontFamily,
  }) {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: _responsiveSize(size),
      fontWeight: weight,
      color: isDark ? Colors.grey[500]! : Colors.grey[600]!,
      letterSpacing: 1.5,
    );
  }

  static TextStyle button(
    bool isDark, {
    double size = 14,
    FontWeight weight = FontWeight.w600,
    String fontFamily = defaultFontFamily,
  }) {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: _responsiveSize(size),
      fontWeight: weight,
      color: isDark ? Colors.white : Colors.black,
    );
  }

  // فانکشن responsive برای اندازه فونت (بر اساس عرض صفحه)
  static double _responsiveSize(double baseSize) {
    // مثلاً بر اساس MediaQuery (در ویجت استفاده کن)
    // return baseSize * (MediaQuery.of(context).size.width / 375); // 375 = iPhone SE
    return baseSize; // ساده – می‌تونی responsive کنی
  }

  // تغییر فونت کلی (دینامیک)
  static void changeGlobalFont(String newFontFamily) {
    // نیاز به rebuild اپ داره – می‌تونی در AppData ذخیره کنی
  }

  // استایل‌های سفارشی (مثل برای موسیقی یا کورس‌ها)
  static TextStyle musicTitle(
    bool isDark, {
    double size = 18,
    FontWeight weight = FontWeight.bold,
  }) {
    return TextStyle(
      fontFamily: secondaryFontFamily, // فونت متفاوت
      fontSize: _responsiveSize(size),
      fontWeight: weight,
      color: isDark ? Colors.yellow[300]! : Colors.blue[800]!,
      letterSpacing: 0.5,
    );
  }

  // می‌تونی استایل‌های بیشتری اضافه کنی (مثل displayLarge, labelSmall, etc. از Material)
}


/*
// تعریف فونت پیش‌فرض (فرض بر نصب فونت Vazir در pubspec.yaml)
const String defaultFontFamily = 'Vazir'; // یا 'Roboto' اگر فونت ندارید

// کلاس برای TextStyleها (با قابلیت تغییر وزن، اندازه، فونت)
class AppTypography {
  // فونت headline (عنوان‌ها)
  static TextStyle headline(
    bool isDark, {
    double size = 24,
    FontWeight weight = FontWeight.bold,
  }) {
    return TextStyle(
      fontFamily: defaultFontFamily,
      fontSize: size,
      fontWeight: weight,
      color: isDark ? Colors.white : Colors.black,
    );
  }

  // فونت body (متن اصلی)
  static TextStyle body(
    bool isDark, {
    double size = 16,
    FontWeight weight = FontWeight.normal,
  }) {
    return TextStyle(
      fontFamily: defaultFontFamily,
      fontSize: size,
      fontWeight: weight,
      color: isDark ? Colors.white70 : Colors.black87,
    );
  }

  // فونت subtitle (زیرعنوان‌ها)
  static TextStyle subtitle(
    bool isDark, {
    double size = 14,
    FontWeight weight = FontWeight.w500,
  }) {
    return TextStyle(
      fontFamily: defaultFontFamily,
      fontSize: size,
      fontWeight: weight,
      color: isDark ? Colors.grey[400]! : Colors.grey[700]!,
    );
  }

  // تغییر فونت کلی (اگر بخوای فونت رو عوض کنی)
  static void changeFontFamily(String newFont) {
    // اینجا می‌تونی فونت رو دینامیک تغییر بدی، اما نیاز به rebuild اپ داره
    // مثلاً در AppData ذخیره کن و ThemeData رو آپدیت کن
  }

  // می‌تونی استایل‌های بیشتری اضافه کنی (مثل buttonStyle, caption, etc.)
}

*/




/*
Use Way

Text(
  'عنوان',
  style: AppTypography.headline(isDark: appData.isDark, size: 28, weight: FontWeight.w900),
),

Text(
  'توضیحات',
  style: AppTypography.body(isDark: appData.isDark),
),


//-------------------------------



MaterialApp(
  theme: ThemeData(
    primaryColor: AppColors.getPrimary(isDark: false), // برای لایت
    scaffoldBackgroundColor: AppColors.getBackground(isDark: false),
    textTheme: TextTheme(
      headlineMedium: AppTypography.headline(isDark: false),
      bodyMedium: AppTypography.body(isDark: false),
      labelMedium: AppTypography.subtitle(isDark: false),
    ),
  ),
  darkTheme: ThemeData(
    primaryColor: AppColors.getPrimary(isDark: true), // برای دارک
    scaffoldBackgroundColor: AppColors.getBackground(isDark: true),
    textTheme: TextTheme(
      headlineMedium: AppTypography.headline(isDark: true),
      bodyMedium: AppTypography.body(isDark: true),
      labelMedium: AppTypography.subtitle(isDark: true),
    ),
  ),
  themeMode: appData.isDark ? ThemeMode.dark : ThemeMode.light,
)
*/