import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sornaz/components/app_drawer_item.dart';
import 'package:sornaz/helpers/app_colors.dart';
import 'package:sornaz/helpers/app_data.dart';
import 'package:sornaz/helpers/app_images.dart';
import 'package:sornaz/helpers/app_strings.dart';
import 'package:sornaz/helpers/app_translations.dart';
import 'package:sornaz/helpers/app_typography.dart';
import 'package:sornaz/screens/Others/about_us.dart';
import 'package:sornaz/screens/Others/settings.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final appData = Provider.of<AppData>(context);
    final isDark = appData.isDark;
    return Drawer(
      backgroundColor: AppColors.app_drawer_background_color(isDark: isDark),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(
              AppStrings.application_fullname.translate(context),
              style: AppTypography.appDrawerApplicationFullname(context),
            ),
            accountEmail: Text(
              AppStrings.application_email.translate(context),
              style: AppTypography.appDrawerApplicationEmail(context),
            ),
            currentAccountPicture: SizedBox(
              child: Image.asset(
                isDark ? AppImages.logo_dark : AppImages.logo_light,
              ),
            ),
            decoration: BoxDecoration(
              color: AppColors.app_drawer_box_decoration_color(isDark: isDark),
            ),
          ),
          AppDrawerItem(
            icon: Icons.info,
            text: AppStrings.about_us_title.translate(context),
            link: AboutUsPage(),
          ),
          AppDrawerItem(
            icon: Icons.settings,
            text: AppStrings.settings_title.translate(context),
            link: SettingsPage(),
          ),
        ],
      ),
    );
  }
}

// class SwitchAcountItem extends StatelessWidget {
//   const SwitchAcountItem({required this.text, required this.color, super.key});

//   final String text;
//   final Color color;

//   @override
//   Widget build(BuildContext context) {
//     return ListTile(
//       title: Text(text, style: AppTypography.appDrawerSwitchAcountItem),
//       onTap: () {},
//     );
//   }
// }

// class HeaderItemPart extends StatelessWidget {
//   const HeaderItemPart({required this.text, super.key});

//   final String text;

//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: EdgeInsets.symmetric(horizontal: AppSpacing.space_16),
//       child: Text(text, style: AppTypography.appDrawerHeaderItemPart),
//     );
//   }
// }
