import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sornaz/helpers/app_colors.dart';
import 'package:sornaz/helpers/app_data.dart';
import 'package:sornaz/helpers/app_spacing.dart';
import 'package:sornaz/helpers/app_typography.dart';
import 'package:sornaz/provider/audio_player_provider.dart';

class AudioControls extends StatelessWidget {
  const AudioControls({super.key});

  @override
  Widget build(BuildContext context) {
    final appData = Provider.of<AppData>(context);
    final isDark = appData.isDark;
    final pr = context.watch<AudioPlayerProvider>();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        IconButton(
          icon: const Icon(Icons.skip_next),
          iconSize: AppSpacing.space_32,
          color: isDark ? AppColors.text_primary_dark : AppColors.text_primary_light,
          onPressed: pr.playNext,
        ),
        IconButton(
          icon: Icon(pr.isPlaying ? Icons.pause : Icons.play_arrow),
          iconSize: AppSpacing.space_32,
          color: isDark ? AppColors.text_primary_dark : AppColors.text_primary_light,
          onPressed: pr.isPlaying
              ? pr.pause
              : () => pr.play(pr.currentIndex),
        ),
        IconButton(
          icon: Icon(pr.isUndoMode ? Icons.undo : Icons.skip_previous),
          iconSize: AppSpacing.space_32,
          color: isDark ? AppColors.text_primary_dark : AppColors.text_primary_light,
          onPressed: pr.previousOrUndo,
        ),
        Theme(
          data: Theme.of(context).copyWith(
            popupMenuTheme: PopupMenuThemeData(
              // color: isDark ? AppColors.surface_dark : AppColors.surface_light,
              // textStyle: AppTypography.musicPlayerSpeedMenuItem(context),
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.space_4),
              ),
            ),
          ),
          
          child: PopupMenuButton<double>(
            initialValue: pr.playbackSpeed,
            onSelected: pr.setSpeed,
            itemBuilder: (_) => pr.speedOptions.map((speed) {
              return PopupMenuItem<double>(
                value: speed,
                child: Text(
                  speed == 1 ? "1x (Normal)" : "${speed}x",
                ),
              );
            }).toList(),
            child: Row(
              children: [
                Icon(
                  Icons.speed,
                  color: isDark? AppColors.text_primary_dark : AppColors.text_primary_light,
                  size: 26
                ),
                const SizedBox(width: AppSpacing.space_4),
                Text(
                  "${pr.playbackSpeed}x",
                  style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? AppColors.text_primary_dark : AppColors.text_primary_light),
                ),
              ],
            ),
          ),
        )
      ],
    );
  }
}
