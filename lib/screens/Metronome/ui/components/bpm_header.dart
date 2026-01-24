import 'package:flutter/material.dart';
import 'package:sornaz/helpers/app_constants.dart';
import 'package:sornaz/helpers/app_spacing.dart';
import 'package:sornaz/helpers/app_typography.dart';

class BpmHeader extends StatelessWidget {
  final int bpm;
  final String tempoName;

  const BpmHeader({
    super.key,
    required this.bpm,
    required this.tempoName,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Directionality(
          textDirection: TextDirection.ltr,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(bpm.toString(), style: AppTypography.metronomeBpmHeaderNumber(context)),
              AppSpacing.sizedBoxW8(),
              Text(AppConstants.BPM_CAPITAL, style: AppTypography.metronomeBpmHeaderUnit(context)),
            ],
          ),
        ),
        Text(tempoName, style: AppTypography.metronomeBpmHeaderName(context)),
      ],
    );
  }
}
