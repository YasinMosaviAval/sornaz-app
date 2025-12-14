import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sornaz/components/audio_flat_list_view.dart';
import 'package:sornaz/components/audio_folder_list_view.dart';
import 'package:sornaz/helpers/app_colors.dart';
import 'package:sornaz/helpers/app_data.dart';
import 'package:sornaz/helpers/app_strings.dart';
import 'package:sornaz/helpers/app_translations.dart';
import 'package:sornaz/helpers/app_typography.dart';
import 'package:sornaz/provider/audio_player_provider.dart';
import 'package:sornaz/provider/folder_navigator_provider.dart';

class AudioList extends StatelessWidget {
  const AudioList({super.key});

  @override
  Widget build(BuildContext context) {
    final appData = context.watch<AppData>();
    final isDark = appData.isDark;

    return Consumer2<AudioPlayerProvider, FolderNavigatorProvider>(
      builder: (context, audio, folder, _) {

        // 🔵 اسکن خودکار با درصد + مسیر
        if (audio.isLoading) {
          return Container(
            color: isDark
                ? AppColors.background_dark
                : AppColors.background_light,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                LinearProgressIndicator(value: audio.progress),
                const SizedBox(height: 16),
                Text(
                  '${(audio.progress * 100).toStringAsFixed(0)}٪',
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 12),
                Text(
                  audio.currentPath,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          );
        }

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
