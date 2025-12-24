import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sornaz/helpers/app_colors.dart';
import 'package:sornaz/helpers/app_data.dart';
import 'package:sornaz/helpers/app_locale_provider.dart';
import 'package:sornaz/helpers/app_strings.dart';
import 'package:sornaz/screens/Practice/metronome/metronome_controller.dart';
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
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
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

            ],
          ),
        ),
      )
    );
  }
}

