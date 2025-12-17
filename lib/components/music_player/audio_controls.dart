import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sornaz/helpers/app_colors.dart';
import 'package:sornaz/helpers/app_data.dart';
import 'package:sornaz/helpers/app_spacing.dart';
import 'package:sornaz/audio/audio_player_provider.dart';

class AudioControls extends StatelessWidget {
  const AudioControls({super.key});

  @override
  Widget build(BuildContext context) {
    final appData = Provider.of<AppData>(context);
    final isDark = appData.isDark;
    final provider = context.watch<AudioPlayerProvider>();

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.forward_10),
              iconSize: AppSpacing.space_32,
              color: isDark ? AppColors.text_primary_dark : AppColors.text_primary_light,
              onPressed: provider.seekForward10,
            ),
            IconButton(
              icon: const Icon(Icons.skip_next),
              iconSize: AppSpacing.space_32,
              color: isDark ? AppColors.text_primary_dark : AppColors.text_primary_light,
              onPressed: provider.playNext,
            ),
            IconButton(
              icon: Icon(provider.isPlaying ? Icons.pause : Icons.play_arrow),
              iconSize: AppSpacing.space_32,
              color: isDark ? AppColors.text_primary_dark : AppColors.text_primary_light,
              onPressed: provider.isPlaying
                  ? provider.pause
                  : () => provider.play(provider.currentIndex),
            ),
            IconButton(
              icon: Icon(provider.isUndoMode ? Icons.undo : Icons.skip_previous),
              iconSize: AppSpacing.space_32,
              color: isDark ? AppColors.text_primary_dark : AppColors.text_primary_light,
              onPressed: provider.previousOrUndo,
            ),
            IconButton(
              icon: const Icon(Icons.replay_10),
              iconSize: AppSpacing.space_32,
              color: isDark ? AppColors.text_primary_dark : AppColors.text_primary_light,
              onPressed: provider.seekBackward10,
            ),
        
          ],
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space_8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            spacing: AppSpacing.space_16,
            children: [
              // IconButton(
              //   icon: Icon(
              //     provider.folderMode ? Icons.list : Icons.folder,
              //     color: isDark ? AppColors.text_secondary_dark : AppColors.text_secondary_light
              //   ),
              //   iconSize: AppSpacing.space_24,
              //   // onPressed: provider.toggleFolderMode,
              //   onPressed: () => _tabController.animateTo(0),
              // ),


              IconButton(
                icon: Icon(
                  provider.folderMode ? Icons.list : Icons.folder,
                  color: isDark ? AppColors.text_secondary_dark : AppColors.text_secondary_light
                ),
                iconSize: AppSpacing.space_24,
                // onPressed: provider.toggleFolderMode,
                onPressed: () => provider.toggleFolderMode(),
              ),






              IconButton(
                icon: Icon(
                  Icons.shuffle,
                  color: provider.isShuffle
                      ? (isDark ? AppColors.primary_dark : AppColors.primary_light)
                      : (isDark ? AppColors.text_secondary_dark : AppColors.text_secondary_light),
                ),
                iconSize: AppSpacing.space_24,
                onPressed: provider.toggleShuffle,
              ),
              IconButton(
                alignment: Alignment.center,
                icon: Icon(
                  provider.repeatMode == 0
                      ? Icons.repeat
                      : provider.repeatMode == 1
                          ? Icons.repeat_one
                          : Icons.repeat, // حالت repeat all
                ),
                color: provider.repeatMode == 0
                    ? (isDark ? AppColors.text_secondary_dark : AppColors.text_secondary_light)
                    : isDark
                        ? AppColors.primary_dark
                        : AppColors.primary_light,
                onPressed: provider.toggleRepeatMode,
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
                  initialValue: provider.playbackSpeed,
                  onSelected: provider.setSpeed,
                  itemBuilder: (_) => provider.speedOptions.map((speed) {
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
                        "${provider.playbackSpeed}x",
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
