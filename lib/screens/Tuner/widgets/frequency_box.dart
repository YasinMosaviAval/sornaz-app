import 'package:flutter/material.dart';
import 'package:sornaz/helpers/app_colors.dart';
import 'package:sornaz/helpers/app_spacing.dart';

class FrequencyBox extends StatelessWidget {
  final double cents;
  final bool inRange;

  const FrequencyBox({
    super.key,
    required this.cents,
    required this.inRange,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return SizedBox(
      height: AppSpacing.space_300,
      child: Stack(
        children: [
          Container(color: AppColors.surface_dark),

          Positioned(
            left: width / 2 - 50,
            top: 0,
            bottom: 0,
            child: Container(
              width: 100,
              color: inRange
                  ? AppColors.success.withAlpha(100)
                  : AppColors.success.withAlpha(40),
            ),
          ),

          Positioned(
            left: width / 2 + (cents * 3),
            top: 0,
            bottom: 0,
            child: Container(
              width: 4,
              color: inRange ? Colors.green : Colors.red,
            ),
          ),
        ],
      ),
    );
  }
}
