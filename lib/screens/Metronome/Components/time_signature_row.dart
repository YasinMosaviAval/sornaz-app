import 'package:flutter/material.dart';
import 'package:sornaz/helpers/app_colors.dart';
import 'package:sornaz/helpers/app_spacing.dart';
import 'package:sornaz/helpers/app_typography.dart';
import 'package:sornaz/screens/Metronome/classes/note_length.dart';
import 'package:sornaz/screens/Metronome/classes/time_signature_option.dart';
import 'package:sornaz/screens/Metronome/controller/metronome_controller.dart';

class TimeSignatureSection extends StatelessWidget {
  final MetronomeController controller;
  final TimeSignatureOption selected;
  final bool isDark;
  final ValueChanged<TimeSignatureOption> onChanged;

  const TimeSignatureSection({
    super.key,
    required this.controller,
    required this.selected,
    required this.isDark,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space_24),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Row(
          mainAxisAlignment: controller.showBarsDivision ? MainAxisAlignment.spaceBetween : MainAxisAlignment.center,
          children: [
            Container(
              width: AppSpacing.space_48,
              height: AppSpacing.space_48,
              decoration: BoxDecoration(
                color: isDark ? AppColors.clicked_dark : AppColors.clicked_light,
                borderRadius: BorderRadius.circular(AppSpacing.space_4),
              ),
              child: DropdownButton<TimeSignatureOption>(
                value: selected,
                isExpanded: true,
                underline: const SizedBox(),
                icon: const SizedBox(),
                dropdownColor: isDark ? AppColors.surface_dark : AppColors.surface_light,
                items: timeSignatures.map((option) {
                  return DropdownMenuItem(
                    value: option,
                    child: Center(
                      child: Text(
                        option.label, 
                        style: AppTypography.body1(context),
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (v) {
                  if (v != null) onChanged(v);
                },
              ),
            ),
        
            if (controller.showBarsDivision)
              Row(
                children: noteLengths.map((note) {
                  final isSelected = controller.selectedNote == note;
                  return GestureDetector(
                    onTap: () => controller.setNoteLength(note),
                    child: Container(
                      margin: EdgeInsets.symmetric(horizontal: AppSpacing.space_8),
                      child: note.nameBox(
                        isDark: isDark,
                        isSelected: isSelected,
                        style: isSelected ? AppTypography.body1(context) : AppTypography.subtitle1(context),
                      ),
                      
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }
}


