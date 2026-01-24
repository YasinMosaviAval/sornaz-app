import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sornaz/components/app_bar.dart';
import 'package:sornaz/components/justified_text.dart';
import 'package:sornaz/components/settings_section_header.dart';
import 'package:sornaz/helpers/app_colors.dart';
import 'package:sornaz/helpers/app_constants.dart';
import 'package:sornaz/helpers/app_data.dart';
import 'package:sornaz/helpers/app_locale_provider.dart';
import 'package:sornaz/helpers/app_spacing.dart';
import 'package:sornaz/helpers/app_strings.dart';
import 'package:sornaz/helpers/app_translations.dart';

class AboutUsPage extends StatelessWidget {
  const AboutUsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final appData = Provider.of<AppData>(context);
    final bool isDark = appData.isDark;
    final localeProvider = Provider.of<LocaleProvider>(context, listen: false);
    final bool isEnglish = localeProvider.locale.languageCode == AppConstants.LOCALIZATION_EN;

    return Directionality(
      textDirection: isEnglish ? TextDirection.ltr : TextDirection.rtl,
      child: Scaffold(
        appBar: SornazAppBar(title: AppStrings.about_us_title.translate(context)),
        backgroundColor: AppColors.about_us_background_color(isDark: isDark),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space_16),
            child: Column(
              children: [
                SettingsSectionHeader(
                  title: AppStrings.about_us_page_title.translate(context),
                  // leadingIcon: Icons.info_outline,
                  leadingIcon: Icons.auto_stories_outlined,
                  children: [
                    JustifiedText(text: AppStrings.about_us_page_description.translate(context)),
                  ],
                ),
                SettingsSectionHeader(
                  title: AppStrings.about_us_our_mission_title.translate(context),
                  leadingIcon: Icons.rocket_launch_outlined,
                  children: [
                    JustifiedText(text: AppStrings.about_us_our_mission_description.translate(context)),
                  ],
                ),
                SettingsSectionHeader(
                  title: AppStrings.about_us_our_vision_title.translate(context),
                  leadingIcon: Icons.visibility_outlined,
                  children: [
                    JustifiedText(text: AppStrings.about_us_our_vision_description.translate(context)),
                  ],
                ),
                SettingsSectionHeader(
                  title: AppStrings.about_us_our_values_title.translate(context),
                  leadingIcon: Icons.star_border_outlined,
                  // leadingIcon: Icons.diamond_outlined,
                  // leadingIcon: Icons.favorite_border_outlined,
                  children: [
                    JustifiedText(text: AppStrings.about_us_our_values_description.translate(context)),
                  ],
                ),
                SettingsSectionHeader(
                  title: AppStrings.about_us_our_story_title.translate(context),
                  leadingIcon: Icons.timeline_outlined,
                  // leadingIcon: Icons.history_outlined,
                  children: [
                    JustifiedText(text: AppStrings.about_us_our_story_description.translate(context)),
                  ],
                ),
                SettingsSectionHeader(
                  title: AppStrings.about_us_our_team_title.translate(context),
                  // leadingIcon: Icons.supervisor_account_outlined,
                  // leadingIcon: Icons.people_outline_outlined,
                  leadingIcon: Icons.group_outlined,
                  children: [
                    JustifiedText(text: AppStrings.about_us_our_team_description.translate(context)),
                  ],
                ),
                SettingsSectionHeader(
                  title: AppStrings.about_us_key_features_title.translate(context),
                  leadingIcon: Icons.check_circle_outline,
                  children: [
                    JustifiedText(text: AppStrings.about_us_key_features_description.translate(context)),
                  ],
                ),
                SettingsSectionHeader(
                  title: AppStrings.about_us_our_commitment_title.translate(context),
                  // leadingIcon: Icons.verified_outlined,
                  // leadingIcon: Icons.shield_outlined,
                  leadingIcon: Icons.handshake_outlined,
                  children: [
                    JustifiedText(text: AppStrings.about_us_our_commitment_description.translate(context)),
                  ],
                ),
                SettingsSectionHeader(
                  title: AppStrings.about_us_contact_information_title.translate(context),
                  // leadingIcon: Icons.phone_in_talk_outlined,
                  leadingIcon: Icons.phone_outlined,
                  children: [
                    JustifiedText(text: AppStrings.about_us_contact_information_description.translate(context)),
                  ],
                ),
                AppSpacing.sizedBoxH16(),
              ],
            )),
        ),
      ),
    );
  }
}
