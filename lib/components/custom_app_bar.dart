import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sornaz/helpers/app_colors.dart';
import 'package:sornaz/helpers/app_data.dart';
import 'package:sornaz/helpers/app_spacing.dart';
import 'package:sornaz/helpers/app_typography.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final Color? backgroundColor;
  final bool showBackButton;
  final VoidCallback? onBack;
  final List<Widget>? actions;
  final double elevation;

  const CustomAppBar({
    super.key,
    required this.title,
    this.backgroundColor,
    this.showBackButton = true,
    this.onBack,
    this.actions,
    this.elevation = 0,
  });

  @override
  Widget build(BuildContext context) {
    final appData = Provider.of<AppData>(context);
    final isDark = appData.isDark;

    return AppBar(
      title: Text(
        title,
        style: AppTypography.headline3(context),
      ),
      titleSpacing: AppSpacing.space_0,
      backgroundColor: backgroundColor ?? (isDark ? AppColors.surface_dark : AppColors.surface_light),
      elevation: elevation,
      leading: showBackButton
          ? IconButton(
              icon: const Icon(Icons.arrow_back),
              color: isDark
                  ? AppColors.text_primary_dark
                  : AppColors.text_primary_light,
              onPressed: onBack ?? () => Navigator.pop(context)
            )
          : null,
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

