import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sornaz/components/settings_switch_tile.dart';
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
        final bool isEnglish = localeProvider.locale.languageCode == AppStrings.localization_en;
        return SettingsSwitchTile(
          title: AppStrings.language_mode.translate(context),
          subtitle: AppStrings.language_mode_description.translate(context),
          value: isEnglish,
          isDark: isDark,
          // enabled: !controller.isPlaying,
          leadingIcon: Icons.language,
          onChanged: (value) {
            localeProvider.setLocale(value ? AppStrings.localization_en : AppStrings.localization_fa);
            if(appData.fontFamily.substring(appData.fontFamily.length-2) == AppStrings.localization_en) {
              appData.updateFontFamily(appData.fontFamily.replaceAll(AppStrings.localization_en, AppStrings.localization_fa));
            } else {
              appData.updateFontFamily(appData.fontFamily.replaceAll(AppStrings.localization_fa, AppStrings.localization_en));
            }
          },
        );
      },
    );
  }
}
