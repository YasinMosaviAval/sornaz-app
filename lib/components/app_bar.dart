import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sornaz/helpers/app_colors.dart';
import 'package:sornaz/helpers/app_data.dart';
import 'package:sornaz/helpers/app_spacing.dart';
import 'package:sornaz/helpers/app_typography.dart';

class SornazAppBar extends StatelessWidget implements PreferredSizeWidget {
  /// ===== Content
  final String? title;
  final IconData? centerIcon;
  final VoidCallback? onCenterIconPressed;

  /// ===== Navigation
  final bool showBackButton;
  final VoidCallback? onBack;

  /// ===== Layout
  final List<Widget>? actions;
  final bool centerTitle;
  final double elevation;

  /// ===== Style
  final Color? backgroundColor;
  final double iconSize;
  final double padding;



  const SornazAppBar({
    super.key,

    // content
    this.title,
    this.centerIcon,
    this.onCenterIconPressed,

    // navigation
    this.showBackButton = true,
    this.onBack,

    // layout
    this.actions,
    this.centerTitle = false,
    this.elevation = 0,

    // style
    this.backgroundColor,
    this.iconSize = AppSpacing.space_32,
    this.padding = AppSpacing.space_16,
  });



  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<AppData>(context).isDark;

    final textColor = isDark
        ? AppColors.text_primary_dark
        : AppColors.text_primary_light;

    return AppBar(
      automaticallyImplyLeading: false,
      centerTitle: centerTitle,
      elevation: elevation,
      backgroundColor: backgroundColor ?? (isDark ? AppColors.surface_dark : AppColors.surface_light),
      
      /// ===== Leading (Back)
      leading: showBackButton
          ? IconButton(
              icon: const Icon(Icons.arrow_back),
              color: textColor,
              onPressed: onBack ?? () => Navigator.pop(context),
            )
          : null,

      /// ===== Title / Center Icon
      title: title != null
          ? Text(
              title!,
              style: AppTypography.headline3(context).copyWith(
                color: textColor,
              ),
            )
          : centerIcon != null
              ? IconButton(
                  icon: Icon(centerIcon),
                  iconSize: iconSize,
                  color: textColor,
                  onPressed: onCenterIconPressed,
                  padding: EdgeInsets.symmetric(horizontal: padding),
                )
              : null,
      titleSpacing: 0,
      /// ===== Actions
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
