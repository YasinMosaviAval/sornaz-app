import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sornaz/helpers/app_colors.dart';
import 'package:sornaz/helpers/app_data.dart';
import 'package:sornaz/helpers/app_images.dart';
import 'package:sornaz/helpers/app_navigation.dart';
import 'package:sornaz/helpers/app_spacing.dart';
import 'package:sornaz/helpers/app_strings.dart';
import 'package:sornaz/helpers/app_translations.dart';
import 'package:sornaz/screens/Others/about_us.dart';
import 'package:sornaz/screens/Others/settings.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final appData = Provider.of<AppData>(context);
    final isDark = appData.isDark;
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(
              AppStrings.application_fullname.translate(context),
              style: TextStyle(
                color: isDark
                    ? AppColors.text_primary_dark
                    : AppColors.text_primary_light,
              ),
            ),
            accountEmail: Text(
              AppStrings.application_email.translate(context),
              style: TextStyle(
                color: isDark
                    ? AppColors.text_secondary_dark
                    : AppColors.text_secondary_light,
              ),
            ),
            currentAccountPicture: SizedBox(
              child: Image.asset(
                isDark ? AppImages.logo_dark : AppImages.logo_light,
              ),
            ),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.background_dark
                  : AppColors.background_light,
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

class SwitchAcountItem extends StatelessWidget {
  const SwitchAcountItem({required this.text, required this.color, super.key});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(text, style: TextStyle(color: color)),
      onTap: () {},
    );
  }
}

class HeaderItemPart extends StatelessWidget {
  const HeaderItemPart({required this.text, super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.space_16),
      child: Text(text),
    );
  }
}

class AppDrawerItem extends StatelessWidget {
  const AppDrawerItem({
    required this.icon,
    required this.text,
    required this.link,
    this.messageColor = Colors.white,
    this.message = '',
    super.key,
  });

  final IconData icon;
  final String text;
  final Widget link;
  final Color messageColor;
  final String message;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(text),

      trailing: message == ''
          ? SizedBox()
          : Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.space_8,
              ),
              decoration: BoxDecoration(
                color: messageColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(message, style: TextStyle(color: Colors.white)),
            ),
      onTap: () => navigateWithFade(context, link),
    );
  }
}
