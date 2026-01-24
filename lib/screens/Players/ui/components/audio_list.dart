import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sornaz/screens/Players/library/audio_library_manager.dart';
import 'package:sornaz/screens/Players/providers/audio_player_provider.dart';
import 'package:sornaz/screens/Players/providers/folder_navigator_provider.dart';
import 'package:sornaz/screens/Players/ui/components/flat_list_view.dart';
import 'package:sornaz/screens/Players/ui/components/folder_list_view.dart';
import 'package:sornaz/helpers/app_strings.dart';
import 'package:sornaz/helpers/app_translations.dart';
import 'package:sornaz/helpers/app_typography.dart';

class AudioList extends StatelessWidget {
  const AudioList({super.key});

  @override
  Widget build(BuildContext context) {
    // final appData = Provider.of<AppData>(context);
    // final isDark = appData.isDark;

    return Consumer3<AudioPlayerProvider, FolderNavigatorProvider, AudioLibraryManager>(
      builder: (context, audio, folder, library, _) {
        if (library.isScanning) return Center(child: CircularProgressIndicator());
        if (audio.filteredFiles.isEmpty && !audio.isHiveLoading) {
          return Center(
            child: Text(
              AppStrings.audio_file_not_found.translate(context),
              style: AppTypography.musicPlayerAudioFileNotFound(context),
            ),
          );
        }
        if (audio.folderMode) {
          if (folder.rootDir == null) {
            return Center(
              child: Text(
                AppStrings.audio_list_preparing_folders.translate(context),
                style: AppTypography.musicPlayerAudioFileNotFound(context),
              ),
            );
          }
          return const FolderView();
        }
        return const FlatListView();
      },
    );
  }
}


