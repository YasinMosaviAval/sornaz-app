import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sornaz/helpers/app_colors.dart';
import 'package:sornaz/helpers/app_data.dart';
import 'package:sornaz/helpers/app_navigation.dart';

class SectionTitle extends StatelessWidget {
  final String title;
  final String? viewAll;
  final Widget? viewAllLink;

  const SectionTitle({
    super.key,
    required this.title,
    this.viewAll,
    this.viewAllLink,
  });

  @override
  Widget build(BuildContext context) {
    final appData = Provider.of<AppData>(context);
    final isDark = appData.isDark;
    // final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            color: isDark
                ? AppColors.text_primary_dark
                : AppColors.text_primary_light,
            fontWeight: FontWeight.w900,
          ),
        ),
        if (viewAll != null)
          TextButton(
            onPressed: () => navigateWithFade(context, viewAllLink!),
            child: Text(
              viewAll!,
              style: TextStyle(
                color: isDark
                    ? AppColors.primary_dark
                    : AppColors.primary_light,
              ),
            ),
          ),
      ],
    );
  }
}
