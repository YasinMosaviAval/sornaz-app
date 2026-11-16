import 'package:flutter/material.dart';

/// A folder-style row; depth and expansion stay controlled by the feature.
class AppHierarchyRow extends StatelessWidget {
  const AppHierarchyRow({
    super.key,
    required this.depth,
    required this.title,
    required this.icon,
    required this.onTap,
    this.subtitle,
    this.actions,
    this.expanded = false,
    this.expandable = false,
    this.enabled = true,
    this.iconColor,
    this.titleAlignment,
    this.horizontalTitleGap,
    this.minLeadingWidth,
  });
  final int depth;
  final Widget title;
  final Widget? subtitle, actions;
  final IconData icon;
  final Color? iconColor;
  final ListTileTitleAlignment? titleAlignment;
  final double? horizontalTitleGap, minLeadingWidth;
  final VoidCallback? onTap;
  final bool expanded, expandable, enabled;

  static Color background(BuildContext context, int depth) {
    if (depth <= 0) return Colors.transparent;
    final theme = Theme.of(context);
    final opacity = theme.brightness == Brightness.dark ? .06 : .035;
    return Color.alphaBlend(
      theme.colorScheme.primary.withValues(alpha: opacity * depth.clamp(1, 4)),
      theme.colorScheme.surface,
    );
  }

  @override
  Widget build(BuildContext context) => Material(
    color: background(context, depth),
    child: ListTile(
      titleAlignment: titleAlignment,
      horizontalTitleGap: horizontalTitleGap,
      minLeadingWidth: minLeadingWidth,
      enabled: enabled,
      contentPadding: EdgeInsetsDirectional.only(start: 12 + depth * 12.0),
      leading: Icon(
        icon,
        color:
            iconColor ??
            (expanded ? Theme.of(context).colorScheme.primary : null),
      ),
      title: title,
      subtitle: subtitle,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (expandable)
            Icon(
              expanded ? Icons.expand_less : Icons.expand_more,
              color: iconColor,
            ),
          ?actions,
        ],
      ),
      onTap: enabled ? onTap : null,
    ),
  );
}
