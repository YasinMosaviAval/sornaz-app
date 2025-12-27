import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sornaz/helpers/app_colors.dart';
import 'package:sornaz/helpers/app_data.dart';
import 'package:sornaz/helpers/app_locale_provider.dart';
import 'package:sornaz/helpers/app_spacing.dart';
import 'package:sornaz/helpers/app_strings.dart';
import 'package:sornaz/helpers/app_typography.dart';
import 'package:sornaz/screens/Practice/metronome/controller/metronome_controller.dart';
import 'package:sornaz/screens/Practice/metronome/Components/labeled_slider.dart';
// import 'package:sornaz/screens/Practice/metronome/tempo_terms.dart';

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

    // final tempoName = getTempoName(bpm);

    return Directionality(
      textDirection: isEnglish ? TextDirection.ltr : TextDirection.rtl,
      child:  Scaffold(
        appBar: AppBar(
          title: const Text('Metronome Settings'),
          backgroundColor: isDark? AppColors.surface_dark : AppColors.surface_light,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pop(context, controller.showTapTempo);
            },
          ),
        ),
        backgroundColor: isDark ? AppColors.background_dark : AppColors.background_light,
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space_16),
          child: Column(
            children: [
              
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.space_16,
                  vertical: AppSpacing.space_16,
                ),
                child: Row(
                  children: [
                    Text(
                      "Volumes",
                      style: AppTypography.settingsSectionTitle(context),
                    ),
                  ],
                ),
              ),
              // Accent Volume
              LabeledSlider(
                label: const Icon(Icons.access_alarm),
                value: controller.accentVolume * 100,
                min: 0,
                max: 100,
                divisions: 100,
                unit: '%',
                onChanged: (v) {
                  setState(() => controller.setAccentVolume(v / 100));
                },
              ),

              const SizedBox(height: 16),

              // Tick Volume
              LabeledSlider(
                label: const Icon(Icons.access_time),
                value: controller.tickVolume * 100,
                min: 0,
                max: 100,
                divisions: 100,
                unit: '%',
                onChanged: (v) {
                  setState(() => controller.setTickVolume(v / 100));
                },
              ),

              const SizedBox(height: 16),

              // Tick Volume
              LabeledSlider(
                label: const Icon(Icons.graphic_eq),
                value: controller.subTickVolume  * 100,
                min: 0,
                max: 100,
                divisions: 100,
                unit: '%',
                onChanged: (v) {
                  setState(() => controller.setSubTickVolume(v / 100));
                },
              ),

              const SizedBox(height: 16),
              Divider(),

              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.space_16,
                  vertical: AppSpacing.space_8,
                ),
                child: Row(
                  children: [
                    Text(
                      'Tools',
                      style: AppTypography.settingsSectionTitle(context),
                    ),
                  ],
                ),
              ),
            
              ListTile(
                // contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                // leading: const Icon(Icons.dark_mode),
                // iconColor: isDark ? AppColors.text_primary_dark : AppColors.text_primary_light,
                textColor: isDark ? AppColors.text_primary_dark : AppColors.text_primary_light,
                title: Text(
                  'Show Bars Division',
                  // AppStrings.dark_mode.translate(context),
                  style: AppTypography.settingsItemTitle(context),
                ),
                subtitle: Text(
                  'set ON for Showing Bars Division',
                  // AppStrings.dark_mode_description.translate(context),
                  style: AppTypography.settingsItemSubtitle(context),
                ),
                trailing: Switch(
                  value: controller.showBarsDivision,
                  onChanged:  (value) {
                    setState(() {
                      controller.showBarsDivision = value;
                    });
                  }
                ),
                onTap: null,
              ),

              ListTile(
                // contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                // leading: const Icon(Icons.dark_mode),
                // iconColor: isDark ? AppColors.text_primary_dark : AppColors.text_primary_light,
                textColor: isDark ? AppColors.text_primary_dark : AppColors.text_primary_light,
                title: Text(
                  'Show Tap Tempo',
                  // AppStrings.dark_mode.translate(context),
                  style: AppTypography.settingsItemTitle(context),
                ),
                subtitle: Text(
                  'set ON for Showing Tap Tempo',
                  // AppStrings.dark_mode_description.translate(context),
                  style: AppTypography.settingsItemSubtitle(context),
                ),
                trailing: Switch(
                  value: controller.showTapTempo,
                  onChanged:  (value) {
                    setState(() {
                      controller.setShowTapTempo(value);
                    });
                  }
                ),
                onTap: null,
              ),


              ListTile(
                // contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                // leading: const Icon(Icons.dark_mode),
                // iconColor: isDark ? AppColors.text_primary_dark : AppColors.text_primary_light,
                textColor: isDark ? AppColors.text_primary_dark : AppColors.text_primary_light,
                title: Text(
                  'Enable Timer Stopwatch',
                  // AppStrings.dark_mode.translate(context),
                  style: AppTypography.settingsItemTitle(context),
                ),
                subtitle: Text(
                  'set ON for Enable Timer Stopwatch',
                  // AppStrings.dark_mode_description.translate(context),
                  style: AppTypography.settingsItemSubtitle(context),
                ),
                trailing: Switch(
                  value: controller.showTimerStopwatch,
                  onChanged:  (value) {
                    setState(() {
                      controller.showTimerStopwatch = value;
                    });
                  }
                ),
                onTap: null,
              ),
            
              ListTile(
                // contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                // leading: const Icon(Icons.dark_mode),
                // iconColor: isDark ? AppColors.text_primary_dark : AppColors.text_primary_light,
                textColor: isDark ? AppColors.text_primary_dark : AppColors.text_primary_light,
                title: Text(
                  'Enable Bars Stopwatch',
                  // AppStrings.dark_mode.translate(context),
                  style: AppTypography.settingsItemTitle(context),
                ),
                subtitle: Text(
                  'set ON for Enable Bars Stopwatch',
                  // AppStrings.dark_mode_description.translate(context),
                  style: AppTypography.settingsItemSubtitle(context),
                ),
                trailing: Switch(
                  value: controller.showBarsStopwatch,
                  onChanged:  (value) {
                    setState(() {
                      controller.showBarsStopwatch = value;
                    });
                  }
                ),
                onTap: null,
              ),

            ],
          ),
        ),
      )
    );
  }
}

