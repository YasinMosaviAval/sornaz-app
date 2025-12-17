import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sornaz/components/music_player/flat_list_view.dart';
import 'package:sornaz/components/music_player/folder_list_view.dart';
import 'package:sornaz/helpers/app_strings.dart';
import 'package:sornaz/helpers/app_translations.dart';
import 'package:sornaz/helpers/app_typography.dart';
import 'package:sornaz/audio/audio_player_provider.dart';
import 'package:sornaz/audio/folder_navigator_provider.dart';

class AudioList extends StatelessWidget {
  const AudioList({super.key});

  @override
  Widget build(BuildContext context) {
    // final appData = context.watch<AppData>();
    // final isDark = appData.isDark;

    return Consumer2<AudioPlayerProvider, FolderNavigatorProvider>(
      builder: (context, audio, folder, _) {

        // 📁 Folder Mode
        if (audio.folderMode) {
          if (folder.rootDir == null) {
            return Center(
              child: Text(
                "در حال آماده‌سازی پوشه‌ها...",
                style: AppTypography.musicPlayerAudioFileNotFound(context),
              ),
            );
          }
          return const FolderView();
        }

        // 🎵 Flat Mode
        if (audio.filteredFiles.isEmpty) {
          return Center(
            child: Text(
              AppStrings.audio_file_not_found.translate(context),
              style: AppTypography.musicPlayerAudioFileNotFound(context),
            ),
          );
        }

        return const FlatListView();
      },
    );
  }
}
