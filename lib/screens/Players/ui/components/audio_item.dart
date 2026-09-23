import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sornaz/helpers/app_colors.dart';
import 'package:sornaz/helpers/app_data.dart';
import 'package:sornaz/helpers/app_functions.dart';
import 'package:sornaz/helpers/app_typography.dart';
import '../../providers/audio_player_provider.dart';
import '../../scan/audio_file.dart';
import 'audio_selection.dart';
import 'file_actions.dart';
import 'marquee_text.dart';

class AudioItem extends StatelessWidget {
  const AudioItem({
    super.key,
    required this.audio,
    required this.isPlaying,
    required this.index,
    this.onTap,
    this.onLongPress,
    this.selected = false,
    this.trailing,
  });
  final AudioFile audio;
  final Widget? trailing;
  final bool isPlaying, selected;
  final int index;
  final VoidCallback? onTap, onLongPress;

  @override
  Widget build(BuildContext context) {
    final dot = audio.fileName.lastIndexOf('.');
    final title = dot > 0 ? audio.fileName.substring(0, dot) : audio.fileName;
    final action =
        onTap ?? () => context.read<AudioPlayerProvider>().play(index);
    return AudioRow(
      key: ValueKey(audio.file.path),
      title: title,
      location: audio.folderName,
      duration: audio.duration,
      isPlaying: isPlaying,
      paused: isPlaying && !context.watch<AudioPlayerProvider>().isPlaying,
      selected: selected,
      onTap: action,
      onLongPress: onLongPress ?? () => showFileOptions(context, audio),
      trailing: trailing ?? AudioActionsMenu(files: [audio]),
    );
  }
}

/// Shared song/recording card, with playback and file actions supplied by its owner.
class AudioRow extends StatelessWidget {
  const AudioRow({
    super.key,
    required this.title,
    required this.location,
    required this.duration,
    required this.isPlaying,
    required this.onTap,
    required this.trailing,
    this.selected = false,
    this.onLongPress,
    this.paused = false,
    this.leadingIcon,
    this.count,
  });
  final String title, location;
  final Duration duration;
  final bool isPlaying, selected;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final Widget trailing;
  final bool paused;
  final IconData? leadingIcon;
  final int? count;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppData>();
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          width: .2,
          color: (app.isDark ? Colors.white : Colors.black).withValues(
            alpha: .04,
          ),
        ),
        color: selected
            ? app.accent.withValues(alpha: .22)
            : isPlaying
            ? AppColors.music_player_audio_item_playing_background_color(
                isDark: app.isDark,
              )
            : AppColors.music_player_audio_item_not_playing_background_color(
                isDark: app.isDark,
              ),
      ),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 48,
                height: 48,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  onPressed: onTap,
                  iconSize: 28,
                  color: isPlaying
                      ? app.accent
                      : Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: .38),
                  icon: Icon(
                    leadingIcon ??
                        (isPlaying && !paused
                            ? Icons.pause_circle_filled
                            : isPlaying
                            ? Icons.play_circle_filled
                            : Icons.play_circle_outline),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isPlaying)
                      MarqueeText(
                        text: title,
                        textStyle: AppTypography.musicPlayerPlayingAudioFile(
                          context,
                        ),
                      )
                    else
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.musicPlayerNotPlayingAudioFile(
                          context,
                        ),
                      ),
                    const SizedBox(height: 4),
                    Directionality(
                      textDirection: TextDirection.ltr,
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              location,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.musicPlayerAudioItemAddress(
                                context,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            count?.toString() ?? formatDuration(duration),
                            style:
                                AppTypography.musicPlayerAudioItemDurationTime(
                                  context,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsetsDirectional.only(end: 8),
                child: SizedBox(width: 32, height: 32, child: trailing),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
