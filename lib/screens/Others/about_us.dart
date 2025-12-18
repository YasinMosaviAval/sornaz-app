import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sornaz/classes/accordion.dart';
import 'package:sornaz/components/title_description.dart';
import 'package:sornaz/helpers/app_colors.dart';
import 'package:sornaz/helpers/app_data.dart';
import 'package:sornaz/helpers/app_locale_provider.dart';
import 'package:sornaz/helpers/app_spacing.dart';
import 'package:sornaz/helpers/app_strings.dart';
import 'package:sornaz/helpers/app_translations.dart';
import 'package:sornaz/helpers/app_typography.dart';

class AboutUsPage extends StatelessWidget {
  const AboutUsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final appData = Provider.of<AppData>(context);
    final bool isDark = appData.isDark;
    final localeProvider = Provider.of<LocaleProvider>(context, listen: false);
    final bool isEnglish = localeProvider.locale.languageCode == AppStrings.localization_en;

    return Directionality(
      textDirection: isEnglish ? TextDirection.ltr : TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(AppStrings.about_us_title.translate(context)),
          titleTextStyle: AppTypography.aboutUsAppBarTitle(context),
          backgroundColor: isDark ? AppColors.surface_dark : AppColors.surface_light,
          iconTheme: IconThemeData(
            color: isDark ? AppColors.text_primary_dark: AppColors.text_primary_light,
          ),
        ),
        backgroundColor: isDark ? AppColors.background_dark : AppColors.background_light,
        body: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.space_16),
                child: Accordion(
                  items: [
                    AccordionItem(
                      title: AppStrings.about_us_page_title.translate(context),
                      description: AppStrings.about_us_page_description.translate(context),
                    ),
                    AccordionItem(
                      title: AppStrings.about_us_our_mission_title.translate(context),
                      description: AppStrings.about_us_our_mission_description.translate(context),
                    ),

                    AccordionItem(
                      title: AppStrings.about_us_our_vision_title.translate(context),
                      description: AppStrings.about_us_our_vision_description.translate(context),
                    ),

                    AccordionItem(
                      title: AppStrings.about_us_our_values_title.translate(context),
                      description: AppStrings.about_us_our_values_description.translate(context)
                    ),

                    AccordionItem(
                      title: AppStrings.about_us_our_story_title.translate(context),
                      description: AppStrings.about_us_our_story_description.translate(context)
                    ),

                    AccordionItem(
                      title: AppStrings.about_us_our_team_title.translate(context),
                      description: AppStrings.about_us_our_team_description.translate(context)
                    ),

                    AccordionItem(
                      title: AppStrings.about_us_key_features_title.translate(context),
                      description: AppStrings.about_us_key_features_description.translate(context)
                    ),

                    AccordionItem(
                      title: AppStrings.about_us_our_commitment_title.translate(context),
                      description: AppStrings.about_us_our_commitment_description.translate(context)
                    ),

                    AccordionItem(
                      title: AppStrings.about_us_contact_information_title.translate(context),
                      description: AppStrings.about_us_contact_information_description.translate(context)
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
