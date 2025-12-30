import 'package:flutter/material.dart';
import 'package:sornaz/helpers/app_colors.dart';
import 'package:sornaz/helpers/app_spacing.dart';
import 'package:sornaz/helpers/app_strings.dart';
import 'package:sornaz/helpers/app_translations.dart';
import 'package:sornaz/screens/Metronome/controller/metronome_controller.dart';

class StopModeSection extends StatelessWidget {
  final MetronomeController controller;
  final bool isDark;
  final int selectedBars;
  final int selectedMinutes;
  final int selectedSeconds;
  final ValueChanged<int> onBarsChanged;
  final void Function(int, int) onTimerChanged;

  const StopModeSection({
    super.key,
    required this.controller,
    required this.isDark,
    required this.selectedBars,
    required this.selectedMinutes,
    required this.selectedSeconds,
    required this.onBarsChanged,
    required this.onTimerChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isSelectedTimer = controller.stopMode == StopMode.timer;
    final isSelectedBars = controller.stopMode == StopMode.bars;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (controller.showTimerStopwatch)
              ChoiceChip(
                label: Text(AppStrings.timer.translate(context)),
                labelStyle: TextStyle(
                  color: isSelectedTimer
                    ? (isDark ? AppColors.text_primary_light : AppColors.text_primary_dark)
                    : (isDark ? AppColors.text_secondary_dark : AppColors.text_secondary_light),
                ),
                checkmarkColor: isDark? AppColors.text_primary_light : AppColors.text_primary_dark,
                selectedColor: isDark? AppColors.primary_dark : AppColors.primary_light,
                backgroundColor: isDark ? AppColors.surface_dark : AppColors.surface_light,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(AppSpacing.space_2)),
                  side: BorderSide(
                    color: Colors.transparent,
                    width: 0,
                  )
                ),
                selected: isSelectedTimer,
                onSelected: (value) {
                  value ? onTimerChanged(selectedMinutes, selectedSeconds) : controller.disableStopConditions();
                },
              ),
            const SizedBox(width: 12),
            if (controller.showBarsStopwatch)
              ChoiceChip(
                label: Text(AppStrings.bars.translate(context)),
                labelStyle: TextStyle(
                  color: isSelectedBars
                    ? (isDark ? AppColors.text_primary_light : AppColors.text_primary_dark)
                    : (isDark ? AppColors.text_secondary_dark : AppColors.text_secondary_light),
                ),
                checkmarkColor: isDark? AppColors.text_primary_light : AppColors.text_primary_dark,
                selectedColor: isDark? AppColors.primary_dark : AppColors.primary_light,
                backgroundColor: isDark ? AppColors.surface_dark : AppColors.surface_light,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(AppSpacing.space_2)),
                  side: BorderSide(
                    color: Colors.transparent,
                    width: 0,
                  )
                ),
                selected: isSelectedBars,
                onSelected: (value) {
                  value ? onBarsChanged(selectedBars) : controller.disableStopConditions();
                },
              ),
          ],
        ),
      ],
    );
  }
}


