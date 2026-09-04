import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sornaz/helpers/app_colors.dart';
import 'package:sornaz/helpers/app_data.dart';
import 'package:sornaz/helpers/app_images.dart';
import 'package:sornaz/helpers/app_locale_provider.dart';
import 'package:sornaz/helpers/app_strings.dart';
import 'package:sornaz/helpers/app_translations.dart';
import 'package:sornaz/screens/Authentication/ui/pages/authentication.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  static const completedPreferenceKey = 'onboarding_completed';

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _page = 0;

  static const _images = [
    AppImages.onboarding_image_0,
    AppImages.onboarding_image_1,
    AppImages.onboarding_image_2,
  ];

  static const _titles = [
    AppStrings.onboarding_title_2,
    AppStrings.onboarding_title_0,
    AppStrings.onboarding_title_1,
  ];

  static const _subtitles = [
    AppStrings.onboarding_subtitle_2,
    AppStrings.onboarding_subtitle_0,
    AppStrings.onboarding_subtitle_1,
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    if (_page < _images.length - 1) {
      await _controller.nextPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
      return;
    }
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(OnboardingScreen.completedPreferenceKey, true);
    if (!mounted) return;
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const SignInScreen()));
  }

  void _previous() {
    _controller.previousPage(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<AppData>().isDark;
    final isEnglish =
        context.watch<LocaleProvider>().locale.languageCode == 'en';
    final foreground = isDark ? Colors.white : Colors.black;
    final accent = isDark ? AppColors.primary_dark : AppColors.primary_light;

    return Directionality(
      textDirection: isEnglish ? TextDirection.ltr : TextDirection.rtl,
      child: Scaffold(
        body: PageView.builder(
          controller: _controller,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _images.length,
          onPageChanged: (value) => setState(() => _page = value),
          itemBuilder: (context, index) => Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(_images[index], fit: BoxFit.cover),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: isDark
                        ? const [
                            Colors.transparent,
                            Color(0x1A000000),
                            Color(0xE6000000),
                          ]
                        : const [
                            Color(0x66FFFFFF),
                            Color(0x99FFFFFF),
                            Color(0xF2FFFFFF),
                          ],
                    stops: const [0, 0.48, 1],
                  ),
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(28, 24, 28, 36),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        _titles[index].translate(context),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: foreground,
                          fontSize: 24,
                          height: 1.12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _subtitles[index].translate(context),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: foreground,
                          fontSize: 13,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 28),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          _images.length,
                          (dot) => AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            width: dot == index ? 16 : 8,
                            height: 8,
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            decoration: BoxDecoration(
                              color: dot == index
                                  ? accent
                                  : Colors.grey.shade600,
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          if (index > 0)
                            TextButton(
                              onPressed: _previous,
                              child: Text(
                                AppStrings.previous_button.translate(context),
                                style: TextStyle(color: foreground),
                              ),
                            ),
                          if (index > 0) const Spacer(),
                          if (index == 0)
                            Expanded(
                              child: SizedBox(
                                height: 48,
                                child: _ActionButton(
                                  accent: accent,
                                  isDark: isDark,
                                  label: AppStrings.next_button.translate(
                                    context,
                                  ),
                                  onPressed: _next,
                                ),
                              ),
                            )
                          else
                            SizedBox(
                              width: 112,
                              height: 48,
                              child: _ActionButton(
                                accent: accent,
                                isDark: isDark,
                                label:
                                    (index == _images.length - 1
                                            ? AppStrings.start_button
                                            : AppStrings.next_button)
                                        .translate(context),
                                onPressed: _next,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.accent,
    required this.isDark,
    required this.label,
    required this.onPressed,
  });

  final Color accent;
  final bool isDark;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      style: FilledButton.styleFrom(
        backgroundColor: accent,
        foregroundColor: isDark ? Colors.black : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onPressed: onPressed,
      child: Text(label),
    );
  }
}
