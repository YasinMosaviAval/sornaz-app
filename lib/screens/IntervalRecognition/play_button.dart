import 'package:flutter/material.dart';
import 'package:sornaz/helpers/app_colors.dart';
import 'package:sornaz/helpers/app_spacing.dart';

/// Uses the metronome's circular decoration, icon colors and subtle scale.
class IntervalPlayButton extends StatelessWidget {
  const IntervalPlayButton({
    super.key,
    required this.playing,
    required this.label,
    required this.onPressed,
  });
  final bool playing;
  final String label;
  final VoidCallback? onPressed;
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = playing
        ? AppColors.metronome_page_accent_beat_icon_active_decoration_color(
            isDark: isDark,
          )
        : AppColors.metronome_page_accent_beat_icon_inactive_decoration_color(
            isDark: isDark,
          );
    final iconColor = playing
        ? AppColors.metronome_page_accent_beat_icon_active_color(isDark: isDark)
        : AppColors.metronome_page_accent_beat_icon_inactive_color(
            isDark: isDark,
          );
    return Center(
      child: AnimatedScale(
        scale: playing ? 1.05 : 1,
        duration: const Duration(milliseconds: 180),
        child: SizedBox(
          width: AppSpacing.space_100,
          height: AppSpacing.space_100,
          child: Material(
            color: color,
            shape: const CircleBorder(),
            child: IconButton(
              tooltip: label,
              onPressed: onPressed,
              iconSize: AppSpacing.space_56,
              style: IconButton.styleFrom(
                shape: const CircleBorder(),
                foregroundColor: iconColor,
              ),
              icon: const Icon(Icons.play_arrow),
            ),
          ),
        ),
      ),
    );
  }
}
