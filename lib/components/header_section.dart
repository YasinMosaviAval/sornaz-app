import 'package:flutter/material.dart';
import 'package:sornaz/helpers/app_spacing.dart';
import 'package:sornaz/helpers/app_strings.dart';
import 'package:sornaz/helpers/app_translations.dart';
import 'package:sornaz/helpers/app_typography.dart';

class HeaderSection extends StatelessWidget {
  final String title;
  final ThemeData theme;

  const HeaderSection({super.key, required this.title, required this.theme});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.space_16,
          vertical: AppSpacing.space_8,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: AppTypography.headerSectionTitle()),
            TextButton(
              onPressed: () {},
              child: Text(
                AppStrings.view_all_link.translate(context),
                style: AppTypography.headerSectionViewAllLink(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
