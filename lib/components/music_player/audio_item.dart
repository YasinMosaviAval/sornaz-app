import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sornaz/classes/audio_file.dart';
import 'package:sornaz/components/music_player/file_actions.dart';
import 'package:sornaz/helpers/app_colors.dart';
import 'package:sornaz/helpers/app_data.dart';
import 'package:sornaz/helpers/app_spacing.dart';
import 'package:sornaz/provider/audio_player_provider.dart';
import 'package:sornaz/components/music_player/marquee_text.dart';
import 'package:sornaz/helpers/app_functions.dart';
import 'package:sornaz/helpers/app_typography.dart';

class AudioItem extends StatelessWidget {
  final AudioFile audio;
  final bool isPlaying;
  final int index;
  final VoidCallback? onTap;

  const AudioItem({
    super.key, 
    required this.audio,
    required this.isPlaying,
    required this.index,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final appData = Provider.of<AppData>(context);
    final isDark = appData.isDark;
    final provider = context.read<AudioPlayerProvider>();
    final file = provider.filteredFiles[index];

    return Container(
      key: ValueKey(file.file.path),
      decoration: BoxDecoration(
        border: Border.all(
          width: 0.8,
          color: isDark ? AppColors.border_dark : AppColors.border_light,
        ),
        color: isPlaying
            ? isDark
                  ? AppColors.clicked_dark
                  : AppColors.clicked_light
            : Colors.transparent,
      ),
      child: GestureDetector(
        onLongPress: () => showFileOptions(context, audio),
        // onLongPress: () => _showFileOptions(context, file, index),
        child: ListTile(
          contentPadding: EdgeInsets.symmetric(
            horizontal: AppSpacing.space_24,
            vertical: AppSpacing.space_2,
          ),
          leading: Icon(
            isPlaying ? Icons.pause_circle_filled :  Icons.play_circle_filled,
            color: isPlaying
                ? (isDark ? AppColors.text_primary_dark : AppColors.text_primary_light)
                : (isDark ? AppColors.text_secondary_dark : AppColors.text_secondary_light),
            size: AppSpacing.space_32,
          ),
          minTileHeight: AppSpacing.space_24,
          title: isPlaying
              ? MarqueeText(
                text: audio.fileName.substring(0, audio.fileName.lastIndexOf('.')), 
                textStyle: AppTypography.musicPlayerPlayingAudioFile(context)
              )
              : Text(
                  audio.fileName.substring(0, audio.fileName.lastIndexOf('.')),
                  style: AppTypography.musicPlayerNotPlayingAudioFile(context),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: AppSpacing.space_4),
              Row(
                children: [
                  Text(
                    formatDuration(audio.duration),
                    style: AppTypography.musicPlayerAudioItemDurationTime(context),
                  ),
                  SizedBox(width: AppSpacing.space_16),
                  Expanded(
                    child: Text(
                      audio.folderName.substring(1),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      textDirection: TextDirection.ltr,
                      style: AppTypography.musicPlayerAudioItemAddress(context),
                    ),
                  ),
                ],
              ),
            ],
          ),
          onTap: onTap ?? () => provider.play(index),
        ),
      ),
    );
  }
}
