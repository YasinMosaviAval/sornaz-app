import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sornaz/components/app_bar.dart';
import 'package:sornaz/components/language_switch_tile.dart';
import 'package:sornaz/components/settings_section_header.dart';
import 'package:sornaz/components/settings_switch_tile.dart';
import 'package:sornaz/helpers/app_colors.dart';
import 'package:sornaz/helpers/app_data.dart';
import 'package:sornaz/helpers/app_locale_provider.dart';
import 'package:sornaz/helpers/app_spacing.dart';
import 'package:sornaz/helpers/app_strings.dart';
import 'package:sornaz/helpers/app_translations.dart';
import 'package:sornaz/helpers/app_typography.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final appData = Provider.of<AppData>(context);
    final bool isDark = appData.isDark;
    final localeProvider = Provider.of<LocaleProvider>(context, listen: false);
    // final theme = Theme.of(context);
    final bool isEnglish = localeProvider.locale.languageCode == AppStrings.localization_en;

    return Directionality(
      textDirection: isEnglish ? TextDirection.ltr : TextDirection.rtl,
      child: Scaffold(
        appBar: SornazAppBar(title: AppStrings.settings_title.translate(context)),
        backgroundColor: isDark ? AppColors.background_dark : AppColors.background_light,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space_16),
            child: Column(
              children: [
                SettingsSectionHeader(
                  title: AppStrings.appearance_title.translate(context),
                  leadingIcon: Icons.palette_outlined,
                  children: [
                    SettingsSwitchTile(
                      title: AppStrings.dark_mode.translate(context),
                      subtitle: AppStrings.dark_mode_description.translate(context),
                      value: appData.isDark,
                      isDark: isDark,
                      leadingIcon: Icons.dark_mode,
                      onChanged: appData.toggleDarkMode,
                    ),
                    LanguageSwitchTile(),
                  ],
                ),
                SettingsSectionHeader(
                  title: AppStrings.elements.translate(context),
                  leadingIcon: Icons.construction_outlined,
                  children: [
                    ListTile(
                      title: Text(
                        AppStrings.text_size.translate(context),
                        style: AppTypography.settingsItemTitle(context),
                      ),
                      textColor: isDark ? AppColors.text_primary_dark : AppColors.text_primary_light,
                      subtitle: Text(
                        AppStrings.text_size_description.translate(context),
                        style: AppTypography.settingsItemSubtitle(context),
                      ),
                      trailing: SizedBox(
                        height: AppSpacing.space_36,
                        width: AppSpacing.space_36,
                        child: Container(
                          alignment: Alignment.center,
                          padding: const EdgeInsets.all(AppSpacing.space_8),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: isDark
                                  ? AppColors.border_dark
                                  : AppColors.border_light,
                            ),
                            color: isDark
                                ? AppColors.surface_dark
                                : AppColors.surface_light,
                          ),
                          child: Text(
                            appData.textSize.toInt().toString(),
                            style: AppTypography.settingsItemContent(context),
                          ),
                        ),
                      ),
                    ),
                    Slider(
                      activeColor: isDark ? AppColors.text_primary_dark : AppColors.text_primary_light,
                      inactiveColor: isDark ? AppColors.text_secondary_dark : AppColors.text_secondary_light,
                      label: appData.textSize.toInt().toString(),
                      value: appData.textSize,
                      min: -2,
                      max: 2,
                      divisions: 4,
                      onChanged: appData.updateTextSize,
                    ),
                    ListTile(
                      title: Text(
                        AppStrings.select_font_title.translate(context),
                        style: AppTypography.settingsItemTitle(context),
                      ),
                      subtitle: Text(
                        AppStrings.select_font_description.translate(context),
                        style: AppTypography.settingsItemSubtitle(context),
                      ),
                      trailing: DropdownButton<String>(
                        value: appData.fontFamily,
                        dropdownColor: isDark
                            ? AppColors.surface_dark
                            : AppColors.surface_light,
                        items: [
                          DropdownMenuItem(
                            value: AppTypography.iran_sansx_fn,
                            child: Text(
                              AppStrings.font_iran_sans.translate(context),
                              style: AppTypography.settingsDropdownItem(context),
                            ),
                          ),
                          DropdownMenuItem(
                            value: AppTypography.iran_yekan_fn,
                            child: Text(
                              AppStrings.font_iran_yekan.translate(context),
                              style: AppTypography.settingsDropdownItem(context),
                            ),
                          ),
                          DropdownMenuItem(
                            value: AppTypography.kalameh_fn,
                            child: Text(
                              AppStrings.font_kalameh.translate(context),
                              style: AppTypography.settingsDropdownItem(context),
                            ),
                          ),
                          DropdownMenuItem(
                            value: AppTypography.peyda,
                            child: Text(
                              AppStrings.font_peyda.translate(context),
                              style: AppTypography.settingsDropdownItem(context),
                            ),
                          ),
                          // DropdownMenuItem(
                          //   value: AppTypography.tahrir,
                          //   child: Text(
                          //     AppStrings.font_tahrir.translate(context),
                          //     style: AppTypography.settingsDropdownItem(context),
                          //   ),
                          // ),
                          DropdownMenuItem(
                            value: AppTypography.sahel_fn,
                            child: Text(
                              AppStrings.font_sahel.translate(context),
                              style: AppTypography.settingsDropdownItem(context),
                            ),
                          ),
                          DropdownMenuItem(
                            value: AppTypography.vazir_fn,
                            child: Text(
                              AppStrings.font_vazir.translate(context),
                              style: AppTypography.settingsDropdownItem(context),
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            appData.updateFontFamily(value);
                          }
                        },
                        iconEnabledColor: isDark
                            ? AppColors.text_primary_dark
                            : AppColors.text_primary_light,
                      ),
                    ),
                  ],
                ),
                AppSpacing.sizedBoxH16(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
