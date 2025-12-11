import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sornaz/components/audio_item.dart';
import 'package:sornaz/helpers/app_colors.dart';
import 'package:sornaz/helpers/app_data.dart';
import 'package:sornaz/helpers/app_strings.dart';
import 'package:sornaz/helpers/app_translations.dart';
import 'package:sornaz/helpers/app_typography.dart';
import 'package:sornaz/provider/audio_player_provider.dart';

class AudioList extends StatelessWidget {
  const AudioList({super.key});

  @override
  Widget build(BuildContext context) {
    final appData = Provider.of<AppData>(context);
    final isDark = appData.isDark;
    final pr = context.watch<AudioPlayerProvider>();

    if (pr.isLoading) {
      return Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.background_dark : AppColors.background_light,
        ),
        child: Center(child: CircularProgressIndicator()
        )
      );
    }
    
    
    if (pr.filteredFiles.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.background_dark : AppColors.background_light,
        ),
        child: Center(
          child: Text(
            AppStrings.audio_file_not_found.translate(context), 
            style: AppTypography.musicPlayerAudioFileNotFound(context)
          )
        ),
      );
    }

    return Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.background_dark : AppColors.background_light,
        ),
      child: ListView.builder(
        itemCount: pr.filteredFiles.length,
        itemBuilder: (_, i) => AudioItem(
          audio: pr.filteredFiles[i],
          isPlaying: pr.currentIndex == i,
          index: i,
        ),
      ),
    );
  }
}
