import 'dart:math';
import 'package:flutter/material.dart';
import 'package:sornaz/helpers/app_spacing.dart';
import 'package:sornaz/helpers/app_strings.dart';
import 'package:sornaz/helpers/app_translations.dart';
import 'package:sornaz/helpers/app_typography.dart';

class FrequencyInfoRow extends StatelessWidget {
  final String note;
  final double cents;
  final double noteFreq;

  const FrequencyInfoRow({
    super.key,
    required this.note,
    required this.cents,
    required this.noteFreq,
  });

  int _getOctave(double freq) {
    if (freq <= 0) return 4;
    return (log(freq / 440.0) / log(2) + 4).floor();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space_24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            children: [
              Text(
                cents.toStringAsFixed(2),
                style: AppTypography.tunerCentDifference(context),
              ),
              Text(
                AppStrings.cents.translate(context),
                style: AppTypography.tunerCentUnitTitle(context),
              ),
            ],
          ),
          Row(
            children: [
              Text(
                _getOctave(noteFreq).toString(),
                style: AppTypography.tunerNoteOctave(context),
              ),
              const SizedBox(width: AppSpacing.space_4),
              Text(
                note,
                style: AppTypography.tunerNoteName(context),
              ),
            ],
          ),
          Column(
            children: [
              Text(
                noteFreq.toStringAsFixed(2),
                style: AppTypography.tunerNearNoteFrequency(context),
              ),
              Text(
                AppStrings.hertz.translate(context),
                style: AppTypography.tunerHertzUnitTitle(context),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
