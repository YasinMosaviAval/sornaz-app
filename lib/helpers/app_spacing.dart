import 'package:flutter/material.dart';

class AppSpacing {
  static const double space_0 = 0;
  static const double space_4 = 4;
  static const double space_8 = 8;
  static const double space_16 = 16;
  static const double space_24 = 24;
  static const double space_32 = 32;
  static const double space_48 = 48;
  static const double space_56 = 56;

  static const double zero = 0;
  static const double xxSmall = 4;
  static const double xSmall = 8;
  static const double small = 16;
  static const double medium = 24;
  static const double large = 32;
  static const double xLarge = 48;
  static const double xxLarge = 56;

  // static Widget horizontal(double space = medium, {bool responsive = true, required BuildContext context}) {
  //   final responsiveSpace = responsive ? _responsive(space, context) : space;
  //   return SizedBox(width: responsiveSpace);
  // }

  // static Widget vertical(double space = medium, {bool responsive = true, required BuildContext context}) {
  //   final responsiveSpace = responsive ? _responsive(space, context) : space;
  //   return SizedBox(height: responsiveSpace);
  // }

  static Widget spacer({int flex = 1}) {
    return Spacer(flex: flex);
  }

  //   static double _responsive(double base, BuildContext context) {
  //     final screenWidth = MediaQuery.of(context).size.width;
  //     if (screenWidth < 600) return base;
  //     if (screenWidth < 1200) return base * 1.2;
  //     return base * 1.5;
  //   }
}

class AppPadding {
  // static EdgeInsets all(double value = AppSpacing.medium) {
  //   return EdgeInsets.all(value);
  // }

  static EdgeInsets symmetric({
    double horizontal = AppSpacing.medium,
    double vertical = AppSpacing.medium,
  }) {
    return EdgeInsets.symmetric(horizontal: horizontal, vertical: vertical);
  }

  static EdgeInsets only({
    double left = 0,
    double top = 0,
    double right = 0,
    double bottom = 0,
  }) {
    return EdgeInsets.only(left: left, top: top, right: right, bottom: bottom);
  }

  // static EdgeInsets responsiveAll(BuildContext context, double base = AppSpacing.medium) {
  //   final responsiveValue = AppSpacing._responsive(base, context);
  //   return EdgeInsets.all(responsiveValue);
  // }

  static EdgeInsets screenPadding() {
    return const EdgeInsets.all(AppSpacing.large);
  }

  static EdgeInsets cardPadding() {
    return const EdgeInsets.symmetric(
      horizontal: AppSpacing.medium,
      vertical: AppSpacing.small,
    );
  }

  static EdgeInsets buttonPadding() {
    return const EdgeInsets.symmetric(
      horizontal: AppSpacing.large,
      vertical: AppSpacing.small,
    );
  }
}






/*
Use Case

Column(
  children: [
    Text('عنوان'),
    AppSpacing.vertical(AppSpacing.medium, context: context), // فاصله عمودی 16px (responsive)
    Text('توضیحات'),
    AppSpacing.horizontal(AppSpacing.large, context: context), // فاصله افقی 24px
    AppSpacing.spacer(flex: 2), // Spacer با flex 2
  ],
),

Container(
  padding: AppPadding.cardPadding(), // پدینگ کارت (16h + 8v)
  child: Text('محتوا'),
),

Padding(
  padding: AppPadding.responsiveAll(context, AppSpacing.large), // پدینگ responsive 24px همه طرف
  child: ElevatedButton(
    onPressed: () {},
    style: ElevatedButton.styleFrom(
      padding: AppPadding.buttonPadding(), // پدینگ باتن (24h + 8v)
    ),
    child: const Text('دکمه'),
  ),
),

*/