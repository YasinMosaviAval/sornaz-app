import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sornaz/components/language_switch_tile.dart';
import 'package:sornaz/helpers/app_colors.dart';
import 'package:sornaz/helpers/app_data.dart';
import 'package:sornaz/helpers/app_locale_provider.dart';
// import 'package:sornaz/helpers/app_locale_provider.dart';
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
    final bool isEnglish = localeProvider.locale.languageCode == 'en';

    return Directionality(
      textDirection: isEnglish ? TextDirection.ltr : TextDirection.rtl,
      child: Scaffold(
        backgroundColor: isDark
            ? AppColors.background_dark
            : AppColors.background_light,
        appBar: AppBar(
          title: Text(
            AppStrings.settings_title.translate(context),
            style: AppTypography.settingsAppBar,
          ),
          backgroundColor: isDark
              ? AppColors.surface_dark
              : AppColors.surface_light,
          iconTheme: IconThemeData(
            color: isDark
                ? AppColors.text_primary_dark
                : AppColors.text_primary_light,
          ),
        ),
        body: ListView(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.space_16,
                vertical: AppSpacing.space_8,
              ),
              child: Text(
                AppStrings.notification_title.translate(context),
                style: AppTypography.settingsSectionTitle,
              ),
            ),
            // SwitchListTile(
            //   title: Text(AppStrings.push_notifications.translate(context), style: AppTypography.settingsItemTitle,),
            //   subtitle: Text(
            //     AppStrings.push_notifications_subtitle.translate(context), style: AppTypography.settingsItemSubtitle
            //   ),
            //   value: appData.pushNotifications,
            //   onChanged: appData.togglePushNotifications,
            // ),
            ListTile(
              // contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              leading: const Icon(Icons.dark_mode),
              iconColor: isDark
                  ? AppColors.text_primary_dark
                  : AppColors.text_primary_light,
              textColor: isDark
                  ? AppColors.text_primary_dark
                  : AppColors.text_primary_light,
              title: Text(
                AppStrings.dark_mode.translate(context),
                style: AppTypography.settingsItemTitle,
              ),
              subtitle: Text(
                AppStrings.dark_mode_description.translate(context),
                style: AppTypography.settingsItemSubtitle,
              ),
              trailing: Switch(
                value: appData.isDark,
                onChanged: appData.toggleDarkMode,
              ),
              onTap: null,
            ),
            LanguageSwitchTile(),
            // SwitchListTile(
            //   title: const Text(AppStrings.new_course_alerts.translate(context), style: AppTypography.settingsItemTitle),
            //   subtitle: const Text(AppStrings.new_course_alerts_description.translate(context), style: AppTypography.settingsItemSubtitle),
            //   value: appData.newCourseAlerts,
            //   onChanged: appData.toggleNewCourseAlerts,
            // ),
            // const Divider(),
            // Padding(
            //   padding: const EdgeInsets.symmetric(
            //     horizontal: AppSpacing.space_16,
            //     vertical: AppSpacing.space_8,
            //   ),
            //   child: Text(
            //     AppStrings.dataTitle.translate(context),
            //     style: AppTypography.settingsSectionTitle,
            //   ),
            // ),
            // SwitchListTile(
            //   title: const Text(AppStrings.use_wifi.translate(context), style: AppTypography.settingsItemTitle),
            //   subtitle: const Text(AppStrings.use_wifi_description.translate(context), style: AppTypography.settingsItemSubtitle),
            //   value: appData.useWifiOverData,
            //   onChanged: appData.toggleUseWifiOverData,
            // ),
            // SwitchListTile(
            //   title: const Text(AppStrings.auto_download.translate(context), style: AppTypography.settingsItemTitle),
            //   subtitle: const Text(AppStrings.auto_download_description.translate(context), style: AppTypography.settingsItemSubtitle),
            //   value: appData.autoDownload,
            //   onChanged: appData.toggleAutoDownload,
            // ),
            Divider(
              color: isDark ? AppColors.border_dark : AppColors.border_light,
            ),
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.space_16,
                vertical: AppSpacing.space_8,
              ),
              child: Text(
                AppStrings.elements.translate(context),
                style: AppTypography.settingsSectionTitle,
              ),
            ),
            ListTile(
              title: Text(
                AppStrings.text_size.translate(context),
                style: AppTypography.settingsItemTitle,
              ),
              textColor: isDark
                  ? AppColors.text_primary_dark
                  : AppColors.text_primary_light,
              subtitle: Text(
                AppStrings.text_size_description.translate(context),
                style: AppTypography.settingsItemSubtitle,
              ),
              trailing: Container(
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
                  style: AppTypography.settingsItemContent,
                ),
              ),
            ),

            Slider(
              activeColor: isDark
                  ? AppColors.text_primary_dark
                  : AppColors.text_primary_light,
              inactiveColor: isDark
                  ? AppColors.text_secondary_dark
                  : AppColors.text_secondary_light,
              // thumbColor: isDark
              //     ? AppColors.text_primary_dark
              //     : AppColors.text_primary_light,
              // secondaryActiveColor: isDark
              //     ? AppColors.text_primary_dark
              //     : AppColors.text_primary_light,
              value: appData.textSize,
              min: 10,
              max: 20,
              divisions: 10,
              label: appData.textSize.toInt().toString(),
              onChanged: appData.updateTextSize,
            ),

            ListTile(
              title: Text(
                "انتخاب فونت",
                style: AppTypography.settingsItemTitle,
              ),
              subtitle: Text(
                "فونت دلخواه خود را انتخاب کنید",
                style: AppTypography.settingsItemSubtitle,
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
                      "ایران سنس FN",
                      style: AppTypography.settingsDropdownItem,
                    ),
                  ),
                  DropdownMenuItem(
                    value: AppTypography.iran_sansx,
                    child: Text(
                      "ایران سنس",
                      style: AppTypography.settingsDropdownItem,
                    ),
                  ),
                  DropdownMenuItem(
                    value: AppTypography.iran_yekan,
                    child: Text(
                      "ایران یکان",
                      style: AppTypography.settingsDropdownItem,
                    ),
                  ),
                  DropdownMenuItem(
                    value: AppTypography.iran_yekan_fn,
                    child: Text(
                      "ایران یکان FN",
                      style: AppTypography.settingsDropdownItem,
                    ),
                  ),
                  DropdownMenuItem(
                    value: AppTypography.kalameh,
                    child: Text(
                      "کلمه",
                      style: AppTypography.settingsDropdownItem,
                    ),
                  ),
                  DropdownMenuItem(
                    value: AppTypography.kalameh_fn,
                    child: Text(
                      "کلمه FN",
                      style: AppTypography.settingsDropdownItem,
                    ),
                  ),
                  DropdownMenuItem(
                    value: AppTypography.peyda,
                    child: Text(
                      "پیدا",
                      style: AppTypography.settingsDropdownItem,
                    ),
                  ),
                  DropdownMenuItem(
                    value: AppTypography.tahrir,
                    child: Text(
                      "تحریر",
                      style: AppTypography.settingsDropdownItem,
                    ),
                  ),
                  DropdownMenuItem(
                    value: AppTypography.sahel,
                    child: Text(
                      "ساحل",
                      style: AppTypography.settingsDropdownItem,
                    ),
                  ),
                  DropdownMenuItem(
                    value: AppTypography.sahel_fn,
                    child: Text(
                      "ساحل FN",
                      style: AppTypography.settingsDropdownItem,
                    ),
                  ),
                  DropdownMenuItem(
                    value: AppTypography.vazir,
                    child: Text(
                      "وزیر",
                      style: AppTypography.settingsDropdownItem,
                    ),
                  ),
                  DropdownMenuItem(
                    value: AppTypography.vazir_fn,
                    child: Text(
                      "وزیر FN",
                      style: AppTypography.settingsDropdownItem,
                    ),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    appData.updateFontFamily(value);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
