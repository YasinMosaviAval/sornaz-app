import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sornaz/helpers/app_colors.dart';
import 'package:sornaz/helpers/app_data.dart';
import 'package:sornaz/helpers/app_spacing.dart';
import 'package:sornaz/helpers/app_strings.dart';
import 'package:sornaz/helpers/app_translations.dart';
import 'package:sornaz/helpers/app_typography.dart';

class ComponentSearchBar extends StatelessWidget {
  const ComponentSearchBar({super.key});

  @override
  Widget build(BuildContext context) {
    final appData = Provider.of<AppData>(context);
    final isDark = appData.isDark;
    // final theme = Theme.of(context);

    return SizedBox(
      height: AppSpacing.space_40,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.space_24,
          AppSpacing.space_0,
          AppSpacing.space_24,
          AppSpacing.space_0,
        ),
        child: SizedBox(
          height: AppSpacing.space_48,
          child: TextField(
            textAlignVertical: TextAlignVertical.center,
            textAlign: TextAlign.start,
            style: AppTypography.searchBarText(context),
            decoration: InputDecoration(
              hintText: AppStrings.home_searchbar_hint.translate(context),
              hintStyle: AppTypography.searchBarHint(context),
              prefixIcon: Icon(
                Icons.search,
                size: AppSpacing.space_24,
                color: AppColors.component_search_bar_prefix_icon_color(isDark: isDark),
              ),
              suffixIcon: Icon(
                Icons.tune,
                size: AppSpacing.space_22,
                color: AppColors.component_search_bar_suffix_icon_color(isDark: isDark),
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: AppSpacing.space_16,
                vertical: AppSpacing.space_0,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: AppColors.component_search_bar_fill_color(isDark: isDark),
            ),
          ),
        ),
      ),
    );
  }
}
