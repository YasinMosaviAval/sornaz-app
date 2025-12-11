import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sornaz/helpers/app_colors.dart';
import 'package:sornaz/helpers/app_data.dart';
import 'package:sornaz/helpers/app_spacing.dart';
import 'package:sornaz/provider/audio_player_provider.dart';

class AudioControls extends StatelessWidget {
  const AudioControls({super.key});

  @override
  Widget build(BuildContext context) {
    final appData = Provider.of<AppData>(context);
    final isDark = appData.isDark;
    final pr = context.watch<AudioPlayerProvider>();

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.forward_10),
              iconSize: AppSpacing.space_32,
              color: isDark ? AppColors.text_primary_dark : AppColors.text_primary_light,
              onPressed: pr.seekForward10,
            ),
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
            IconButton(
              icon: const Icon(Icons.replay_10),
              iconSize: AppSpacing.space_32,
              color: isDark ? AppColors.text_primary_dark : AppColors.text_primary_light,
              onPressed: pr.seekBackward10,
            ),
        
          ],
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space_8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            spacing: AppSpacing.space_16,
            children: [
              IconButton(
                icon: Icon(
                  Icons.shuffle,
                  color: pr.isShuffle
                      ? (isDark ? AppColors.primary_dark : AppColors.primary_light)
                      : (isDark ? AppColors.text_secondary_dark : AppColors.text_secondary_light),
                ),
                iconSize: AppSpacing.space_24,
                onPressed: pr.toggleShuffle,
              ),
              IconButton(
                alignment: Alignment.center,
                icon: Icon(
                  pr.repeatMode == 0
                      ? Icons.repeat
                      : pr.repeatMode == 1
                          ? Icons.repeat_one
                          : Icons.repeat, // حالت repeat all
                ),
                color: pr.repeatMode == 0
                    ? (isDark ? AppColors.text_secondary_dark : AppColors.text_secondary_light)
                    : isDark
                        ? AppColors.primary_dark
                        : AppColors.primary_light,
                onPressed: pr.toggleRepeatMode,
                iconSize: AppSpacing.space_24,
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
                        size: AppSpacing.space_24,
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
          ),
        ),
      ],
    );
  }
}
