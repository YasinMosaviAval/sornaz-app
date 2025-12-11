import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sornaz/classes/audio_file.dart';
import 'package:sornaz/helpers/app_colors.dart';
import 'package:sornaz/helpers/app_data.dart';
import 'package:sornaz/helpers/app_spacing.dart';
import 'package:sornaz/provider/audio_player_provider.dart';
import 'package:sornaz/components/marquee_text.dart';
import 'package:sornaz/helpers/app_functions.dart';
import 'package:sornaz/helpers/app_typography.dart';

class AudioItem extends StatelessWidget {
  final AudioFile audio;
  final bool isPlaying;
  final int index;

  const AudioItem({super.key, 
    required this.audio,
    required this.isPlaying,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final appData = Provider.of<AppData>(context);
    final isDark = appData.isDark;
    final pr = context.read<AudioPlayerProvider>();

    return Container(
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
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(
          horizontal: AppSpacing.space_24,
          vertical: AppSpacing.space_2,
        ),
        minTileHeight: AppSpacing.space_24,
        title: isPlaying
            ? MarqueeText(text: audio.fileName, textStyle: AppTypography.musicPlayerPlayingAudioFile(context))
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
        onTap: () => pr.play(index),
      ),
    );
  }
}
