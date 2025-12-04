import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sornaz/helpers/app_colors.dart';
import 'package:sornaz/helpers/app_data.dart';
import 'package:sornaz/helpers/app_locale_provider.dart';
import 'package:sornaz/helpers/app_strings.dart';
import 'package:sornaz/helpers/app_translations.dart';
import 'package:sornaz/helpers/app_typography.dart';

class LanguageSwitchTile extends StatelessWidget {
  const LanguageSwitchTile({super.key});

  @override
  Widget build(BuildContext context) {
    final appData = Provider.of<AppData>(context);
    final isDark = appData.isDark;
    // final isPersian = appData.isPersian;
    return Consumer<LocaleProvider>(
      builder: (context, localeProvider, child) {
        final bool isEnglish = localeProvider.locale.languageCode == 'en';
        return ListTile(
          leading: const Icon(Icons.language),
          title: Text(
            AppStrings.language_mode.translate(context),
            style: AppTypography.languageSwitchTileTitle(context),
          ),
          iconColor: isDark
              ? AppColors.text_primary_dark
              : AppColors.text_primary_light,
          textColor: isDark
              ? AppColors.text_primary_dark
              : AppColors.text_primary_light,
          subtitle: Text(
            AppStrings.language_mode_description.translate(context),
            style: AppTypography.languageSwitchTileSubtitle(context),
          ),
          trailing: Switch(
            value: isEnglish,
            onChanged: (value) {
              localeProvider.setLocale(value ? 'en' : 'fa');
              // appData.toggleLanguage();
            },
          ),
          onTap: null,
        );
      },
    );
  }
}
