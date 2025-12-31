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
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.space_24, 
            AppSpacing.space_12, 
            AppSpacing.space_24, 
            AppSpacing.space_0
          ),
          child: Row(
            children: [
              leadingIcon,
              AppSpacing.sizedBoxW4(),
              Text(
                label == '' ? ' ${value.round()}$unit' : label,
                style: AppTypography.body2(context),
              ),

            ],
          ),
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          activeColor: isDark ? AppColors.primary_dark : AppColors.primary_light,
          inactiveColor: isDark ? AppColors.text_secondary_dark : AppColors.text_secondary_light,
          label: '${value.round()}$unit',
          onChanged: onChanged,
        ),
      ],
    );
  }
}
