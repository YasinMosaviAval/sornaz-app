import 'package:sornaz/components/app_top_bar_direction.dart';
import 'package:flutter/material.dart';

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

    this.iconSize = AppTopBarDirection.iconSize,
    this.padding = AppTopBarDirection.contentInset,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.colorScheme.onSurface;

    return AppTopBarDirection(
      child: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: centerTitle,
        elevation: elevation,
        backgroundColor: theme.appBarTheme.backgroundColor,

        leading: showBackButton
            ? BackButton(
                color: textColor,
                onPressed: onBack ?? () => Navigator.pop(context),
              )
            : null,

        title: title != null
            ? Text(title!, style: theme.appBarTheme.titleTextStyle)
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
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(48);
}
