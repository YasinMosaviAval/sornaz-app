import 'package:flutter/material.dart';
import 'package:sornaz/helpers/app_colors.dart';
import 'package:sornaz/helpers/app_spacing.dart';
import 'package:sornaz/helpers/app_typography.dart';

class LabeledSlider extends StatelessWidget {
  final Widget leadingIcon;
  final double value;
  final double min;
  final double max;
  final String label;
  final String unit;
  final bool isDark;
  final int? divisions;
  final ValueChanged<double> onChanged;
  final bool enabled;

  const LabeledSlider({
    super.key,
    required this.leadingIcon,
    required this.value,
    required this.onChanged,
    required this.isDark,
    this.label = '',
    this.unit = '',
    this.min = 0,
    this.max = 100,
    this.divisions = 100,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final step = divisions == null || divisions == 0
        ? 0.0
        : (max - min) / divisions!;
    final displayValue = step > 0 && step < 1
        ? value.toStringAsFixed(1)
        : value.toStringAsFixed(0);
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.space_24,
              AppSpacing.space_12,
              AppSpacing.space_24,
              AppSpacing.space_0,
            ),
            child: Row(
              children: [
                leadingIcon,
                AppSpacing.sizedBoxW4(),
                Text(
                  label == '' ? ' ${value.round()}$unit' : label,
                  style: AppTypography.metronomeLabeledSlider(context),
                ),
              ],
            ),
          ),
          Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            activeColor: AppColors.labled_slider_active_color(isDark: isDark),
            inactiveColor: AppColors.labled_slider_inactive_color(
              isDark: isDark,
            ),
            label: '$displayValue$unit',
            onChanged: enabled ? onChanged : null,
          ),
        ],
      ),
    );
  }
}
