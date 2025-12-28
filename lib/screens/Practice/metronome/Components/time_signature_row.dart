import 'package:flutter/material.dart';
import 'package:sornaz/helpers/app_colors.dart';
import 'package:sornaz/helpers/app_spacing.dart';
import 'package:sornaz/helpers/app_typography.dart';
import 'package:sornaz/screens/Practice/metronome/classes/note_length.dart';
import 'package:sornaz/screens/Practice/metronome/classes/time_signature_option.dart';
import 'package:sornaz/screens/Practice/metronome/controller/metronome_controller.dart';

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
      child: Row(
        mainAxisAlignment: controller.showBarsDivision ? MainAxisAlignment.spaceBetween : MainAxisAlignment.center,
        children: [
          if (controller.showBarsDivision)
            Row(
              children: noteLengths.reversed.map((note) {
                final isSelected = controller.selectedNote == note;
                return GestureDetector(
                  onTap: () => controller.setNoteLength(note),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    child: note.nameBox(
                      isDark: isDark,
                      isSelected: isSelected,
                      style: isSelected ? AppTypography.body1(context) : AppTypography.subtitle1(context),
                    ),
                    
                  ),
                );
              }).toList(),
            ),
          
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isDark ? AppColors.clicked_dark : AppColors.clicked_light,
              borderRadius: BorderRadius.circular(4),
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
        ],
      ),
    );
  }
}


