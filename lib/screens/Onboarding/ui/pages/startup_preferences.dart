import 'package:sornaz/components/app_logo.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sornaz/helpers/app_data.dart';
import 'package:sornaz/helpers/app_locale_provider.dart';
import 'package:sornaz/screens/Onboarding/ui/pages/onboarding.dart';

class StartupPreferencesScreen extends StatelessWidget {
  const StartupPreferencesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppData>();
    final locale = context.watch<LocaleProvider>();
    final english = locale.locale.languageCode == 'en';
    return Directionality(
      textDirection: english ? TextDirection.ltr : TextDirection.rtl,
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Spacer(),
                AppLogo(size: 130, withBackground: false),
                const SizedBox(height: 24),
                Text(
                  english ? 'Set up your experience' : 'تنظیم تجربه کاربری',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 32),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.language),
                        title: Text(english ? 'Language' : 'زبان برنامه'),
                        subtitle: Text(english ? 'English' : 'فارسی'),
                        trailing: Switch(
                          value: english,
                          onChanged: (v) => locale.setLocale(v ? 'en' : 'fa'),
                        ),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: Icon(
                          app.isDark ? Icons.dark_mode : Icons.light_mode,
                        ),
                        title: Text(english ? 'Dark mode' : 'حالت تاریک'),
                        subtitle: Text(
                          english
                              ? 'Choose light or dark theme'
                              : 'تم روشن یا تاریک را انتخاب کنید',
                        ),
                        trailing: Switch(
                          value: app.isDark,
                          onChanged: app.toggleDarkMode,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (_) => const OnboardingScreen(),
                      ),
                    ),
                    child: Text(english ? 'Continue' : 'ادامه'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
