
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sornaz/helpers/app_logger.dart';
import 'package:sornaz/screens/Players/Components/file_actions.dart';
import 'package:sornaz/screens/Players/Components/audio_item.dart';
import 'package:sornaz/screens/Players/Components/bottom_player.dart';
import 'package:sornaz/helpers/app_colors.dart';
import 'package:sornaz/helpers/app_data.dart';
import 'package:sornaz/audio/audio_player_provider.dart';
import 'package:sornaz/screens/Players/Components/search_bar.dart';

class FlatListView extends StatelessWidget {
  const FlatListView({super.key});

  @override
  Widget build(BuildContext context) {
    final appData = Provider.of<AppData>(context);
    final isDark = appData.isDark;
    final provider = context.watch<AudioPlayerProvider>();

    loggingSornaz("  ===   provider.filteredFiles.length: ${provider.filteredFiles.length}");
    return Consumer<AudioPlayerProvider>(
      builder: (context, provider, _) {
        if (provider.filteredFiles.isEmpty && !provider.isHiveLoading) {
          return Center(
            child: Text(
              "فایل صوتی یافت نشد",
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          );
        }
        return Column(
          children: [
            const SearchBarWidget(),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.background_dark : AppColors.background_light,
                ),
                child: ListView.builder(
                  padding: EdgeInsets.all(0),
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
                  },
                ),
              ),
            ),
            BottomPlayerWidget(),
          ],
        );
      }
    );
  }
}