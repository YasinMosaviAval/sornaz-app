import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sornaz/helpers/app_colors.dart';
import 'package:sornaz/helpers/app_data.dart';
import 'package:sornaz/helpers/app_images.dart';
import 'package:sornaz/helpers/app_spacing.dart';
import 'package:sornaz/helpers/app_strings.dart';
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
              AppStrings.applicationFullname,
              // AppStrings.sample_username,
              style: TextStyle(
                color: isDark
                    ? AppColors.text_primary_dark
                    : AppColors.text_primary_light,
              ),
            ),
            accountEmail: Text(
              AppStrings.applicationEmail,
              // AppStrings.sample_email,
              style: TextStyle(
                color: isDark
                    ? AppColors.text_secondary_dark
                    : AppColors.text_secondary_light,
              ),
            ),
            currentAccountPicture: SizedBox(
              // CircleAvatar(
              // backgroundImage: AssetImage(AppImages.logo_light),
              child: Image.asset(
                isDark ? AppImages.logo_dark : AppImages.logo_light,
              ),
              // NetworkImage(
              //   AppImages.logo_light,
              //   // AppImages.sample_online_images,
              // ), // جایگزین با تصویر واقعی
            ),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.background_dark
                  : AppColors.background_light,
            ),
            /*
            otherAccountsPictures: [
              SwitchListTile(
                title: const Text(AppStrings.dark_mode),
                subtitle: const Text(AppStrings.dark_mode_description),
                value: isDark,
                onChanged: appData.toggleDarkMode,
              ),
            ],
            */
          ),
          AppDrawerItem(
            icon: Icons.info,
            text: AppStrings.aboutUsTitle,
            link: AboutUsPage(),
          ),
          // AppDrawerItem(icon: Icons.bookmark, text: AppStrings.bookmark, link: BookmarkPage()),
          // AppDrawerItem(icon: Icons.share, text: AppStrings.share_app, link: ShareAppPage()),
          // AppDrawerItem(icon: Icons.help, text: AppStrings.faqTitle, link: FaqPage()),
          AppDrawerItem(
            icon: Icons.settings,
            text: AppStrings.settingsTitle,
            link: SettingsPage(),
          ),
          // AppDrawerItem(icon: Icons.emoji_events, text: AppStrings.achievements, link: AchievementsPage(), message: '2 New', messageColor: Colors.blue),
          // AppDrawerItem(icon: Icons.privacy_tip, text: AppStrings.privacyPolicyTitle, link: PrivacyPage(), message: 'Action Needed', messageColor: AppColors.error),

          // const Divider(),
          // HeaderItemPart(text: AppStrings.community),
          // AppDrawerItem(icon: Icons.feedback, text: AppStrings.share_feedback, link: ShareFeedbackPage()),
          // AppDrawerItem(icon: Icons.contact_mail, text: AppStrings.contactUsTitle, link: ContactUsPage(), ),
          // AppDrawerItem(icon: Icons.card_membership, text: AppStrings.membership, link: PaymentPage()),

          // const Divider(),
          // HeaderItemPart(text: AppStrings.my_account),
          // SwitchAcountItem(text: AppStrings.switch_acount, color: AppColors.info),
          // SwitchAcountItem(text: AppStrings.logout, color: AppColors.error),
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
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              decoration: BoxDecoration(
                color: messageColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(message, style: TextStyle(color: Colors.white)),
            ),

      onTap: () => Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => link,
          transitionDuration: const Duration(milliseconds: 250),
          transitionsBuilder: (_, animation, __, child) =>
              FadeTransition(opacity: animation, child: child),
        ),
      ),
    );
  }
}
