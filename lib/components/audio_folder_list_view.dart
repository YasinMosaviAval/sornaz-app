import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sornaz/components/audio_breadcrumb.dart';
import 'package:sornaz/helpers/app_colors.dart';
import 'package:sornaz/helpers/app_data.dart';
import 'package:sornaz/helpers/app_spacing.dart';
import 'package:sornaz/helpers/app_typography.dart';
import 'package:sornaz/provider/audio_player_provider.dart';
import 'package:sornaz/components/audio_item.dart';
import 'package:sornaz/provider/folder_navigator_provider.dart';


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
          return ExpansionTile(
            title: Text(
              folderPath.split('/').last, 
              style: AppTypography.musicPlayerAudioFolderListViewTitle(context),
            ),
            collapsedIconColor: isDark ? AppColors.text_primary_dark : AppColors.text_primary_light,
            children: [
              for (int i = 0; i < files.length; i++)
                AudioItem(
                  audio: files[i],
                  index: provider.filteredFiles.indexOf(files[i]),
                  isPlaying: provider.filteredFiles.indexOf(files[i]) == provider.currentIndex,
                ),
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
      return const Center(
        child: Text("در حال بارگذاری پوشه‌ها..."),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: isDark? AppColors.background_dark : AppColors.background_light
      ),
      child: Column(
        children: [
          BreadcrumbWidget(),
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
                      leading: Icon(Icons.folder, color: isDark ? AppColors.text_secondary_dark : AppColors.text_secondary_light,),
                      title: Text(dir.path.split("/").last, style: AppTypography.musicPlayerFolderViewTitle(context)),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.space_8),
                        child: Row(
                          children: [
                            Text(
                              "${nav.folderAudioCount[dir.path] ?? 0} آهنگ",
                              style: AppTypography.musicPlayerFolderViewSubtitle(context)
                            ),
                          ],
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
                      context.read<AudioPlayerProvider>()
                          .playFromFolder(files, i);
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
