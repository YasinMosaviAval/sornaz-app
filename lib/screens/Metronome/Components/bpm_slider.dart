import 'package:flutter/material.dart';
import 'package:sornaz/helpers/app_colors.dart';

class BpmSlider extends StatelessWidget {
  final int bpm;
  final bool isDark;
  final ValueChanged<int> onChanged;

  const BpmSlider({
    super.key,
    required this.bpm,
    required this.isDark,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Slider(
      value: bpm.toDouble(),
      min: 40,
      max: 200,
      activeColor: isDark ? AppColors.primary_dark : AppColors.primary_light,
      inactiveColor: isDark ? AppColors.text_secondary_dark : AppColors.text_secondary_light,
      onChanged: (v) => onChanged(v.toInt()),
    );
  }
}
