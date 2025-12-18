import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sornaz/helpers/app_colors.dart';
import 'package:sornaz/helpers/app_data.dart';
import 'package:sornaz/helpers/app_typography.dart';
import 'package:sornaz/audio/audio_player_provider.dart';
import 'package:sornaz/helpers/app_functions.dart';

class AudioSlider extends StatelessWidget {
  const AudioSlider({super.key});

  @override
  Widget build(BuildContext context) {
    final appData = Provider.of<AppData>(context);
    final isDark = appData.isDark;
    final pr = context.watch<AudioPlayerProvider>();

    final double currentPosition = pr.position.inSeconds.toDouble();
    final double totalDuration = pr.duration.inSeconds.toDouble() == 0 ? 1.0 : pr.duration.inSeconds.toDouble();

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
              value: currentPosition.clamp(0.0, totalDuration),
              max: totalDuration,
              onChangeStart: (_) => [pr.startSliding()],
              onChanged: (v) => {},
              onChangeEnd: (v) => pr.seek(Duration(seconds: v.toInt())),
            ),
          ),
        ),
        TextButton(
          onPressed: () => pr.toggleTimeMode(),
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            maximumSize: const Size(56, 20),
            minimumSize: const Size(56, 20),
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
