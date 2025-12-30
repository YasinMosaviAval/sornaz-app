import 'package:flutter/material.dart';
import 'package:sornaz/helpers/app_spacing.dart';
import 'package:sornaz/helpers/app_strings.dart';
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
              Text(bpm.toString(), style: AppTypography.body0(context)),
              AppSpacing.sizedBoxW8(),
              Text(AppStrings.bpm_capital, style: AppTypography.subtitle3(context)),
            ],
          ),
        ),
        Text(tempoName, style: AppTypography.subtitle1(context)),
      ],
    );
  }
}
