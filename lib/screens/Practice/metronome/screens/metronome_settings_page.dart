import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sornaz/components/custom_app_bar.dart';
import 'package:sornaz/components/settings_section_header.dart';
import 'package:sornaz/components/settings_switch_tile.dart';
import 'package:sornaz/helpers/app_colors.dart';
import 'package:sornaz/helpers/app_data.dart';
import 'package:sornaz/helpers/app_locale_provider.dart';
import 'package:sornaz/helpers/app_spacing.dart';
import 'package:sornaz/helpers/app_strings.dart';
import 'package:sornaz/screens/Practice/metronome/controller/metronome_controller.dart';
import 'package:sornaz/screens/Practice/metronome/Components/labeled_slider.dart';

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
    final isEnglish = localeProvider.locale.languageCode == AppStrings.localization_en;

    return Directionality(
      textDirection: isEnglish ? TextDirection.ltr : TextDirection.rtl,
      child:  Scaffold(
        appBar: CustomAppBar(title: 'Metronome Settings'),
        backgroundColor: isDark ? AppColors.background_dark : AppColors.background_light,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space_16),
            child: Column(
              children: [
                SettingsSectionHeader(
                  title: 'Volumes',
                  leadingIcon: Icons.volume_up,
                  children: [
                    LabeledSlider(
                      label: Icon(
                        Icons.access_alarm,
                        color: isDark ? AppColors.text_primary_dark : AppColors.text_primary_light,
                        size: 20,
                      ),
                      value: controller.accentVolume * 100,
                      isDark: isDark,
                      onChanged: (value) {
                        setState(() => controller.setAccentVolume(value / 100));
                      },
                    ),
                    LabeledSlider(
                      label: Icon(
                        Icons.access_time,
                        color: isDark ? AppColors.text_primary_dark : AppColors.text_primary_light,
                        size: 20,
                      ),
                      value: controller.tickVolume * 100,
                      isDark: isDark,
                      onChanged: (value) {
                        setState(() => controller.setTickVolume(value / 100));
                      },
                    ),
                    LabeledSlider(
                      label: Icon(
                        Icons.graphic_eq,
                        color: isDark ? AppColors.text_primary_dark : AppColors.text_primary_light,
                        size: 20,
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
                  title: 'Tools',
                  leadingIcon: Icons.construction_outlined,
                  children: [
                    SettingsSwitchTile(
                      title: 'Show Bars Division',
                      subtitle: 'Set ON for showing bars division',
                      value: controller.showBarsDivision,
                      isDark: isDark,
                      onChanged: (value) {
                        setState(() {
                          controller.showBarsDivision = value;
                        });
                      },
                    ),
                    SettingsSwitchTile(
                      title: 'Show Tap Tempo',
                      subtitle: 'set ON for Showing Tap Tempo',
                      value: controller.showTapTempo,
                      isDark: isDark,
                      onChanged: (value) {
                        setState(() {
                          controller.setShowTapTempo(value);
                        });
                      },
                    ),
          
                    SettingsSwitchTile(
                      title: 'Enable Timer Stopwatch',
                      subtitle: 'set ON for Enable Timer Stopwatch',
                      value: controller.showTimerStopwatch,
                      isDark: isDark,
                      onChanged: (value) {
                        setState(() {
                          controller.showTimerStopwatch = value;
                        });
                      },
                    ),
          
                    SettingsSwitchTile(
                      title: 'Enable Bars Stopwatch',
                      subtitle: 'set ON for Enable Bars Stopwatch',
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

