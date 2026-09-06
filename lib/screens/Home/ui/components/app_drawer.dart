import 'package:flutter/material.dart';
import 'package:sornaz/screens/Social/user_panel.dart';
import 'package:provider/provider.dart';
import 'package:sornaz/components/app_drawer_item.dart';
import 'package:sornaz/helpers/app_colors.dart';
import 'package:sornaz/helpers/app_data.dart';
import 'package:sornaz/helpers/app_images.dart';
import 'package:sornaz/helpers/app_strings.dart';
import 'package:sornaz/helpers/app_translations.dart';
import 'package:sornaz/helpers/app_typography.dart';
import 'package:sornaz/screens/Others/ui/pages/about_us.dart';
import 'package:sornaz/screens/Others/ui/pages/settings.dart';
import 'package:sornaz/screens/Authentication/providers/auth_session.dart';
import 'package:sornaz/screens/Authentication/ui/pages/authentication.dart';
import 'package:sornaz/screens/Others/ui/pages/support_pages.dart';
import 'package:url_launcher/url_launcher.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final appData = Provider.of<AppData>(context);
    final isDark = appData.isDark;
    final authUser = context.watch<AuthSession>().user;
    return Drawer(
      backgroundColor: AppColors.app_drawer_background_color(isDark: isDark),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(
              authUser?.fullName ??
                  AppStrings.application_fullname.translate(context),
              style: AppTypography.appDrawerApplicationFullname(context),
            ),
            accountEmail: Text(
              authUser?.contact ??
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
          SwitchListTile(
            // Theme preference also applies to the social panel.
            secondary: const Icon(Icons.dark_mode_outlined),
            title: const Text('حالت تاریک'),
            subtitle: const Text('نمایش برنامه با تم تاریک'),
            value: isDark,
            onChanged: appData.toggleDarkMode,
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(
              'برنامه',
              style: TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ),
          AppDrawerItem(
            icon: Icons.person_outline,
            text: 'پنل کاربری و پروفایل',
            link: const UserPanelPage(),
          ),
          AppDrawerItem(
            icon: Icons.info,
            text: AppStrings.about_us_title.translate(context),
            link: AboutUsPage(),
          ),
          AppDrawerItem(
            icon: Icons.bookmark_border,
            text: 'نشان‌شده‌ها',
            link: const SimpleInfoPage(
              title: 'نشان‌شده‌ها',
              icon: Icons.bookmark_border,
              body: 'محتواهایی که نشان می‌کنید در این بخش نمایش داده می‌شوند.',
            ),
          ),
          ListTile(
            leading: const Icon(Icons.share_outlined),
            title: const Text('اشتراک‌گذاری برنامه'),
            onTap: () => launchUrl(
              Uri.parse('https://sornaz.com'),
              mode: LaunchMode.externalApplication,
            ),
          ),
          AppDrawerItem(
            icon: Icons.help_outline,
            text: 'پرسش‌های متداول',
            link: const FaqPage(),
          ),
          AppDrawerItem(
            icon: Icons.settings,
            text: AppStrings.settings_title.translate(context),
            link: SettingsPage(),
          ),
          AppDrawerItem(
            icon: Icons.emoji_events_outlined,
            text: 'دستاوردها',
            link: const SimpleInfoPage(
              title: 'دستاوردها',
              icon: Icons.emoji_events_outlined,
              body:
                  'دستاوردها و روند پیشرفت آموزشی شما در این بخش نمایش داده می‌شود.',
            ),
          ),
          AppDrawerItem(
            icon: Icons.privacy_tip_outlined,
            text: 'حریم خصوصی',
            link: const SimpleInfoPage(
              title: 'حریم خصوصی',
              icon: Icons.privacy_tip_outlined,
              body:
                  'اطلاعات شخصی کاربران محرمانه نگهداری می‌شود و جز در موارد قانونی یا با رضایت کاربر در اختیار شخص ثالث قرار نمی‌گیرد.',
            ),
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text(
              'جامعه',
              style: TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ),
          AppDrawerItem(
            icon: Icons.rate_review_outlined,
            text: 'ارسال بازخورد',
            link: const ContactUsPage(feedback: true),
          ),
          AppDrawerItem(
            icon: Icons.contact_support_outlined,
            text: 'تماس با ما',
            link: const ContactUsPage(),
          ),
          AppDrawerItem(
            icon: Icons.card_membership_outlined,
            text: 'عضویت',
            link: const SimpleInfoPage(
              title: 'عضویت',
              icon: Icons.card_membership_outlined,
              body:
                  'جزئیات عضویت و خدمات حساب شما پس از فعال شدن طرح‌های عضویت اینجا قرار می‌گیرد.',
            ),
          ),
          const Divider(),
          if (authUser == null)
            ListTile(
              leading: const Icon(Icons.login),
              title: const Text('ورود یا ثبت‌نام'),
              onTap: () => Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const SignInScreen()),
                (_) => false,
              ),
            )
          else ...[
            ListTile(
              leading: const Icon(Icons.switch_account_outlined),
              title: const Text('ورود با حساب دیگر'),
              onTap: () async {
                await context.read<AuthSession>().clear();
                if (context.mounted)
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const SignInScreen()),
                    (_) => false,
                  );
              },
            ),
            ListTile(
              textColor: AppColors.error,
              iconColor: AppColors.error,
              leading: const Icon(Icons.logout),
              title: const Text('خروج از حساب'),
              onTap: () async {
                await context.read<AuthSession>().clear();
                if (context.mounted)
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const SignInScreen()),
                    (_) => false,
                  );
              },
            ),
          ],
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
