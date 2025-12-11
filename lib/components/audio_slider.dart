import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sornaz/helpers/app_colors.dart';
import 'package:sornaz/helpers/app_data.dart';
import 'package:sornaz/helpers/app_typography.dart';
import 'package:sornaz/provider/audio_player_provider.dart';
import 'package:sornaz/helpers/app_functions.dart';

class AudioSlider extends StatelessWidget {
  const AudioSlider({super.key});

  @override
  Widget build(BuildContext context) {
    final appData = Provider.of<AppData>(context);
    final isDark = appData.isDark;
    final pr = context.watch<AudioPlayerProvider>();

    return Row(
      children: [
        TextButton(
          onPressed: () => {},
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            maximumSize: const Size(40, 20),
            minimumSize: const Size(40, 20),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            formatDuration(pr.duration), 
            style: AppTypography.musicPlayerAudioWidgetDurationTime(context)
          ),
        ),
        Directionality(
          textDirection: TextDirection.ltr,
          child: Expanded(
            child: Slider(
              activeColor: isDark ? AppColors.text_primary_dark : AppColors.text_primary_light,
              inactiveColor: isDark ? AppColors.border_dark : AppColors.border_light,
              value: pr.position.inSeconds.toDouble(),
              max: pr.duration.inSeconds.toDouble().clamp(1, double.infinity),
              onChangeStart: (_) => pr.startSliding(),
              onChanged: (v) =>
                  pr.position = Duration(seconds: v.toInt()), // UI update
              onChangeEnd: (v) => pr.seekTo(v),
            ),
          ),
        ),
        TextButton(
          onPressed: () => pr.toggleTimeMode(),
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            maximumSize: const Size(40, 20),
            minimumSize: const Size(40, 20),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            pr.showRemaining
                ? formatDuration(pr.duration - pr.position)
                : formatDuration(pr.position),
            style: AppTypography.musicPlayerAudioWidgetPositionTime(context),
          ),
        ),
      ],
    );
  }
}
