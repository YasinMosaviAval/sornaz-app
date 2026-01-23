import 'package:flutter/material.dart';
import 'package:sornaz/helpers/app_colors.dart';
import 'package:sornaz/helpers/app_spacing.dart';

class MetronomeButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final TextStyle style;
  final bool isDark;

  const MetronomeButton({
    super.key,
    required this.text,
    required this.onPressed,
    required this.style,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.metronome_button_background_color(isDark: isDark),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space_24,
          vertical: AppSpacing.space_12,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.space_4),
        ),
      ),
      child: Text(text, style: style),
    );
  }
}

