import 'package:flutter/material.dart';

class A4Slider extends StatelessWidget {
  final double value;
  final ValueChanged<double> onChanged;

  const A4Slider({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Slider(
      min: 420,
      max: 460,
      divisions: 40,
      value: value,
      label: value.toStringAsFixed(0),
      onChanged: onChanged,
    );
  }
}
