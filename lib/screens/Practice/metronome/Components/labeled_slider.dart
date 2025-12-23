import 'package:flutter/material.dart';
import 'package:sornaz/helpers/app_spacing.dart';

// Widget buildSlider({
//   required double value,
//   required double min,
//   required double max,
//   int? divisions,
//   required ValueChanged<double> onChanged,
// }) {
//   return Slider(
//     value: value,
//     min: min,
//     max: max,
//     divisions: divisions,
//     onChanged: onChanged,
//   );
// }


class LabeledSlider extends StatelessWidget {
  final Widget label;
  final double value;
  final double min;
  final double max;
  final int? divisions;
  final String unit;
  final ValueChanged<double> onChanged;

  const LabeledSlider({
    super.key,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.divisions,
    this.unit = '',
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space_24),
          child: Row(
            children: [
              label,
              Text(
                ' ${value.round()}$unit',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          label: '${value.round()}$unit',
          onChanged: onChanged,
        ),
      ],
    );
  }
}
