import '../pages/song_information.dart';
import 'playback_speed_dialog.dart';
import 'player_slide_navigation.dart';
import 'package:flutter/material.dart' hide RepeatMode;
import 'package:sornaz/components/ab_repeat.dart';
import 'package:provider/provider.dart';
import 'package:sornaz/helpers/app_colors.dart';
import 'package:sornaz/helpers/app_data.dart';
import '../../playback/playback_queue_manager.dart';
import '../../providers/audio_player_provider.dart';

class AudioControls extends StatelessWidget {
  const AudioControls({super.key});
  @override
  Widget build(BuildContext context) {
    final p = context.watch<AudioPlayerProvider>();
    return PlaybackControls(
      playing: p.isPlaying,
      undo: p.isUndoMode,
      shuffle: p.isShuffle,
      repeatMode: p.repeatMode,
      repeat: p.abRepeat,
      speed: p.playbackSpeed,
      speedOptions: p.speedOptions,
      onPlayPause: p.isPlaying ? p.pause : p.resume,
      onNext: p.playNext,
      onPrevious: p.previousOrUndo,
      onForward: p.seekForward10,
      onBackward: p.seekBackward10,
      onShuffle: p.toggleShuffle,
      onRepeat: p.toggleRepeatMode,
      onAbRepeat: p.currentAudio == null ? null : p.cycleAbRepeat,
      onSpeed: p.setSpeed,
      onInfo: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SongDetailsPage()),
      ),
    );
  }
}

/// The same playback controls for the music library and recorded audio.
class PlaybackControls extends StatelessWidget {
  const PlaybackControls({
    super.key,
    required this.playing,
    this.undo = false,
    required this.shuffle,
    required this.repeatMode,
    required this.repeat,
    required this.speed,
    required this.speedOptions,
    required this.onPlayPause,
    required this.onNext,
    required this.onPrevious,
    required this.onForward,
    required this.onBackward,
    required this.onShuffle,
    required this.onRepeat,
    required this.onAbRepeat,
    required this.onSpeed,
    required this.onInfo,
  });
  final bool playing, undo, shuffle;
  final RepeatMode repeatMode;
  final AbRepeat repeat;
  final double speed;
  final List<double> speedOptions;
  final VoidCallback onPlayPause,
      onNext,
      onPrevious,
      onForward,
      onBackward,
      onShuffle,
      onRepeat,
      onInfo;
  final VoidCallback? onAbRepeat;
  final ValueChanged<double> onSpeed;
  @override
  Widget build(BuildContext context) {
    final dark = context.watch<AppData>().isDark;
    final ink = AppColors.music_player_audio_controls_main_icon_color(
      isDark: dark,
    );
    final secondary =
        AppColors.music_player_audio_controls_sub_level_icon_color(
          isDark: dark,
        );
    final active =
        AppColors.music_player_audio_controls_sub_level_active_icon_color(
          isDark: dark,
        );
    final slides = PlayerSlideNavigation.of(context);
    final rtl = Directionality.of(context) == TextDirection.rtl;
    Widget button(
      IconData icon,
      VoidCallback? action, {
      Key? key,
      double size = 32,
    }) => IconButton(
      key: key,
      icon: Icon(icon),
      iconSize: size,
      color: ink,
      onPressed: action,
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
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
              button(
                rtl ? Icons.arrow_back : Icons.arrow_forward,
                slides?.left,
                key: const ValueKey('player-leading-slide'),
                size: 24,
              ),
              button(Icons.forward_10, onForward),
              button(Icons.skip_next, onNext),
              button(playing ? Icons.pause : Icons.play_arrow, onPlayPause),
              button(undo ? Icons.undo : Icons.skip_previous, onPrevious),
              button(Icons.replay_10, onBackward),
              button(
                rtl ? Icons.arrow_forward : Icons.arrow_back,
                slides?.right,
                key: const ValueKey('player-trailing-slide'),
                size: 24,
              ),
            ],
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.info_outline),
              color: secondary,
              iconSize: 24,
              tooltip: 'اطلاعات',
              onPressed: onInfo,
            ),
            AbRepeatButton(repeat: repeat, onPressed: onAbRepeat),
            IconButton(
              icon: const Icon(Icons.shuffle),
              color: shuffle ? active : secondary,
              iconSize: 24,
              onPressed: onShuffle,
            ),
            IconButton(
              icon: Icon(
                repeatMode == RepeatMode.one ? Icons.repeat_one : Icons.repeat,
              ),
              color: repeatMode == RepeatMode.off ? secondary : active,
              iconSize: 24,
              onPressed: onRepeat,
            ),
            PlaybackSpeedButton(
              speed: speed,
              presets: speedOptions,
              onChanged: onSpeed,
            ),
          ],
        ),
      ],
    );
  }
}

class PlaybackSpeedButton extends StatelessWidget {
  const PlaybackSpeedButton({
    super.key,
    required this.speed,
    required this.presets,
    required this.onChanged,
  });
  final double speed;
  final List<double> presets;
  final ValueChanged<double> onChanged;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: () => showPlaybackSpeedDialog(
      context,
      speed: speed,
      presets: presets,
      onChanged: onChanged,
    ),
    child: SizedBox(
      width: 48,
      height: 48,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            Icons.speed,
            size: 24,
            color: AppColors.music_player_audio_controls_main_icon_color(
              isDark: context.watch<AppData>().isDark,
            ),
          ),
          Positioned(
            bottom: 0,
            child: Text('${speed}×', style: const TextStyle(fontSize: 9)),
          ),
        ],
      ),
    ),
  );
}
