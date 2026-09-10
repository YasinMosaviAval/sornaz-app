import 'package:flutter/material.dart';
import 'audio_selection.dart';
import 'package:provider/provider.dart';
import 'package:sornaz/screens/Players/providers/audio_player_provider.dart';
import 'package:sornaz/screens/Players/scan/audio_file.dart';
import 'package:sornaz/screens/Players/ui/components/file_actions.dart';
import 'package:sornaz/helpers/app_colors.dart';
import 'package:sornaz/helpers/app_data.dart';
import 'package:sornaz/helpers/app_spacing.dart';
import 'package:sornaz/screens/Players/ui/components/marquee_text.dart';
import 'package:sornaz/helpers/app_functions.dart';
import 'package:sornaz/helpers/app_typography.dart';

class AudioItem extends StatelessWidget {
  final AudioFile audio;
  final bool isPlaying;
  final int index;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool selected;

  const AudioItem({
    super.key, 
    required this.audio,
    required this.isPlaying,
    required this.index,
    this.onTap,
    this.onLongPress,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    final appData = Provider.of<AppData>(context);
    final isDark = appData.isDark;
    final provider = context.read<AudioPlayerProvider>();
    final file = audio;

    return Container(
      key: ValueKey(file.file.path),
      decoration: BoxDecoration(
        border: Border.all(
          width: 0.4,
          color: (isDark ? Colors.white : Colors.black).withValues(alpha: .12),
        ),
        color: isPlaying
            ? AppColors.music_player_audio_item_playing_background_color(isDark: isDark)
            : AppColors.music_player_audio_item_not_playing_background_color(isDark: isDark),
      ),
      child: GestureDetector(
        onLongPress: onLongPress ?? () => showFileOptions(context, audio),
        // onLongPress: () => _showFileOptions(context, file, index),
        child: ListTile(
          selected: selected,
          trailing: selected ? const Icon(Icons.check_circle) : AudioActionsMenu(files: [audio]),
          contentPadding: EdgeInsets.symmetric(
            horizontal: AppSpacing.space_12,
            vertical: AppSpacing.space_2,
          ),
          leading: Icon(
            isPlaying ? Icons.pause_circle_filled :  Icons.play_circle_filled,
            color: isPlaying
                ? AppColors.music_player_audio_item_playing_icon_background_color(isDark: isDark)
                : AppColors.music_player_audio_item_not_playing_icon_background_color(isDark: isDark),
            size: AppSpacing.space_32,
          ),
          minTileHeight: AppSpacing.space_24,
          title: isPlaying
              ? MarqueeText(
                text: audio.fileName.substring(0, audio.fileName.lastIndexOf('.')), 
                textStyle: AppTypography.musicPlayerPlayingAudioFile(context)
              )
              : Text(
                  // audio.fileName,
                  audio.fileName.substring(0, audio.fileName.lastIndexOf('.')),
                  style: AppTypography.musicPlayerNotPlayingAudioFile(context),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppSpacing.sizedBoxH4(),
              Directionality(
                textDirection: TextDirection.ltr,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        audio.folderName.substring(1),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        textDirection: TextDirection.ltr,
                        style: AppTypography.musicPlayerAudioItemAddress(context),
                      ),
                    ),
                    AppSpacing.sizedBoxW16(),
                    Text(
                      formatDuration(audio.duration),
                      style: AppTypography.musicPlayerAudioItemDurationTime(context),
                    ),
                  ],
                ),
              ),
            ],
          ),
          onTap: onTap ?? () => provider.play(index),
        ),
      ),
    );
  }
}
