import 'package:flutter/material.dart';
import 'package:sornaz/helpers/app_colors.dart';
import 'package:sornaz/helpers/app_spacing.dart';
import 'package:sornaz/helpers/app_typography.dart';

class SettingsSwitchTile extends StatelessWidget {
  final String title;
  final String subtitle;

  final bool value;
  final bool isDark;
  final bool enabled;

  final IconData? leadingIcon;
  final ValueChanged<bool> onChanged;

  const SettingsSwitchTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.isDark,
    required this.onChanged,
    this.leadingIcon,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveTitleColor = !enabled
        ? AppColors.settings_switch_tile_not_enabled_title_color(isDark: isDark)
        : AppColors.settings_switch_tile_enabled_title_color(isDark: isDark);

    final effectiveSubtitleColor = !enabled
        ? AppColors.settings_switch_tile_not_enabled_subtitle_color(isDark: isDark)
        : AppColors.settings_switch_tile_enabled_subtitle_color(isDark: isDark);

    return InkWell(
      // onTap: enabled ? () => onChanged(!value) : null,
      borderRadius: BorderRadius.circular(AppSpacing.space_2),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 250),
        opacity: enabled ? 1 : 0.5,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.space_0),
          child: ListTile(
            contentPadding: const EdgeInsets.fromLTRB(
              AppSpacing.space_16, 
              AppSpacing.space_0, 
              AppSpacing.space_24, 
              AppSpacing.space_0
            ),

            // ===== Leading Icon (optional)
            leading: leadingIcon != null
                ? Icon(
                    leadingIcon,
                    color: effectiveTitleColor,
                  )
                : null,

            title: Text(
              title,
              style: AppTypography.settingsSwitchTileItemTitle(context, effectiveTitleColor),
            ),

            subtitle: Text(
              subtitle,
              style: AppTypography.settingsSwitchTileItemSubtitle(context, effectiveSubtitleColor),
            ),

            // ===== Switch
            trailing: Switch(
              value: value,
              onChanged: enabled ? onChanged : null,
              inactiveThumbColor: AppColors.settings_switch_tile_inactive_thumb_color(isDark: isDark),
              inactiveTrackColor: AppColors.settings_switch_tile_inactive_track_color(isDark: isDark),
              activeTrackColor: AppColors.settings_switch_tile_active_track_color(isDark: isDark),
              activeThumbColor: AppColors.settings_switch_tile_active_thumb_color(isDark: isDark),
            ),
            onTap: null,

          ),
        ),
      ),
    );
  }
}
