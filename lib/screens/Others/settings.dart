import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sornaz/components/language_switch_tile.dart';
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
        backgroundColor: isDark
            ? AppColors.background_dark
            : AppColors.background_light,
        appBar: AppBar(
          title: Text(
            AppStrings.settings_title.translate(context),
            style: AppTypography.settingsAppBarTitle(context),
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
                style: AppTypography.settingsSectionTitle(context),
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
                style: AppTypography.settingsItemTitle(context),
              ),
              subtitle: Text(
                AppStrings.dark_mode_description.translate(context),
                style: AppTypography.settingsItemSubtitle(context),
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
                style: AppTypography.settingsSectionTitle(context),
              ),
            ),
            ListTile(
              title: Text(
                AppStrings.text_size.translate(context),
                style: AppTypography.settingsItemTitle(context),
              ),
              textColor: isDark
                  ? AppColors.text_primary_dark
                  : AppColors.text_primary_light,
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
              activeColor: isDark
                  ? AppColors.text_primary_dark
                  : AppColors.text_primary_light,
              inactiveColor: isDark
                  ? AppColors.text_secondary_dark
                  : AppColors.text_secondary_light,
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
                  DropdownMenuItem(
                    value: AppTypography.tahrir,
                    child: Text(
                      AppStrings.font_tahrir.translate(context),
                      style: AppTypography.settingsDropdownItem(context),
                    ),
                  ),
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

// ListTile(
//   title: Text("روش ذخیره‌سازی کش فایل‌ها"),
//   subtitle: Text(provider.storageType == StorageType.hive ? "Hive (فعلی)" : "Isar (فعلی)"),
//   onTap: () async {
//     final newType = provider.storageType == StorageType.hive 
//         ? StorageType.isar 
//         : StorageType.hive;

//     await provider.setStorageType(newType);

//     // کش قبلی رو پاک کن و دوباره اسکن کن
//     await libraryManager.clearCache();
//     await libraryManager.loadOrScan();

//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text("روش ذخیره‌سازی تغییر کرد. کش پاک شد و دوباره لود می‌شه.")),
//     );
//   },
// ),

          ],
        ),
      ),
    );
  }
}
