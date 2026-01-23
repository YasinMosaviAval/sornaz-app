import 'package:flutter/material.dart';
import 'package:sornaz/components/bottom_nav.dart';
import 'package:sornaz/helpers/app_colors.dart';
import 'package:sornaz/helpers/app_constants.dart';
import 'package:sornaz/helpers/app_images.dart';
import 'package:sornaz/helpers/app_spacing.dart';
import 'package:sornaz/helpers/app_strings.dart';
import 'package:sornaz/helpers/app_translations.dart';
import 'package:sornaz/helpers/app_typography.dart';

import 'package:provider/provider.dart';
import 'package:sornaz/components/search_bar.dart';
import 'package:sornaz/helpers/app_data.dart';
import 'package:sornaz/helpers/app_locale_provider.dart';
import 'package:sornaz/screens/Articles/ui/blog_carousel.dart';
import 'package:sornaz/screens/Home/app_drawer.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final appData = Provider.of<AppData>(context);
    final isDark = appData.isDark;
    final localeProvider = Provider.of<LocaleProvider>(context, listen: false);
    final bool isEnglish = localeProvider.locale.languageCode == AppConstants.LOCALIZATION_EN;

    return
    Directionality(
      textDirection: isEnglish ? TextDirection.ltr : TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.home_body_background_color(isDark: isDark),
        appBar: AppBar(
          backgroundColor: AppColors.home_app_bar_background_color(isDark: isDark),
          elevation: 0,
          automaticallyImplyLeading: false,
          leadingWidth: AppSpacing.space_48,
          titleSpacing: AppSpacing.space_16,
          actionsPadding: const EdgeInsets.only(right: AppSpacing.space_24),
          leading: HeaderMenuIcon(isDark: isDark),
          title: ApplicationTitle(isDark: isDark),
          actions: [ApplicationLogo(isDark: isDark)],
        ),
        drawer: const AppDrawer(),
        body: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ComponentSearchBar(),
              BlogCarousel(),
              // NewCourseCardCarousel(),
              // UpdatedCoursesCarousel(),
              // ImportantCoursesList(),
              // AuthorsCarousel(),
            ],
          ),
        ),
        bottomNavigationBar: const BottomNavBarWidget(),
      ),
      // ),
    );
  }
}


class ApplicationLogo extends StatelessWidget {
  const ApplicationLogo({super.key, required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Image.asset(
        isDark ? AppImages.logo_dark : AppImages.logo_light,
        height: AppSpacing.space_32,
      ),
    );
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
