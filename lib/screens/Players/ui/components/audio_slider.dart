import 'package:flutter/material.dart';
import 'package:sornaz/components/ab_repeat.dart';
import 'package:provider/provider.dart';
import 'package:sornaz/helpers/app_colors.dart';
import 'package:sornaz/helpers/app_data.dart';
import 'package:sornaz/helpers/app_typography.dart';
import 'package:sornaz/helpers/app_functions.dart';
import 'package:sornaz/screens/Players/providers/audio_player_provider.dart';

class AudioSlider extends StatelessWidget {
  const AudioSlider({super.key});

  @override
  Widget build(BuildContext context) {
    final appData = Provider.of<AppData>(context);
    final isDark = appData.isDark;
    final provider = context.watch<AudioPlayerProvider>();

    final double currentPosition = provider.position.inSeconds.toDouble();
    final double totalDuration = provider.duration.inSeconds.toDouble() == 0
        ? 1.0
        : provider.duration.inSeconds.toDouble();

    return Row(
      children: [
        TextButton(
          onPressed: () {},
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            maximumSize: const Size(56, 20),
            minimumSize: const Size(56, 20),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            formatDuration(provider.duration),
            style: AppTypography.musicPlayerAudioWidgetDurationTime(context),
          ),
        ),
        Directionality(
          textDirection: TextDirection.ltr,
          child: Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 15),
              ),
              child: AbTrack(
                repeat: provider.abRepeat,
                duration: provider.duration,
                child: Slider(
                  activeColor: Theme.of(context).colorScheme.primary,
                  inactiveColor:
                      AppColors.music_player_audio_slider_inactive_color(
                        isDark: isDark,
                      ),
                  value: provider.duration == Duration.zero
                      ? 0
                      : currentPosition.clamp(0.0, totalDuration),
                  max: totalDuration,
                  onChangeStart: (_) => [provider.startSliding()],
                  onChanged: (v) => {},
                  onChangeEnd: (v) => {
                    provider.seek(Duration(seconds: v.toInt())),
                    // تایمر رو دوباره شروع کن تا ۱۰ ثانیه فرصت داشته باشه
                    provider
                        .restartUndoTimer(), // اگر private بود، یک متد عمومی بساز
                  },
                ),
              ),
            ),
          ),
        ),
        TextButton(
          onPressed: () => provider.toggleTimeMode(),
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            maximumSize: const Size(56, 20),
            minimumSize: const Size(56, 20),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            provider.showRemaining
                ? formatDuration(provider.duration - provider.position)
                : formatDuration(provider.position),
            style: AppTypography.musicPlayerAudioWidgetPositionTime(context),
          ),
        ),
      ],
    );
  }
}
