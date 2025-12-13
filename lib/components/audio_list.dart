/*
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

class AudioList extends StatelessWidget {
  const AudioList({super.key});

  @override
  Widget build(BuildContext context) {
    final appData = Provider.of<AppData>(context);
    final isDark = appData.isDark;
    final provider = context.watch<AudioPlayerProvider>();

  if (provider.isLoading) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.background_dark : AppColors.background_light,
      ),
      child: Center(child: CircularProgressIndicator()
      )
    );
  }

  if (provider.filteredFiles.isEmpty) {
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

  if (provider.folderMode) return FolderView();
  // if (provider.folderMode) return FolderListView();

  return FlatListView();
  }
}
*/

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

        // لودینگ
        if (audio.isLoading) {
          return Container(
            color: isDark ? AppColors.background_dark : AppColors.background_light,
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        // حالت Folder Mode
        if (audio.folderMode) {
          // 👈 هنوز پوشه انتخاب نشده
          if (folder.rootDir == null) {
            return Container(
              color: isDark ? AppColors.background_dark : AppColors.background_light,
              child: Center(
                child: Text(
                  "لطفاً پوشه آهنگ‌ها را انتخاب کنید",
                  style: AppTypography.musicPlayerAudioFileNotFound(context),
                ),
              ),
            );
          }

          // 👈 پوشه انتخاب شده → نمایش فولدر
          return const FolderView();
        }

        // حالت Flat
        if (audio.filteredFiles.isEmpty) {
          return Container(
            color: isDark ? AppColors.background_dark : AppColors.background_light,
            child: Center(
              child: Text(
                AppStrings.audio_file_not_found.translate(context),
                style: AppTypography.musicPlayerAudioFileNotFound(context),
              ),
            ),
          );
        }

        return const FlatListView();
      },
    );
  }
}
