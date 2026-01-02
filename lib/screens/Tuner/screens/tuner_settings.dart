import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sornaz/components/app_bar.dart';
import 'package:sornaz/components/settings_section_header.dart';
import 'package:sornaz/components/settings_switch_tile.dart';
import 'package:sornaz/helpers/app_colors.dart';
import 'package:sornaz/helpers/app_data.dart';
import 'package:sornaz/helpers/app_locale_provider.dart';
import 'package:sornaz/helpers/app_spacing.dart';
import 'package:sornaz/helpers/app_strings.dart';
import 'package:sornaz/helpers/app_translations.dart';
import 'package:sornaz/screens/Metronome/Components/labeled_slider.dart';
import 'package:sornaz/screens/Tuner/controller/tuner_provider.dart';

class TunerSettingsPage extends StatelessWidget {
  const TunerSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final tuner = context.watch<TunerProvider>();
    final appData = context.watch<AppData>();
    final isDark = appData.isDark;

    final localeProvider = Provider.of<LocaleProvider>(context, listen: false);
    final isEnglish = localeProvider.locale.languageCode == AppStrings.localization_en;

    return Directionality(
      textDirection: isEnglish ? TextDirection.ltr : TextDirection.rtl,
      child: Scaffold(
        appBar: SornazAppBar(
          title: AppStrings.tuner_settings_title.translate(context),
        ),
        backgroundColor:
            isDark ? AppColors.background_dark : AppColors.background_light,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.space_16,
            ),
            child: Column(
              children: [
                SettingsSectionHeader(
                  title: AppStrings.volumes.translate(context),
                  leadingIcon: Icons.volume_up,
                  children: [
                    LabeledSlider(
                      leadingIcon: Icon(
                        Icons.access_alarm,
                        color: isDark ? AppColors.text_primary_dark : AppColors.text_primary_light,
                        size: AppSpacing.space_20,
                      ),
                      // label: "Note duration (seconds)",
                      // unit: "seconds",
                      // unit: "ثانیه",
                      label: "کشش نت : ${tuner.noteDurationSeconds} ثانیه",
                      value: tuner.noteDurationSeconds.toDouble(),
                      min: 1,
                      max: 60,
                      divisions: 59,
                      isDark: isDark,
                      onChanged: (value) {
                        tuner.setNoteDuration(value.toInt());
                      },
                    ),
                    LabeledSlider(
                      leadingIcon: Icon(
                        Icons.tune,
                        color: isDark ? AppColors.text_primary_dark : AppColors.text_primary_light,
                        size: AppSpacing.space_20,
                      ),
                      label: "${AppStrings.set_base_frequency.translate(context)}${tuner.a4.toStringAsFixed(0)} هرتز",
                      value: tuner.a4,
                      min: 420,
                      max: 460,
                      divisions: 40,
                      isDark: isDark,
                      onChanged: tuner.setA4,
                    ),
                  ],
                ),
                SettingsSectionHeader(
                  title: AppStrings.tools.translate(context),
                  leadingIcon: Icons.construction_outlined,
                  children: [
                    LabeledSlider(
                      leadingIcon: Icon(
                        Icons.flag_outlined,
                        color: isDark ? AppColors.text_primary_dark : AppColors.text_primary_light,
                        size: AppSpacing.space_20,
                      ),
                      label: "اکتاو شروع پیانو",
                      value: tuner.keyboardSettings.startOctave.toDouble(),
                      min: 1,
                      max: 6,
                      divisions: 5,
                      isDark: isDark,
                      onChanged: (value) => tuner.setStartOctave(value.toInt()),
                    ),
                    LabeledSlider(
                      leadingIcon: Icon(
                        Icons.arrow_forward_outlined,
                        color: isDark ? AppColors.text_primary_dark : AppColors.text_primary_light,
                        size: AppSpacing.space_20,
                      ),
                      label: "تعداد اکتاو",
                      value: tuner.keyboardSettings.octaveCount.toDouble(),
                      min: 1,
                      max: 6,
                      divisions: 5,
                      isDark: isDark,
                      onChanged: (value) => tuner.setOctaveCount(value.toInt()),
                    ),
                    SettingsSwitchTile(
                      title: "هایلایت A4",
                      subtitle: "برای هایلایت کلید A4 روشن کنید",
                      value: tuner.keyboardSettings.highlightA4,
                      isDark: isDark,
                      onChanged: tuner.setHighlightA4,
                    ),
                    SettingsSwitchTile(
                      title: "فرکانس کلیدهای سفید",
                      subtitle: "برای نمایش فرکانس روی کلیدهای سفید روشن کنید",
                      value: tuner.keyboardSettings.showWhiteKeyFrequencies,
                      isDark: isDark,
                      onChanged: (value) => tuner.setShowWhiteKeyFrequencies(value),
                    ),
                    SettingsSwitchTile(
                      title: "فرکانس کلیدهای سیاه",
                      subtitle: "برای نمایش فرکانس روی کلیدهای سیاه روشن کنید",
                      value: tuner.keyboardSettings.showBlackKeyFrequencies,
                      isDark: isDark,
                      onChanged: (value) => tuner.setShowBlackKeyFrequencies(value),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

