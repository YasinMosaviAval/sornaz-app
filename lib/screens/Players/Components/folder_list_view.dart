import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sornaz/screens/Players/Components/breadcrumb.dart';
import 'package:sornaz/screens/Players/Components/bottom_player.dart';
import 'package:sornaz/helpers/app_colors.dart';
import 'package:sornaz/helpers/app_data.dart';
import 'package:sornaz/helpers/app_spacing.dart';
import 'package:sornaz/helpers/app_strings.dart';
import 'package:sornaz/helpers/app_translations.dart';
import 'package:sornaz/helpers/app_typography.dart';
import 'package:sornaz/audio/audio_player_provider.dart';
import 'package:sornaz/screens/Players/Components/audio_item.dart';
import 'package:sornaz/audio/folder_navigator_provider.dart';
import 'package:sornaz/screens/Players/Components/search_bar.dart';

class FolderListView extends StatelessWidget {
  const FolderListView({super.key});

  @override
  Widget build(BuildContext context) {
    final appData = Provider.of<AppData>(context);
    final isDark = appData.isDark;
    final provider = context.watch<AudioPlayerProvider>();
    final folders = provider.folderTree.keys.toList()..sort();

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.background_dark : AppColors.background_light,
      ),
      child: ListView.builder(
        itemCount: folders.length,
        itemBuilder: (context, index) {
          final folderPath = folders[index];
          final files = provider.folderTree[folderPath]!;
          final fileIndexes = files.map((f) => provider.filteredFiles.indexOf(f)).toList();
          return Column(
            children: [
              ExpansionTile(
                title: Text(
                  folderPath.split('/').last, 
                  style: AppTypography.musicPlayerAudioFolderListViewTitle(context),
                ),
                collapsedIconColor: isDark ? AppColors.text_primary_dark : AppColors.text_primary_light,
                children: [
                  for (int i = 0; i < files.length; i++)
                    AudioItem(
                      audio: files[i],
                      index: fileIndexes[i],
                      isPlaying: fileIndexes[i] == provider.currentIndex,
                    ),
                ],
              ),
              BottomPlayerWidget(),
            ],
          );
        },
      ),
    );
  }
}

class FolderView extends StatelessWidget {
  const FolderView({super.key});

  @override
  Widget build(BuildContext context) {
    final appData = Provider.of<AppData>(context);
    final isDark = appData.isDark;
    final nav = context.watch<FolderNavigatorProvider>();
    final subFolders = nav.subFolders;
    final files = nav.audioFiles;

    if (nav.rootDir == null || nav.currentDir == null) {
      return Center(
        child: Text(AppStrings.folder_list_view_preparing_folders.translate(context)),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.background_dark : AppColors.background_light
      ),
      child: Column(
        children: [
          const SearchBarWidget(),
          const BreadcrumbWidget(),
          Expanded(
            child: ListView(
              children: [
                for (var dir in subFolders)
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        width: 0.8,
                        color: isDark ? AppColors.border_dark : AppColors.border_light,
                      ),
                    ),
                    child: ListTile(
                      leading: Icon(Icons.folder, color: isDark ? AppColors.text_secondary_dark : AppColors.text_secondary_light),
                      title: Text(dir.path.split("/").last, style: AppTypography.musicPlayerFolderViewTitle(context)),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.space_8),
                        child: Text(
                          "${nav.folderAudioCount[dir.path] ?? 0} ${AppStrings.folder_list_view_song.translate(context)}",
                          style: AppTypography.musicPlayerFolderViewSubtitle(context)
                        ),
                      ),
                      contentPadding: EdgeInsets.symmetric(horizontal: AppSpacing.space_16),
                      trailing: Icon(
                        Icons.chevron_right,
                        color: isDark ? AppColors.text_primary_dark : AppColors.text_primary_light,
                      ),
                      onTap: () => nav.enterFolder(dir),
                    ),
                  ),
                for (int i = 0; i < files.length; i++)
                  AudioItem(
                    audio: files[i],
                    index: i,
                    isPlaying: false,
                    onTap: () {
                      // context.read<AudioPlayerProvider>().playFromFolder(files, i);
                    },
                  ),
              ],
            ),
          ),
          const BottomPlayerWidget(),
        ],
      ),
    );
  }
}
