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
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title)),
    body: Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          children: [
            Icon(icon, size: 64, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 24),
            Text(
              body,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, height: 1.8),
            ),
          ],
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
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('پرسش‌های متداول')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final item in items)
          Card(
            child: ExpansionTile(
              title: Text(item.$1),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(item.$2, style: const TextStyle(height: 1.6)),
                ),
              ],
            ),
          ),
      ],
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
    if (message.text.trim().isEmpty) return;
    setState(() => loading = true);
    try {
      final response = await http
          .post(
            Uri.parse('https://sornaz.com/api/sornaz/v1/contact'),
            headers: {'Accept': 'application/json'},
            body: {
              'name': name.text.trim(),
              'email': email.text.trim(),
              'subject': subject.text.trim(),
              'message': message.text.trim(),
            },
          )
          .timeout(const Duration(seconds: 20));
      final json =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      if (response.statusCode < 200 ||
          response.statusCode >= 300 ||
          json['success'] != true)
        throw Exception();
      if (!mounted) return;
      message.clear();
      subject.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('پیام شما ارسال شد. در اولین فرصت پاسخ می‌دهیم.'),
        ),
      );
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'ارسال پیام انجام نشد؛ پس از انتشار API دوباره تلاش کنید.',
            ),
          ),
        );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthSession>().user;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.feedback ? 'ارسال بازخورد' : 'تماس با ما'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            widget.feedback
                ? 'نظر شما به بهتر شدن سرناز کمک می‌کند.'
                : 'ارتباط با ما — ارسال پیام جدید',
            style: const TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          if (user == null) ...[
            TextField(
              controller: name,
              decoration: const InputDecoration(
                labelText: 'نام و نام خانوادگی *',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'ایمیل *',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 14),
          ],
          TextField(
            controller: subject,
            decoration: const InputDecoration(
              labelText: 'موضوع',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: message,
            minLines: 5,
            maxLines: 8,
            decoration: const InputDecoration(
              labelText: 'متن پیام *',
              alignLabelWithHint: true,
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 50,
            child: FilledButton(
              onPressed: loading ? null : submit,
              child: loading
                  ? const CircularProgressIndicator()
                  : const Text('ارسال پیام'),
            ),
          ),
        ],
      ),
    );
  }
}
