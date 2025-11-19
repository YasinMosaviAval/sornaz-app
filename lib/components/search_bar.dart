import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sornaz/helpers/app_colors.dart';
import 'package:sornaz/helpers/app_data.dart';
import 'package:sornaz/helpers/app_strings.dart';

class ComponentSearchBar extends StatelessWidget {
  const ComponentSearchBar({super.key});

  @override
  Widget build(BuildContext context) {
    final appData = Provider.of<AppData>(context);
    final isDark = appData.isDark;
    // final theme = Theme.of(context);

    return SizedBox(
      height: 40,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
        child: SizedBox(
          height: 48,
          child: TextField(
            textAlignVertical: TextAlignVertical.center,
            textAlign: TextAlign.start,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              hintText: AppStrings.home_searchbar_hint_text,
              hintStyle: TextStyle(
                fontWeight: FontWeight.w500,
                color: isDark
                    ? AppColors.text_secondary_dark
                    : AppColors.text_secondary_light,
              ),
              prefixIcon: Icon(
                Icons.search,
                size: 24,
                color: isDark
                    ? AppColors.text_secondary_dark
                    : AppColors.text_secondary_light,
              ),
              suffixIcon: Icon(
                Icons.tune,
                size: 22,
                color: isDark
                    ? AppColors.text_secondary_dark
                    : AppColors.text_secondary_light,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 0,
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
