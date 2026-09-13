import 'playback_speed_dialog.dart';
import 'player_slide_navigation.dart';
import 'package:flutter/material.dart' hide RepeatMode;
import 'package:sornaz/components/ab_repeat.dart';
import 'package:provider/provider.dart';
import 'package:sornaz/helpers/app_constants.dart';
import 'package:sornaz/helpers/app_typography.dart';
import 'package:sornaz/helpers/app_colors.dart';
import 'package:sornaz/helpers/app_data.dart';
import 'package:sornaz/helpers/app_spacing.dart';


import 'package:sornaz/screens/Players/playback/playback_queue_manager.dart';
import 'package:sornaz/screens/Players/providers/audio_player_provider.dart';

class AudioControls extends StatelessWidget {
  const AudioControls({super.key});

  @override
  Widget build(BuildContext context) {
    final appData = Provider.of<AppData>(context);
    final isDark = appData.isDark;
    final provider = context.watch<AudioPlayerProvider>();

    final slides = PlayerSlideNavigation.of(context);
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return Column(
      children: [
        IconButtonTheme(
          data: IconButtonThemeData(
            style: IconButton.styleFrom(
              minimumSize: const Size(32, 44),
              padding: EdgeInsets.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                key: const ValueKey('player-leading-slide'),
                icon: Icon(rtl ? Icons.arrow_back : Icons.arrow_forward),
                color: AppColors.music_player_audio_controls_main_icon_color(
                  isDark: isDark,
                ),
                onPressed: rtl ? slides?.right : slides?.left,
              ),
              IconButton(
                icon: const Icon(Icons.forward_10),
                iconSize: AppSpacing.space_32,
                color: AppColors.music_player_audio_controls_main_icon_color(
                  isDark: isDark,
                ),
                onPressed: provider.seekForward10,
              ),
              IconButton(
                icon: const Icon(Icons.skip_next),
                iconSize: AppSpacing.space_32,
                color: AppColors.music_player_audio_controls_main_icon_color(
                  isDark: isDark,
                ),
                onPressed: provider.playNext,
              ),
              IconButton(
                icon: Icon(provider.isPlaying ? Icons.pause : Icons.play_arrow),
                iconSize: AppSpacing.space_32,
                color: AppColors.music_player_audio_controls_main_icon_color(
                  isDark: isDark,
                ),
                onPressed: provider.isPlaying
                    ? provider.pause
                    : provider.resume,
              ),
              IconButton(
                icon: Icon(
                  provider.isUndoMode ? Icons.undo : Icons.skip_previous,
                ),
                iconSize: AppSpacing.space_32,
                color: AppColors.music_player_audio_controls_main_icon_color(
                  isDark: isDark,
                ),
                onPressed: provider.previousOrUndo,
              ),
              IconButton(
                icon: const Icon(Icons.replay_10),
                iconSize: AppSpacing.space_32,
                color: AppColors.music_player_audio_controls_main_icon_color(
                  isDark: isDark,
                ),
                onPressed: provider.seekBackward10,
              ),
              IconButton(
                key: const ValueKey('player-trailing-slide'),
                icon: Icon(rtl ? Icons.arrow_forward : Icons.arrow_back),
                color: AppColors.music_player_audio_controls_main_icon_color(
                  isDark: isDark,
                ),
                onPressed: rtl ? slides?.left : slides?.right,
              ),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.zero,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            spacing: 0,
            children: [
              IconButton(
                icon: Icon(
                  provider.folderMode ? Icons.list : Icons.folder,
                  color:
                      AppColors.music_player_audio_controls_sub_level_icon_color(
                        isDark: isDark,
                      ),
                ),
                iconSize: AppSpacing.space_24,
                onPressed: () => provider.toggleFolderMode(),
              ),
              AbRepeatButton(
                repeat: provider.abRepeat,
                onPressed: provider.currentAudio == null
                    ? null
                    : provider.cycleAbRepeat,
              ),
              IconButton(
                icon: Icon(
                  Icons.shuffle,
                  color: provider.isShuffle
                      ? AppColors.music_player_audio_controls_sub_level_active_icon_color(
                          isDark: isDark,
                        )
                      : AppColors.music_player_audio_controls_sub_level_icon_color(
                          isDark: isDark,
                        ),
                ),
                iconSize: AppSpacing.space_24,
                onPressed: provider.toggleShuffle,
              ),
              IconButton(
                alignment: Alignment.center,
                icon: Icon(
                  provider.repeatMode == RepeatMode.off
                      ? Icons.repeat
                      : provider.repeatMode == RepeatMode.one
                      ? Icons.repeat_one
                      : Icons.repeat,
                ),
                color: provider.repeatMode == RepeatMode.off
                    ? AppColors.music_player_audio_controls_sub_level_icon_color(
                        isDark: isDark,
                      )
                    : AppColors.music_player_audio_controls_sub_level_active_icon_color(
                        isDark: isDark,
                      ),
                onPressed: provider.toggleRepeatMode,
                iconSize: AppSpacing.space_24,
              ),

              Theme(
                data: Theme.of(context).copyWith(
                  popupMenuTheme: PopupMenuThemeData(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.space_4),
                    ),
                  ),
                ),
                child: InkWell(
                  onTap: () => showPlaybackSpeedDialog(
                    context,
                    speed: provider.playbackSpeed,
                    presets: provider.speedOptions,
                    onChanged: provider.setSpeed,
                  ),
                  child: SizedBox(
                    width: 48,
                    height: 48,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Icon(
                          Icons.speed,
                          size: AppSpacing.space_24,
                          color:
                              AppColors.music_player_audio_controls_main_icon_color(
                                isDark: isDark,
                              ),
                        ),
                        Positioned(
                          bottom: 0,
                          child: Text(
                            "${provider.playbackSpeed}${AppConstants.AUDIO_CONTROLS_SPEED_SIGN}",
                            style: AppTypography.musicPlayerAudioControlsSpeed(
                              context,
                            ).copyWith(fontSize: 9),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
