import 'package:flutter/material.dart';
import 'package:sornaz/helpers/app_strings.dart';
import 'package:sornaz/helpers/app_translations.dart';
import 'package:sornaz/helpers/app_typography.dart';
import 'package:sornaz/screens/Tuner/utils/tuner_math.dart';

class DetectedFrequency extends StatelessWidget {
  final double frequency;

  const DetectedFrequency({
    super.key,
    required this.frequency,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      "فرکانس: ${TunerMath.removeUnusedZERO(frequency)} ${AppStrings.hz.translate(context)}",
      style: AppTypography.tunerDetectedFrequency(context),
    );
  }
}
