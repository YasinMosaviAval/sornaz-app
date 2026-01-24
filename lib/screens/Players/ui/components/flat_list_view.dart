
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sornaz/helpers/app_strings.dart';
import 'package:sornaz/helpers/app_translations.dart';
import 'package:sornaz/helpers/app_typography.dart';
import 'package:sornaz/screens/Players/providers/audio_player_provider.dart';
import 'package:sornaz/screens/Players/ui/components/file_actions.dart';
import 'package:sornaz/screens/Players/ui/components/audio_item.dart';
import 'package:sornaz/screens/Players/ui/components/bottom_player.dart';
import 'package:sornaz/helpers/app_colors.dart';
import 'package:sornaz/helpers/app_data.dart';
import 'package:sornaz/screens/Players/ui/components/search_bar.dart';

class FlatListView extends StatelessWidget {
  final ScrollController? scrollController;

  const FlatListView({super.key, this.scrollController});

  @override
  Widget build(BuildContext context) {
    final appData = Provider.of<AppData>(context);
    final isDark = appData.isDark;
    
    return Consumer<AudioPlayerProvider>(
      builder: (context, provider, _) {
        if (provider.filteredFiles.isEmpty && !provider.isHiveLoading) {
          return Center(
            child: Text(
              AppStrings.audio_file_not_found.translate(context),
              style: AppTypography.musicPlayerAudioFileNotFound(context),
            ),
          );
        }
        return Column(
          children: [
            const SearchBarWidget(),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.music_player_flat_list_view_decoration_color(isDark: isDark),
                ),
                child: ListView.builder(
                  controller: scrollController,
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