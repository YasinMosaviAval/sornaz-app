import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sornaz/components/app_bar.dart';
import 'package:sornaz/components/settings_section_header.dart';
import 'package:sornaz/components/settings_switch_tile.dart';
import 'package:sornaz/helpers/app_colors.dart';
import 'package:sornaz/helpers/app_constants.dart';
import 'package:sornaz/helpers/app_data.dart';
import 'package:sornaz/helpers/app_locale_provider.dart';
import 'package:sornaz/helpers/app_spacing.dart';
import 'package:sornaz/helpers/app_strings.dart';
import 'package:sornaz/helpers/app_translations.dart';
import 'package:sornaz/screens/Metronome/controller/metronome_controller.dart';
import 'package:sornaz/screens/Metronome/Components/labeled_slider.dart';

class MetronomeSettingsPage extends StatefulWidget {
  final MetronomeController controller;

  const MetronomeSettingsPage({super.key, required this.controller});

  @override
  State<MetronomeSettingsPage> createState() => _MetronomeSettingsPageState();
}

class _MetronomeSettingsPageState extends State<MetronomeSettingsPage> {

  int bpm = 120;

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final appData = Provider.of<AppData>(context);
    final isDark = appData.isDark;
    final localeProvider = Provider.of<LocaleProvider>(context, listen: false);
    final isEnglish = localeProvider.locale.languageCode == AppConstants.LOCALIZATION_EN;

    return Directionality(
      textDirection: isEnglish ? TextDirection.ltr : TextDirection.rtl,
      child:  Scaffold(
        appBar: SornazAppBar(title: AppStrings.metronome_settings_title.translate(context)),
        backgroundColor: AppColors.metronome_settings_page_background_color(isDark: isDark),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space_16),
            child: Column(
              children: [
                SettingsSectionHeader(
                  title: AppStrings.volumes.translate(context),
                  leadingIcon: Icons.volume_up,
                  children: [
                    LabeledSlider(
                      leadingIcon: Icon(
                        Icons.access_alarm,
                        color: AppColors.metronome_settings_page_leading_icon_color(isDark: isDark),
                        size: AppSpacing.space_20,
                      ),
                      value: controller.accentVolume * 100,
                      isDark: isDark,
                      onChanged: (value) {
                        setState(() => controller.setAccentVolume(value / 100));
                      },
                    ),
                    LabeledSlider(
                      leadingIcon: Icon(
                        Icons.access_time,
                        color: AppColors.metronome_settings_page_leading_icon_color(isDark: isDark),
                        size: AppSpacing.space_20,
                      ),
                      value: controller.tickVolume * 100,
                      isDark: isDark,
                      onChanged: (value) {
                        setState(() => controller.setTickVolume(value / 100));
                      },
                    ),
                    LabeledSlider(
                      leadingIcon: Icon(
                        Icons.graphic_eq,
                        color: AppColors.metronome_settings_page_leading_icon_color(isDark: isDark),
                        size: AppSpacing.space_20,
                      ),
                      value: controller.subTickVolume  * 100,
                      isDark: isDark,
                      onChanged: (value) {
                        setState(() => controller.setSubTickVolume(value / 100));
                      },
                    ),
                  ],
                ),
                SettingsSectionHeader(
                  title: AppStrings.tools.translate(context),
                  leadingIcon: Icons.construction_outlined,
                  children: [
                    SettingsSwitchTile(
                      title: AppStrings.show_bars_division_title.translate(context),
                      subtitle: AppStrings.show_bars_division_subtitle.translate(context),
                      value: controller.showBarsDivision,
                      isDark: isDark,
                      onChanged: (value) {
                        setState(() {
                          controller.showBarsDivision = value;
                        });
                      },
                    ),
                    SettingsSwitchTile(
                      title: AppStrings.show_tap_tempo_title.translate(context),
                      subtitle: AppStrings.show_tap_tempo_subtitle.translate(context),
                      value: controller.showTapTempo,
                      isDark: isDark,
                      onChanged: (value) {
                        setState(() {
                          controller.setShowTapTempo(value);
                        });
                      },
                    ),
                    SettingsSwitchTile(
                      title: AppStrings.enable_timer_stopwatch_title.translate(context),
                      subtitle: AppStrings.enable_timer_stopwatch_subtitle.translate(context),
                      value: controller.showTimerStopwatch,
                      isDark: isDark,
                      onChanged: (value) {
                        setState(() {
                          controller.showTimerStopwatch = value;
                        });
                      },
                    ),
                    SettingsSwitchTile(
                      title: AppStrings.enable_bars_stopwatch_title.translate(context),
                      subtitle: AppStrings.enable_bars_stopwatch_subtitle.translate(context),
                      value: controller.showBarsStopwatch,
                      isDark: isDark,
                      onChanged: (value) {
                        setState(() {
                          controller.showBarsStopwatch = value;
                        });
                      },
                    ),
                  ],
                ),
                AppSpacing.sizedBoxH16()
              ],
            ),
          ),
        ),
      )
    );
  }
}

