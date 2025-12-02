import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.about_us_title.translate(context)),
        titleTextStyle: AppTypography.aboutUsAppBarTitle,
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.space_16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    appData.aboutUsTitle1,
                    style: AppTypography.aboutUsTitle,
                  ),
                  const SizedBox(height: AppSpacing.space_8),
                  Text(appData.aboutUsText1, style: AppTypography.aboutUsBody),
                  const SizedBox(height: AppSpacing.space_16),
                  Text(
                    appData.aboutUsTitle2,
                    style: AppTypography.aboutUsTitle,
                  ),
                  const SizedBox(height: AppSpacing.space_8),
                  Text(appData.aboutUsText2, style: AppTypography.aboutUsBody),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
