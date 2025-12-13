
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sornaz/components/audio_file_actions.dart';
import 'package:sornaz/components/audio_item.dart';
import 'package:sornaz/helpers/app_colors.dart';
import 'package:sornaz/helpers/app_data.dart';
import 'package:sornaz/provider/audio_player_provider.dart';

class FlatListView extends StatelessWidget {
  const FlatListView({super.key});

  
  @override
  Widget build(BuildContext context) {
    final appData = Provider.of<AppData>(context);
    final isDark = appData.isDark;
    final provider = context.watch<AudioPlayerProvider>();

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.background_dark : AppColors.background_light,
      ),
      child: ListView.builder(
        itemCount: provider.filteredFiles.length,
        itemBuilder: (context, index) {
          final audio = provider.filteredFiles[index];
          return GestureDetector(
            onTap: () => provider.play(index),
            key: ValueKey(audio.file.path),
            onLongPress: () => showFileOptions(context, audio),
            child: AudioItem(
              audio: provider.filteredFiles[index],
              isPlaying: provider.currentIndex == index,
              index: index,
            ),
          );
        }
      ),
    );
  }
}
