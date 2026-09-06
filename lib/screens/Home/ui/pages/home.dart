import 'package:sornaz/components/app_logo.dart';
import 'package:flutter/material.dart';
import 'package:sornaz/helpers/app_strings.dart';
import 'package:sornaz/helpers/app_translations.dart';
import 'package:sornaz/helpers/app_typography.dart';
import 'package:sornaz/helpers/app_colors.dart';
export 'learning_home.dart';

class ApplicationLogo extends StatelessWidget {
  const ApplicationLogo({super.key, required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Center(child: AppLogo(size: 40, withBackground: false));
  }
}

class ApplicationTitle extends StatelessWidget {
  const ApplicationTitle({super.key, required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Text(
      AppStrings.application_name.translate(context),
      style: AppTypography.homeApplicationTitle(context),
      // textAlign: TextAlign.start,
      // textAlign: TextAlign.end,
    );
  }
}

class HeaderMenuIcon extends StatelessWidget {
  const HeaderMenuIcon({super.key, required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) {
        return IconButton(
          icon: Icon(
            Icons.menu,
            color: AppColors.home_header_menu_icon_color(isDark: isDark),
          ),
          onPressed: () => Scaffold.of(context).openDrawer(),
        );
      },
    );
  }
}
