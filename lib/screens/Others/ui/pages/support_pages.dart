import 'package:sornaz/screens/Social/social_api.dart';
import 'package:sornaz/helpers/app_translations.dart';
import 'package:sornaz/components/app_text.dart';
import 'package:sornaz/components/drawer_theme.dart';
import 'package:sornaz/components/settings_section_header.dart';
import 'package:sornaz/components/justified_text.dart';
import 'package:sornaz/components/app_bar.dart';
import 'package:sornaz/helpers/app_colors.dart';
import 'package:sornaz/helpers/app_data.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:sornaz/screens/Authentication/providers/auth_session.dart';

class SimpleInfoPage extends StatelessWidget {
  const SimpleInfoPage({
    required this.title,
    required this.icon,
    required this.body,
    super.key,
  });
  final String title;
  final IconData icon;
  final String body;
  @override
  Widget build(BuildContext context) => DrawerThemeScope(
    child: Scaffold(
      appBar: AppBar(title: AppText(title)),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            children: [
              Icon(
                icon,
                size: 64,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 24),
              AppText(
                body,
                textAlign: TextAlign.center,
                style: const TextStyle(height: 1.8),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class FaqPage extends StatelessWidget {
  const FaqPage({super.key});
  static const items = <(String, String)>[
    (
      'چطور در سرناز ثبت‌نام کنم؟',
      'از صفحه ثبت‌نام، مشخصات خود را وارد کنید و کد تأیید ۶ رقمی را ثبت کنید.',
    ),
    (
      'آیا بدون حساب کاربری می‌توانم از برنامه استفاده کنم؟',
      'بله، در صفحه ورود یا ثبت‌نام گزینه ادامه بدون ورود را انتخاب کنید.',
    ),
    (
      'چطور با پشتیبانی تماس بگیرم؟',
      'از منوی برنامه وارد صفحه تماس با ما شوید و پیام خود را ارسال کنید.',
    ),
  ];
  @override
  Widget build(BuildContext context) => DrawerThemeScope(
    child: Scaffold(
      appBar: SornazAppBar(title: 'پرسش‌های متداول'.translate(context)),
      backgroundColor: AppColors.about_us_background_color(
        isDark: context.watch<AppData>().isDark,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            for (final item in items)
              SettingsSectionHeader(
                title: item.$1.translate(context),
                leadingIcon: Icons.help_outline,
                initiallyExpanded: false,
                children: [JustifiedText(text: item.$2.translate(context))],
              ),
          ],
        ),
      ),
    ),
  );
}

class ContactUsPage extends StatefulWidget {
  const ContactUsPage({this.feedback = false, super.key});
  final bool feedback;
  @override
  State<ContactUsPage> createState() => _ContactUsPageState();
}

class _ContactUsPageState extends State<ContactUsPage> {
  final name = TextEditingController();
  final email = TextEditingController();
  final subject = TextEditingController();
  final message = TextEditingController();
  bool loading = false;
  @override
  void dispose() {
    name.dispose();
    email.dispose();
    subject.dispose();
    message.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (message.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: AppText('متن پیام را وارد کنید.')),
      );
      return;
    }
    final user = context.read<AuthSession>().user;
    setState(() => loading = true);
    try {
      final response = await http
          .post(
            Uri.parse('${SocialApi.base}/contact'),
            headers: {'Accept': 'application/json'},
            body: {
              'name': name.text.trim().isNotEmpty
                  ? name.text.trim()
                  : (user?.fullName ?? ''),
              'email': email.text.trim().isNotEmpty
                  ? email.text.trim()
                  : (user?.email ?? ''),
              'subject': subject.text.trim(),
              'message': message.text.trim(),
            },
          )
          .timeout(const Duration(seconds: 20));
      final json =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      if (response.statusCode < 200 ||
          response.statusCode >= 300 ||
          json['success'] != true &&
              (json['data'] is! Map || json['data']['success'] != true)) {
        throw Exception();
      }
      if (!mounted) return;
      message.clear();
      subject.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: AppText('پیام شما ارسال شد. در اولین فرصت پاسخ می‌دهیم.'),
        ),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: AppText(
              'ارسال پیام انجام نشد؛ اتصال اینترنت را بررسی کنید و دوباره تلاش کنید.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthSession>().user;
    return DrawerThemeScope(
      child: Scaffold(
        appBar: AppBar(title: const AppText('تماس با ما')),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AppText(
                          'ارتباط با ما — ارسال پیام جدید',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 24),
                        if (user == null) ...[
                          TextField(
                            controller: name,
                            decoration: InputDecoration(
                              labelText: 'نام و نام خانوادگی'.translate(
                                context,
                              ),
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 14),
                        ],
                        if (user?.email?.isNotEmpty != true) ...[
                          TextField(
                            controller: email,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              labelText: 'ایمیل پاسخ (اختیاری)'.translate(
                                context,
                              ),
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 14),
                        ],
                        TextField(
                          controller: subject,
                          decoration: InputDecoration(
                            labelText: 'موضوع'.translate(context),
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Expanded(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(minHeight: 180),
                            child: TextField(
                              key: const Key('contact-message'),
                              controller: message,
                              expands: true,
                              maxLines: null,
                              textAlignVertical: TextAlignVertical.top,
                              decoration: InputDecoration(
                                labelText: 'متن پیام *'.translate(context),
                                alignLabelWithHint: true,
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        FilledButton(
                          key: const Key('contact-send'),
                          onPressed: loading ? null : submit,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            child: loading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const AppText('ارسال پیام'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
