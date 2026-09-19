import 'package:sornaz/components/scroll_aware_scaffold.dart';
import 'package:sornaz/components/app_top_bar_direction.dart';
import 'package:sornaz/components/app_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sornaz/components/drawer_theme.dart';
import 'package:sornaz/helpers/app_typography.dart';
import 'package:url_launcher/url_launcher.dart';

const appSocialLinks = <(String, String, IconData)>[
  ('سایت سرناز', 'https://sornaz.com/', Icons.language),
  ('کانال تلگرام', 'https://t.me/sornaz_music_application', Icons.telegram),
  (
    'کانال یوتیوب',
    'https://www.youtube.com/@sornaz.academy/',
    Icons.play_circle_outline,
  ),
  (
    'صفحه اینستاگرام',
    'https://www.instagram.com/sornaz.ac',
    Icons.camera_alt_outlined,
  ),
  ('ایمیل', 'mailto:sornaz.ac@gmail.com', Icons.email_outlined),
];

class SocialLinkTile extends StatelessWidget {
  const SocialLinkTile({super.key, required this.link});
  final (String, String, IconData) link;
  @override
  Widget build(BuildContext context) => Material(
    type: MaterialType.transparency,
    child: ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(link.$3),
      title: AppText(link.$1, style: AppTypography.appDrawerItemTitle(context)),
      subtitle: AppText(
        link.$2.replaceFirst('mailto:', ''),
        textDirection: TextDirection.ltr,
        style: AppTypography.appDrawerApplicationEmail(context),
      ),
      onTap: () async {
        try {
          if (await launchUrl(
            Uri.parse(link.$2),
            mode: LaunchMode.externalApplication,
          )) {
            return;
          }
        } catch (_) {}
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: AppText('برنامه‌ای برای باز کردن این پیوند پیدا نشد.'),
            ),
          );
        }
      },
    ),
  );
}

class ShareAppPage extends StatefulWidget {
  const ShareAppPage({super.key});
  @override
  State<ShareAppPage> createState() => _ShareAppPageState();
}

class _ShareAppPageState extends State<ShareAppPage> {
  bool sharing = false;
  static const channel = MethodChannel('sornaz/app_share');
  Future<void> share() async {
    setState(() => sharing = true);
    try {
      await channel.invokeMethod<void>('shareApk');
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: AppText(
              'اشتراک‌گذاری فایل نصب در این دستگاه ممکن نشد. از لینک سایت استفاده کنید.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) => DrawerThemeScope(
    child: ScrollAwareScaffold(
      appBar: AppTopBarDirection(
        child: AppBar(title: const AppText('اشتراک‌گذاری برنامه')),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const AppText(
              'سرناز را به دوستان خود معرفی کنید و در شبکه‌های اجتماعی همراه ما باشید.',
            ),
            const SizedBox(height: 20),
            for (final link in appSocialLinks) SocialLinkTile(link: link),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: sharing ? null : share,
              icon: sharing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.share_outlined),
              label: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: AppText(
                  sharing ? 'آماده‌سازی فایل نصب…' : 'ارسال فایل نصبی برنامه',
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
