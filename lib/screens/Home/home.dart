import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sornaz/components/app_drawer.dart';
import 'package:sornaz/components/blog_carousel.dart';
import 'package:sornaz/components/bottom_nav.dart';
import 'package:sornaz/components/search_bar.dart';
import 'package:sornaz/helpers/app_colors.dart';
import 'package:sornaz/helpers/app_data.dart';
import 'package:sornaz/helpers/app_images.dart';
import 'package:sornaz/helpers/app_strings.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final appData = Provider.of<AppData>(context);
    final isDark = appData.isDark;
    // final theme = Theme.of(context);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Vazir',
        scaffoldBackgroundColor: isDark
            ? AppColors.background_dark
            : AppColors.background_light,
      ),
      home: Scaffold(
        appBar: AppBar(
          backgroundColor: isDark
              ? AppColors.background_dark
              : AppColors.background_light,
          elevation: 0,
          automaticallyImplyLeading: false,
          leadingWidth: 48,
          titleSpacing: 16,
          actionsPadding: const EdgeInsets.only(right: 24),

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
              RealBlogCarousel(),
              // NewCourseCardCarousel(),
              // UpdatedCoursesCarousel(),
              // ImportantCoursesList(),
              // AuthorsCarousel(),
            ],
          ),
        ),
        bottomNavigationBar: const BottomNavBarWidget(),
      ),
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
        height: 30,
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
      AppStrings.applicationName,
      style: TextStyle(
        fontSize: 18,
        color: isDark
            ? AppColors.text_primary_dark
            : AppColors.text_primary_light,
        fontWeight: FontWeight.w700,
      ),
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
        return Padding(
          padding: const EdgeInsets.only(left: 16),
          child: IconButton(
            icon: Icon(
              Icons.menu,
              color: isDark
                  ? AppColors.text_primary_dark
                  : AppColors.text_primary_light,
            ),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        );
      },
    );
  }
}
