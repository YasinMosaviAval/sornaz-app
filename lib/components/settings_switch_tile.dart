import 'package:flutter/material.dart';
import '../helpers/app_appearance.dart';

/// Shared switch row; a null callback always remains read-only.
class SettingsSwitchTile extends StatelessWidget {
  const SettingsSwitchTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.isDark = false,
    this.leadingIcon,
    this.enabled = true,
    this.horizontalPadding,
    this.contentPadding,
  }) : _title = null,
       _subtitle = null,
       _secondary = null;
  const SettingsSwitchTile.widgets({
    super.key,
    required Widget title,
    Widget? subtitle,
    Widget? secondary,
    required this.value,
    required this.onChanged,
    this.enabled = true,
    this.contentPadding,
  }) : _title = title,
       _subtitle = subtitle,
       _secondary = secondary,
       title = '',
       subtitle = '',
       isDark = false,
       leadingIcon = null,
       horizontalPadding = null;
  final String title, subtitle;
  final Widget? _title, _subtitle, _secondary;
  final bool value, enabled;

  /// Compatibility field; colors follow the application theme.
  final bool isDark;
  final double? horizontalPadding;
  final EdgeInsetsGeometry? contentPadding;
  final IconData? leadingIcon;
  final ValueChanged<bool>? onChanged;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      type: MaterialType.transparency,
      child: ListTileTheme.merge(
        titleTextStyle: theme.textTheme.bodyMedium,
        subtitleTextStyle: theme.textTheme.bodySmall,
        child: SwitchListTile(
          shape: RoundedRectangleBorder(borderRadius: appRadius(context)),
          contentPadding:
              contentPadding ??
              EdgeInsets.symmetric(horizontal: horizontalPadding ?? 12),
          title: _title ?? Text(title),
          subtitle: _subtitle ?? (subtitle.isEmpty ? null : Text(subtitle)),
          secondary:
              _secondary ?? (leadingIcon == null ? null : Icon(leadingIcon)),
          value: value,
          onChanged: enabled ? onChanged : null,
        ),
      ),
    );
  }
}
