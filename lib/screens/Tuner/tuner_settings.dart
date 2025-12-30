import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sornaz/components/app_bar.dart';
import 'package:sornaz/components/settings_section_header.dart';
import 'package:sornaz/helpers/app_colors.dart';
import 'package:sornaz/helpers/app_data.dart';
import 'package:sornaz/helpers/app_locale_provider.dart';
import 'package:sornaz/helpers/app_spacing.dart';
import 'package:sornaz/helpers/app_strings.dart';
import 'package:sornaz/helpers/app_translations.dart';
// import 'package:sornaz/screens/Metronome/controller/metronome_controller.dart';
// import 'package:sornaz/screens/Metronome/Components/labeled_slider.dart';

class TunerSettingsPage extends StatefulWidget {
  const TunerSettingsPage({super.key});

  // final TunerController controller;

  // const TunerSettingsPage({super.key, required this.controller});

  @override
  State<TunerSettingsPage> createState() => _TunerSettingsPageState();
}

class _TunerSettingsPageState extends State<TunerSettingsPage> {

  int bpm = 120;

  @override
  Widget build(BuildContext context) {
    // final controller = widget.controller;
    final appData = Provider.of<AppData>(context);
    final isDark = appData.isDark;
    final localeProvider = Provider.of<LocaleProvider>(context, listen: false);
    final isEnglish = localeProvider.locale.languageCode == AppStrings.localization_en;

    return Directionality(
      textDirection: isEnglish ? TextDirection.ltr : TextDirection.rtl,
      child:  Scaffold(
        appBar: SornazAppBar(title: AppStrings.tuner_settings_title.translate(context)),
        backgroundColor: isDark ? AppColors.background_dark : AppColors.background_light,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space_16),
            child: Column(
              children: [
                SettingsSectionHeader(
                  title: AppStrings.volumes.translate(context),
                  leadingIcon: Icons.volume_up,
                  children: [

                  ],
                ),
                // SettingsSectionHeader(
                //   title: AppStrings.tools.translate(context),
                //   leadingIcon: Icons.construction_outlined,
                //   children: [
                    // SettingsSwitchTile(
                    //   title: AppStrings.show_bars_division_title.translate(context),
                    //   subtitle: AppStrings.show_bars_division_subtitle.translate(context),
                      // value: controller.showBarsDivision,
                      // isDark: isDark,
                      // onChanged: (value) {
                        // setState(() {
                        //   controller.showBarsDivision = value;
                        // });
                      // },
                    // )
                //   ],
                // ),
                AppSpacing.sizedBoxH16()
              ],
            ),
          ),
        ),
      )
    );
  }
}

