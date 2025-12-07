import 'package:flutter/material.dart';

class AppSpacing {
  static const double space_0 = 0;
  static const double space_1 = 1;
  static const double space_2 = 2;
  static const double space_4 = 4;
  static const double space_8 = 8;
  static const double space_10 = 10;
  static const double space_12 = 12;
  static const double space_14 = 14;
  static const double space_16 = 16;
  static const double space_18 = 18;
  static const double space_20 = 20;
  static const double space_22 = 22;
  static const double space_24 = 24;
  static const double space_32 = 32;
  static const double space_36 = 36;
  static const double space_40 = 40;
  static const double space_48 = 48;
  static const double space_50 = 50;
  static const double space_56 = 56;
  static const double space_76 = 76;
  static const double space_85 = 85;
  static const double space_100 = 100;
  static const double space_150 = 150;
  static const double space_160 = 160;
  static const double space_170 = 170;
  static const double space_200 = 200;
  static const double space_300 = 300;

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
