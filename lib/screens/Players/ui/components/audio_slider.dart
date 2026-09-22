import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sornaz/components/ab_repeat.dart';
import 'package:sornaz/helpers/app_colors.dart';
import 'package:sornaz/helpers/app_data.dart';
import 'package:sornaz/helpers/app_typography.dart';
import 'package:sornaz/helpers/app_functions.dart';
import '../../providers/audio_player_provider.dart';

class AudioSlider extends StatelessWidget {
  const AudioSlider({super.key});
  @override
  Widget build(BuildContext context) {
    final player = context.watch<AudioPlayerProvider>();
    return PlaybackProgress(
      position: player.position,
      duration: player.duration,
      repeat: player.abRepeat,
      remaining: player.showRemaining,
      toggleTime: player.toggleTimeMode,
      onStart: player.startSliding,
      onSeek: (at) {
        player.seek(at);
        player.restartUndoTimer();
      },
    );
  }
}

class PlaybackProgress extends StatefulWidget {
  const PlaybackProgress({
    super.key,
    required this.position,
    required this.duration,
    required this.repeat,
    required this.onSeek,
    this.onStart,
    this.remaining = false,
    this.toggleTime,
  });
  final Duration position, duration;
  final AbRepeat repeat;
  final ValueChanged<Duration> onSeek;
  final VoidCallback? onStart, toggleTime;
  final bool remaining;
  @override
  State<PlaybackProgress> createState() => _PlaybackProgressState();
}

class _PlaybackProgressState extends State<PlaybackProgress> {
  double? dragging;
  @override
  Widget build(BuildContext context) {
    final total = widget.duration.inMilliseconds.toDouble();
    final isDark = context.watch<AppData>().isDark;
    return Row(
      children: [
        SizedBox(
          width: 56,
          child: Text(
            formatDuration(widget.duration),
            textAlign: TextAlign.center,
            style: AppTypography.musicPlayerAudioWidgetDurationTime(context),
          ),
        ),
        Expanded(
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                trackShape: const RectangularSliderTrackShape(),
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 15),
              ),
              child: AbTrack(
                repeat: widget.repeat,
                duration: widget.duration,
                horizontalPadding: 15,
                child: Slider(
                  activeColor: Theme.of(context).colorScheme.primary,
                  inactiveColor:
                      AppColors.music_player_audio_slider_inactive_color(
                        isDark: isDark,
                      ),
                  value: (dragging ?? widget.position.inMilliseconds.toDouble())
                      .clamp(0, total > 0 ? total : 1),
                  max: total > 0 ? total : 1,
                  onChangeStart: total > 0
                      ? (v) {
                          widget.onStart?.call();
                          setState(() => dragging = v);
                        }
                      : null,
                  onChanged: total > 0
                      ? (v) => setState(() => dragging = v)
                      : null,
                  onChangeEnd: total > 0
                      ? (v) {
                          widget.onSeek(Duration(milliseconds: v.round()));
                          setState(() => dragging = null);
                        }
                      : null,
                ),
              ),
            ),
          ),
        ),
        SizedBox(
          width: 56,
          child: TextButton(
            style: TextButton.styleFrom(padding: EdgeInsets.zero),
            onPressed: widget.toggleTime,
            child: Text(
              formatDuration(
                widget.remaining
                    ? widget.duration - widget.position
                    : widget.position,
              ),
              style: AppTypography.musicPlayerAudioWidgetPositionTime(context),
            ),
          ),
        ),
      ],
    );
  }
}
