import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sornaz/classes/accordion.dart';
import 'package:sornaz/components/title_description.dart';
import 'package:sornaz/helpers/app_colors.dart';
import 'package:sornaz/helpers/app_data.dart';
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
    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.about_us_title.translate(context)),
        titleTextStyle: AppTypography.aboutUsAppBarTitle(context),
        backgroundColor: isDark
            ? AppColors.surface_dark
            : AppColors.surface_light,
        iconTheme: IconThemeData(
          color: isDark
              ? AppColors.text_primary_dark
              : AppColors.text_primary_light,
        ),
      ),
      backgroundColor: isDark
          ? AppColors.background_dark
          : AppColors.background_light,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.space_16),
              child: Accordion(
                items: [
                  AccordionItem(
                    title: AppStrings.aboutUsTitle1,
                    description: AppStrings.aboutUsText1,
                  ),
                  AccordionItem(
                    title: AppStrings.aboutUsTitle2,
                    description: AppStrings.aboutUsText2,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
