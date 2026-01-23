import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sornaz/components/settings_switch_tile.dart';
import 'package:sornaz/helpers/app_constants.dart';
import 'package:sornaz/helpers/app_data.dart';
import 'package:sornaz/helpers/app_locale_provider.dart';
import 'package:sornaz/helpers/app_strings.dart';
import 'package:sornaz/helpers/app_translations.dart';

class LanguageSwitchTile extends StatelessWidget {
  const LanguageSwitchTile({super.key});

  @override
  Widget build(BuildContext context) {
    final appData = Provider.of<AppData>(context);
    final isDark = appData.isDark;
    return Consumer<LocaleProvider>(
      builder: (context, localeProvider, child) {
        final bool isEnglish = localeProvider.locale.languageCode == AppConstants.LOCALIZATION_EN;
        return SettingsSwitchTile(
          title: AppStrings.language_mode.translate(context),
          subtitle: AppStrings.language_mode_description.translate(context),
          value: isEnglish,
          isDark: isDark,
          // enabled: !controller.isPlaying,
          leadingIcon: Icons.language,
          onChanged: (value) {
            localeProvider.setLocale(value ? AppConstants.LOCALIZATION_EN : AppConstants.LOCALIZATION_FA);
            if(appData.fontFamily.substring(appData.fontFamily.length-2) == AppConstants.LOCALIZATION_EN) {
              appData.updateFontFamily(appData.fontFamily.replaceAll(AppConstants.LOCALIZATION_EN, AppConstants.LOCALIZATION_FA));
            } else {
              appData.updateFontFamily(appData.fontFamily.replaceAll(AppConstants.LOCALIZATION_FA, AppConstants.LOCALIZATION_EN));
            }
          },
        );
      },
    );
  }
}
