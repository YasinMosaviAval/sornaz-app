import 'package:sornaz/components/scroll_aware_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:sornaz/components/color_palette_picker.dart';
import 'package:provider/provider.dart';
import 'package:sornaz/components/app_bar.dart';
import 'package:sornaz/components/language_switch_tile.dart';
import 'package:sornaz/components/settings_section_header.dart';
import 'package:sornaz/components/settings_switch_tile.dart';
import 'package:sornaz/helpers/app_colors.dart';
import 'package:sornaz/helpers/app_constants.dart';
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
    final bool isEnglish =
        localeProvider.locale.languageCode == AppConstants.LOCALIZATION_EN;

    return Directionality(
      textDirection: isEnglish ? TextDirection.ltr : TextDirection.rtl,
      child: ScrollAwareScaffold(
        appBar: SornazAppBar(
          title: AppStrings.settings_title.translate(context),
        ),
        backgroundColor: AppColors.settings_background_color(isDark: isDark),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.space_16,
            ),
            child: Column(
              children: [
                SettingsSectionHeader(
                  title: AppStrings.appearance_title.translate(context),
                  leadingIcon: Icons.palette_outlined,
                  children: [
                    SettingsSwitchTile(
                      title: AppStrings.dark_mode.translate(context),
                      subtitle: AppStrings.dark_mode_description.translate(
                        context,
                      ),
                      value: appData.isDark,
                      isDark: isDark,
                      leadingIcon: Icons.dark_mode,
                      onChanged: appData.toggleDarkMode,
                    ),
                    LanguageSwitchTile(),
                    const ColorPalettePicker(),
                  ],
                ),
                SettingsSectionHeader(
                  title: AppStrings.elements.translate(context),
                  leadingIcon: Icons.construction_outlined,
                  children: [
                    ListTile(
                      title: Text(
                        AppStrings.font_size.translate(context),
                        style: AppTypography.settingsItemTitle(context),
                      ),
                      textColor: AppColors.settings_list_tile_text_color(
                        isDark: isDark,
                      ),
                      subtitle: Text(
                        AppStrings.font_size_description.translate(context),
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
                              color: AppColors.settings_list_tile_border_color(
                                isDark: isDark,
                              ),
                            ),
                            color:
                                AppColors.settings_list_tile_decoration_color(
                                  isDark: isDark,
                                ),
                          ),
                          child: Text(
                            appData.fontSize.toInt().toString(),
                            style: AppTypography.settingsItemContent(context),
                            textDirection: TextDirection.ltr,
                          ),
                        ),
                      ),
                    ),
                    Slider(
                      activeColor: AppColors.settings_slider_active_color(
                        isDark: isDark,
                      ),
                      inactiveColor: AppColors.settings_slider_inactive_color(
                        isDark: isDark,
                      ),
                      label: appData.fontSize.toInt().toString(),
                      value: appData.fontSize,
                      min: -2,
                      max: 2,
                      divisions: 4,
                      onChanged: appData.updateFontSize,
                    ),
                    ListTile(
                      title: Text(
                        AppStrings.font_weight.translate(context),
                        style: AppTypography.settingsItemTitle(context),
                      ),
                      textColor: AppColors.settings_list_tile_text_color(
                        isDark: isDark,
                      ),
                      subtitle: Text(
                        AppStrings.font_weight_description.translate(context),
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
                              color: AppColors.settings_list_tile_border_color(
                                isDark: isDark,
                              ),
                            ),
                            color:
                                AppColors.settings_list_tile_decoration_color(
                                  isDark: isDark,
                                ),
                          ),
                          child: Text(
                            appData.fontWeight.toInt().toString(),
                            style: AppTypography.settingsItemContent(context),
                            textDirection: TextDirection.ltr,
                          ),
                        ),
                      ),
                    ),
                    Slider(
                      activeColor: AppColors.settings_slider_active_color(
                        isDark: isDark,
                      ),
                      inactiveColor: AppColors.settings_slider_inactive_color(
                        isDark: isDark,
                      ),
                      label: appData.fontWeight.toInt().toString(),
                      value: appData.fontWeight,
                      min: 0,
                      max: 5,
                      divisions: 5,
                      onChanged: appData.updateFontWeight,
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
                        dropdownColor: AppColors.settings_drop_down_color(
                          isDark: isDark,
                        ),
                        items: [
                          DropdownMenuItem(
                            value: isEnglish
                                ? AppTypography.iran_sansx_en
                                : AppTypography.iran_sansx_fa,
                            child: Text(
                              AppStrings.font_iran_sans.translate(context),
                              style: AppTypography.settingsDropdownItem(
                                context,
                              ),
                            ),
                          ),
                          DropdownMenuItem(
                            value: isEnglish
                                ? AppTypography.iran_yekan_en
                                : AppTypography.iran_yekan_fa,
                            child: Text(
                              AppStrings.font_iran_yekan.translate(context),
                              style: AppTypography.settingsDropdownItem(
                                context,
                              ),
                            ),
                          ),
                          DropdownMenuItem(
                            value: isEnglish
                                ? AppTypography.kalameh_en
                                : AppTypography.kalameh_fa,
                            child: Text(
                              AppStrings.font_kalameh.translate(context),
                              style: AppTypography.settingsDropdownItem(
                                context,
                              ),
                            ),
                          ),
                          DropdownMenuItem(
                            value: AppTypography.peyda,
                            child: Text(
                              AppStrings.font_peyda.translate(context),
                              style: AppTypography.settingsDropdownItem(
                                context,
                              ),
                            ),
                          ),
                          DropdownMenuItem(
                            value: isEnglish
                                ? AppTypography.sahel_en
                                : AppTypography.sahel_fa,
                            child: Text(
                              AppStrings.font_sahel.translate(context),
                              style: AppTypography.settingsDropdownItem(
                                context,
                              ),
                            ),
                          ),
                          DropdownMenuItem(
                            value: isEnglish
                                ? AppTypography.vazir_en
                                : AppTypography.vazir_fa,
                            child: Text(
                              AppStrings.font_vazir.translate(context),
                              style: AppTypography.settingsDropdownItem(
                                context,
                              ),
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            appData.updateFontFamily(value);
                          }
                        },
                        iconEnabledColor: AppColors.settings_icon_enabled_color(
                          isDark: isDark,
                        ),
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
