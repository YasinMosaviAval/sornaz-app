import 'package:flutter/material.dart';
import 'package:sornaz/helpers/app_strings.dart';
import 'package:sornaz/helpers/app_translations.dart';
import 'package:sornaz/helpers/app_typography.dart';

class DetectedFrequency extends StatelessWidget {
  final double frequency;

  const DetectedFrequency({
    super.key,
    required this.frequency,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      "${frequency.toStringAsFixed(1)} ${AppStrings.hz.translate(context)}",
      style: AppTypography.tunerDetectedFrequency(context),
    );
  }
}
