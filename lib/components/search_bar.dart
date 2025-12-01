import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sornaz/helpers/app_colors.dart';
import 'package:sornaz/helpers/app_data.dart';
import 'package:sornaz/helpers/app_spacing.dart';
import 'package:sornaz/helpers/app_strings.dart';
import 'package:sornaz/helpers/app_translations.dart';

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
            style: TextStyle(
              fontSize: AppSpacing.space_12,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              hintText: AppStrings.home_searchbar_hint.translate(context),
              hintStyle: TextStyle(
                fontWeight: FontWeight.w500,
                color: isDark
                    ? AppColors.text_secondary_dark
                    : AppColors.text_secondary_light,
              ),
              prefixIcon: Icon(
                Icons.search,
                size: AppSpacing.space_24,
                color: isDark
                    ? AppColors.text_secondary_dark
                    : AppColors.text_secondary_light,
              ),
              suffixIcon: Icon(
                Icons.tune,
                size: AppSpacing.space_22,
                color: isDark
                    ? AppColors.text_secondary_dark
                    : AppColors.text_secondary_light,
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
              fillColor: isDark
                  ? AppColors.surface_dark
                  : AppColors.surface_light,
            ),
          ),
        ),
      ),
    );
  }
}
