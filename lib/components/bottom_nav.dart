// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sornaz/helpers/app_colors.dart';
import 'package:sornaz/helpers/app_data.dart';
import 'package:sornaz/helpers/app_navigation.dart';
import 'package:sornaz/helpers/app_strings.dart';
import 'package:sornaz/helpers/app_translations.dart';
import 'package:sornaz/helpers/app_typography.dart';
import 'package:sornaz/screens/Articles/ui/articles_page.dart';
import 'package:sornaz/screens/Players/music_palyer.dart';
import 'package:sornaz/screens/Metronome/screens/metronome_page.dart';
import 'package:sornaz/screens/Tuner/tuner_page.dart';
import 'package:flutter/services.dart';
import 'package:sornaz/screens/Voice%20Recorder/voice_recorder.dart';
// import 'package:sornaz/screens/Profile/voice_recorder/view/voice_recorder_page.dart';

class BottomNavBarWidget3 extends StatelessWidget {
  const BottomNavBarWidget3({super.key});

  // لیست صفحات — مهم: ترتیب باید دقیقاً با آیتم‌ها یکی باشه
  static const List<Widget> _pages = [
    ArticlesPage(),
    MusicPlayerPage(),
    MetronomePage(),
    TunerPage(),
    VoiceRecorderPage2(),
  ];

  void _onItemTapped(BuildContext context, int index) {
    Provider.of<AppData>(context, listen: false).setBottomNavIndex(index);

    navigateWithFade(context, _pages[index]);
  }

  @override
  Widget build(BuildContext context) {
    final appData = Provider.of<AppData>(context);
    final isDark = appData.isDark;
    final currentIndex = appData.bottomNavIndex;

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        if (currentIndex != 0) {
          appData.setBottomNavIndex(0);
        }
      },
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        type: BottomNavigationBarType.fixed,
        backgroundColor: isDark
            ? AppColors.background_dark
            : AppColors.background_light,
        selectedItemColor: isDark
            ? AppColors.primary_dark
            : AppColors.primary_light,
        unselectedItemColor: isDark
            ? AppColors.unselected_item_dark
            : AppColors.unselected_item_light,
        selectedFontSize: 11,
        unselectedFontSize: 11,
        onTap: (index) => _onItemTapped(context, index),
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: AppStrings.home_title.translate(context),
          ),
          // BottomNavigationBarItem(
          //   icon: Icon(Icons.music_note_outlined),
          //   activeIcon: Icon(Icons.music_note),
          //   label: AppStrings.musicSheetTitle.translate(context),
          // ),
          BottomNavigationBarItem(
            icon: Icon(Icons.library_music_outlined),
            activeIcon: Icon(Icons.library_music),
            label: AppStrings.music_player_title.translate(context),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.punch_clock_outlined),
            activeIcon: Icon(Icons.punch_clock),
            label: AppStrings.metronome_title.translate(context),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.tune_outlined),
            activeIcon: Icon(Icons.tune_rounded),
            label: AppStrings.tuner_title.translate(context),
          ),
          // BottomNavigationBarItem(
          //   icon: Icon(Icons.person_outlined),
          //   activeIcon: Icon(Icons.person),
          //   label: AppStrings.profile_title.translate(context),
          // ),
          BottomNavigationBarItem(
            icon: Icon(Icons.keyboard_voice_outlined),
            activeIcon: Icon(Icons.keyboard_voice),
            label: AppStrings.voice_recorder_title.translate(context),
          ),
        ],
      ),
    );
  }
}

class BottomNavBarWidget extends StatefulWidget {
  const BottomNavBarWidget({super.key});
  @override
  State<BottomNavBarWidget> createState() => _BottomNavBarWidgetState();
}

class _BottomNavBarWidgetState extends State<BottomNavBarWidget> {
  DateTime? _lastBackPressed;

  // لیست صفحات — مهم: ترتیب باید دقیقاً با آیتم‌ها یکی باشه
  static const List<Widget> _pages = [
    ArticlesPage(),
    MusicPlayerPage(),
    MetronomePage(),
    TunerPage(),
    VoiceRecorderPage2(),
  ];

  void _onItemTapped(BuildContext context, int index) {
    Provider.of<AppData>(context, listen: false).setBottomNavIndex(index);

    navigateWithFade(context, _pages[index]);
  }

  @override
  Widget build(BuildContext context) {
    final appData = Provider.of<AppData>(context);
    final isDark = appData.isDark;
    final currentIndex = appData.bottomNavIndex;
    // final localeProvider = Provider.of<LocaleProvider>(context, listen: false);
    // final bool isEnglish = localeProvider.locale.languageCode == 'en';

    return Directionality(
      textDirection: TextDirection.ltr,
      child: PopScope(
        // canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
      
          if (currentIndex == 0) {
            // در صفحه اصلی هستیم
            final now = DateTime.now();
            if (_lastBackPressed == null ||
                now.difference(_lastBackPressed!) > const Duration(seconds: 2)) {
              _lastBackPressed = now;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    AppStrings.two_times_press_back_button_for_exit_application
                        .translate(context),
                    style: AppTypography.bottomNavSnackBar(context),
                  ),
                  duration: Duration(seconds: 2),
                  backgroundColor: Colors.black87,
                ),
              );
              return;
            }
            // دوبار در ۲ ثانیه → خروج کامل
            SystemNavigator.pop(); // فقط اندروید
          } else {
            // در صفحه دیگه → برگرد به خانه
            appData.setBottomNavIndex(0);
          }
        },
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          type: BottomNavigationBarType.fixed,
          backgroundColor: isDark
              ? AppColors.surface_dark
              : AppColors.surface_light,
              // ? AppColors.background_dark
              // : AppColors.background_light,
          selectedItemColor: isDark
              ? AppColors.primary_dark
              : AppColors.primary_light,
          unselectedItemColor: isDark
              ? AppColors.unselected_item_dark
              : AppColors.unselected_item_light,
          selectedFontSize: 11,
          unselectedFontSize: 11,
          onTap: (index) => _onItemTapped(context, index),
          items: [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: AppStrings.home_title.translate(context),
            ),
            // BottomNavigationBarItem(
            //   icon: Icon(Icons.music_note_outlined),
            //   activeIcon: Icon(Icons.music_note),
            //   label: AppStrings.music_sheet_title.translate(context),
            // ),
            BottomNavigationBarItem(
              icon: Icon(Icons.library_music_outlined),
              activeIcon: Icon(Icons.library_music),
              label: AppStrings.music_player_title.translate(context),
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.punch_clock_outlined),
              activeIcon: Icon(Icons.punch_clock),
              label: AppStrings.metronome_title.translate(context),
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.tune_outlined),
              activeIcon: Icon(Icons.tune_rounded),
              label: AppStrings.tuner_title.translate(context),
            ),
            // BottomNavigationBarItem(
            //   icon: Icon(Icons.person_outlined),
            //   activeIcon: Icon(Icons.person),
            //   label: AppStrings.profile_title.translate(context),
            // ),
            BottomNavigationBarItem(
              icon: Icon(Icons.keyboard_voice_outlined),
              activeIcon: Icon(Icons.keyboard_voice),
              label: AppStrings.voice_recorder_title.translate(context),
            ),
          ],
        ),
      ),
    );
  }
}
