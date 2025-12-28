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
    final effectiveTextColor = !enabled
        ? (isDark
            ? AppColors.text_secondary_dark
            : AppColors.text_secondary_light)
        : (isDark
            ? AppColors.text_primary_dark
            : AppColors.text_primary_light);

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
                    color: effectiveTextColor,
                  )
                : null,

            title: Text(
              title,
              style: AppTypography.settingsItemTitle(context).copyWith(
                color: effectiveTextColor,
              ),
            ),

            subtitle: Text(
              subtitle,
              style: AppTypography.settingsItemSubtitle(context).copyWith(
                color: effectiveTextColor.withAlpha(200),
              ),
            ),

            // ===== Switch
            trailing: Switch(
              value: value,
              onChanged: enabled ? onChanged : null,

              inactiveThumbColor: isDark
                  ? AppColors.text_secondary_dark
                  : AppColors.text_secondary_light,

              inactiveTrackColor: isDark
                  ? AppColors.surface_dark
                  : AppColors.surface_light,

              activeTrackColor: isDark
                  ? AppColors.primary_dark
                  : AppColors.primary_light,

              activeThumbColor: isDark
                  ? AppColors.surface_dark
                  : AppColors.surface_light,
            ),
            onTap: null,

          ),
        ),
      ),
    );
  }
}
