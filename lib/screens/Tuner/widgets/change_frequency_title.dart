import 'package:flutter/material.dart';
import 'package:sornaz/helpers/app_spacing.dart';
import 'package:sornaz/helpers/app_strings.dart';
import 'package:sornaz/helpers/app_translations.dart';
import 'package:sornaz/helpers/app_typography.dart';

class ChangeFrequencyTitleWidget extends StatelessWidget {
  final double a4;

  const ChangeFrequencyTitleWidget({
    super.key,
    required this.a4,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space_24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "${a4.toStringAsFixed(0)} ${AppStrings.hz.translate(context)}",
            style: AppTypography.tunerA4Frequency(context),
          ),
          const SizedBox(width: AppSpacing.space_4),
          Text(
            AppStrings.set_base_frequency.translate(context),
            style: AppTypography.tunerSetBaseFrequency(context),
          ),
        ],
      ),
    );
  }
}
