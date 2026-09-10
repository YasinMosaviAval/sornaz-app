import 'package:sornaz/components/app_text.dart';
import 'package:sornaz/components/app_logo.dart';
import 'package:flutter/cupertino.dart' show CupertinoSwitch;
import 'package:flutter/material.dart';
import 'package:sornaz/screens/Home/ui/pages/home.dart';
import 'package:sornaz/components/drawer_theme.dart';
import 'package:sornaz/screens/Others/ui/pages/share_app.dart';
import 'package:provider/provider.dart';
import 'package:sornaz/components/app_drawer_item.dart';
import 'package:sornaz/helpers/app_colors.dart';
import 'package:sornaz/helpers/app_data.dart';
import 'package:sornaz/helpers/app_strings.dart';
import 'package:sornaz/helpers/app_translations.dart';
import 'package:sornaz/helpers/app_typography.dart';
import 'package:sornaz/screens/Others/ui/pages/about_us.dart';
import 'package:sornaz/screens/Others/ui/pages/settings.dart';
import 'package:sornaz/screens/Authentication/providers/auth_session.dart';
import 'package:sornaz/screens/Authentication/ui/pages/authentication.dart';
import 'package:sornaz/screens/Others/ui/pages/support_pages.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final appData = Provider.of<AppData>(context);
    final isDark = appData.isDark;
    final session = context.watch<AuthSession>();
    final authUser = session.user;
    return DrawerThemeScope(
      child: Drawer(
        shape: const RoundedRectangleBorder(),
        backgroundColor: isDark ? Colors.black : Colors.white,
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            children: [
                              ClipOval(
                                child: AppLogo(size: 48, withBackground: true),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    AppText(
                                      authUser?.fullName ??
                                          AppStrings.application_fullname
                                              .translate(context),
                                      style:
                                          AppTypography.appDrawerApplicationFullname(
                                            context,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    AppText(
                                      authUser?.contact ??
                                          AppStrings.application_email
                                              .translate(context),
                                      style:
                                          AppTypography.appDrawerApplicationEmail(
                                            context,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Ink(
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xff111111)
                                  : const Color(0xfff7f7f7),
                              border: Border.all(
                                color: isDark ? Colors.white12 : Colors.black12,
                              ),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        AppText(
                                          'حالت تاریک',
                                          style:
                                              AppTypography.appDrawerItemTitle(
                                                context,
                                              ),
                                        ),
                                        AppText(
                                          'نمایش برنامه با تم تاریک',
                                          style:
                                              AppTypography.appDrawerApplicationEmail(
                                                context,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Transform.scale(
                                    scale: 0.8,
                                    child: CupertinoSwitch(
                                      activeTrackColor: appData.accent,
                                      value: isDark,
                                      onChanged: appData.toggleDarkMode,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.fromLTRB(20, 16, 20, 4),
                          child: AppText('برنامه'),
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
                            body:
                                'محتواهایی که نشان می‌کنید در این بخش نمایش داده می‌شوند.',
                          ),
                        ),
                        const AppDrawerItem(
                          icon: Icons.share_outlined,
                          text: 'اشتراک‌گذاری برنامه',
                          link: ShareAppPage(),
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
                          child: AppText(
                            'جامعه',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                        AppDrawerItem(
                          icon: Icons.rate_review_outlined,
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
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Ink(
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xff111111)
                              : const Color(0xfff7f7f7),
                          border: Border.all(
                            color: isDark ? Colors.white12 : Colors.black12,
                          ),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            ListTile(
                              textColor: appData.accent,
                              title: AppText(
                                authUser == null
                                    ? 'ورود یا ثبت‌نام'
                                    : 'ورود با حساب دیگر',
                              ),
                              onTap: session.isChanging
                                  ? null
                                  : () => _accounts(context),
                            ),
                            if (authUser != null)
                              ListTile(
                                textColor: AppColors.error,
                                title: const AppText('خروج از حساب'),
                                onTap: session.isChanging
                                    ? null
                                    : () async {
                                        final session = context
                                            .read<AuthSession>();
                                        await session.clear();
                                        if (context.mounted) _home(context);
                                      },
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _home(BuildContext context) {
    context.read<AppData>().setBottomNavIndex(0);
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomePage()),
      (_) => false,
    );
  }

  Future<void> _accounts(BuildContext context) async {
    final session = context.read<AuthSession>();
    final navigator = Navigator.of(context);
    final selection = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      builder: (_) => DrawerThemeScope(
        child: Builder(
          builder: (context) => Material(
            color: Theme.of(context).colorScheme.surface,
            child: SafeArea(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(20),
                      child: AppText('حساب‌های کاربری'),
                    ),
                    for (final account in session.accounts)
                      ListTile(
                        leading: ClipOval(
                          child: account.avatar?.isNotEmpty == true
                              ? Image.network(
                                  Uri.parse(
                                    const String.fromEnvironment(
                                      'Sornaz_API_BASE_URL',
                                      defaultValue:
                                          'https://sornaz.com/api/sornaz/v1',
                                    ),
                                  ).resolve(account.avatar!).toString(),
                                  width: 40,
                                  height: 40,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) => const Icon(
                                    Icons.account_circle_outlined,
                                    size: 40,
                                  ),
                                )
                              : const Icon(
                                  Icons.account_circle_outlined,
                                  size: 40,
                                ),
                        ),
                        title: AppText(account.fullName),
                        subtitle: AppText(account.contact),
                        trailing: account.id == session.user?.id
                            ? const Icon(Icons.check)
                            : null,
                        onTap: () => Navigator.pop(context, account.id),
                      ),
                    ListTile(
                      leading: const Icon(Icons.person_add_alt),
                      title: const AppText('افزودن حساب کاربری'),
                      onTap: () => Navigator.pop(context, -1),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    if (selection == null || !context.mounted) return;
    if (selection == -1) {
      navigator.push(MaterialPageRoute(builder: (_) => const SignInScreen()));
    } else {
      await session.switchTo(selection);
      if (context.mounted) _home(context);
    }
  }
}
