import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sornaz/helpers/app_colors.dart';
import 'package:sornaz/helpers/app_data.dart';
import 'package:sornaz/helpers/app_spacing.dart';
import 'package:sornaz/helpers/app_typography.dart';

class SornazAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final IconData? centerIcon;
  final VoidCallback? onCenterIconPressed;

  final bool showBackButton;
  final VoidCallback? onBack;

  final List<Widget>? actions;
  final bool centerTitle;
  final double elevation;

  final double iconSize;
  final double padding;



  const SornazAppBar({
    super.key,

    this.title,
    this.centerIcon,
    this.onCenterIconPressed,

    this.showBackButton = true,
    this.onBack,

    this.actions,
    this.centerTitle = false,
    this.elevation = 0,

    this.iconSize = AppSpacing.space_32,
    this.padding = AppSpacing.space_16,
  });



  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<AppData>(context).isDark;

    final textColor = AppColors.sornaz_app_bar_text_color(isDark: isDark);

    return AppBar(
      automaticallyImplyLeading: false,
      centerTitle: centerTitle,
      elevation: elevation,
      backgroundColor: AppColors.sornaz_app_bar_background_color(isDark: isDark),
      
      leading: showBackButton
          ? IconButton(
              icon: const Icon(Icons.arrow_back),
              color: textColor,
              onPressed: onBack ?? () => Navigator.pop(context),
            )
          : null,

      title: title != null
          ? Text(
              title!,
              style: AppTypography.sornazAppBarTitle(context, textColor),
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
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
