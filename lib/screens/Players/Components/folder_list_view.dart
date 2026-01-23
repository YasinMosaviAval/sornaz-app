import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sornaz/screens/Players/Components/breadcrumb.dart';
import 'package:sornaz/screens/Players/Components/bottom_player.dart';
import 'package:sornaz/helpers/app_colors.dart';
import 'package:sornaz/helpers/app_data.dart';
import 'package:sornaz/helpers/app_strings.dart';
import 'package:sornaz/helpers/app_translations.dart';
import 'package:sornaz/helpers/app_typography.dart';
import 'package:sornaz/screens/Players/audio/audio_player_provider.dart';
import 'package:sornaz/screens/Players/Components/audio_item.dart';
import 'package:sornaz/screens/Players/audio/folder_navigator_provider.dart';
import 'package:sornaz/screens/Players/Components/search_bar.dart';

/*
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
*/

/*
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
              padding: EdgeInsets.all(0),
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
                      leading: Icon(Icons.folder, color: AppColors.music_player_folder_list_view_leading_icon_color(isDark: isDark)),
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
                        color: AppColors.music_player_folder_list_view_trailing_icon_color(isDark: isDark),
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
*/

/*
class FolderView extends StatelessWidget {
  const FolderView({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<AppData>(context).isDark;
    final nav = context.watch<FolderNavigatorProvider>();
    final provider = context.read<AudioPlayerProvider>();

    if (nav.currentDir == null) return Center(child: Text("در حال بارگذاری..."));

    return Column(
      children: [
        AppSpacing.sizedBoxH48(),
        BreadcrumbWidget(),
        Expanded(
          child: ListView(
            padding: EdgeInsets.all(0),
            children: [
              for (var dir in nav.subFolders)
                ListTile(
                  leading: Icon(Icons.folder),
                  title: Text(dir.path.split('/').last),
                  trailing: Icon(Icons.chevron_right),
                  onTap: () => nav.enterRealFolder(dir),
                ),
              // for (int i = 0; i < nav.audioFiles.length; i++)
              //   AudioItem(
              //     audio: nav.audioFiles[i],
              //     index: provider.filteredFiles.indexOf(nav.audioFiles[i]),
              //     // isPlaying: provider.currentIndex == provider.filteredFiles.indexOf(nav.audioFiles[i]),
              //     // index: i,
              //     // isPlaying: provider.currentAudio != null && provider.currentAudio!.file.path == nav.audioFiles[i].file.path,
              //     isPlaying: provider.filteredFiles.indexOf(nav.audioFiles[i]) == provider.currentIndex,
              //     onTap: () {
              //       provider.playFromFolder(nav.audioFiles, i);
              //     },
              //   ),
              for (int i = 0; i < nav.audioFiles.length; i++)

                AudioItem(
                  audio: nav.audioFiles[i],
                  index: i,
                  isPlaying: provider.currentAudio != null && provider.currentAudio!.file.path == nav.audioFiles[i].file.path,
                  onTap: () => provider.playFromFolder(nav.audioFiles, i)
                ),
            ],
          ),
        ),
        BottomPlayerWidget(),
      ]
    );
  }
}
*/

/*
class FolderView extends StatelessWidget {
  const FolderView({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<AppData>(context).isDark;

    return Consumer2<FolderNavigatorProvider, AudioPlayerProvider>(
      builder: (context, nav, provider, _) {
        if (nav.currentDir == null) return Center(child: Text("در حال بارگذاری فولدرها..."));

        final bool isCompletelyEmpty = nav.subFolders.isEmpty && nav.audioFiles.isEmpty;
        loggingSornaz("audioFiles.length = ${nav.audioFiles.length}");

        final hasSubFolders = nav.subFolders.isNotEmpty;
        final hasAudioFiles = nav.audioFiles.isNotEmpty;

        // اگر هیچی نبود
        if (!hasSubFolders && !hasAudioFiles) {
          return const Center(child: Text("هیچ فولدر یا آهنگی در این مسیر یافت نشد"));
        }

        return Column(
          children: [
            AppSpacing.sizedBoxH32(),
            const BreadcrumbWidget(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    nav.showOnlyFoldersWithAudio 
                        ? "فقط فولدرهای دارای آهنگ" 
                        : "نمایش همه فولدرها",
                    style: AppTypography.musicPlayerFolderListViewSwitchText(context),
                  ),
                  Switch(
                    value: nav.showOnlyFoldersWithAudio,
                    onChanged: (value) {
                      nav.toggleShowOnlyAudioFolders();
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: 
              // isCompletelyEmpty
              //   ? Center(child: Text("هیچ فولدر یا آهنگی یافت نشد"))
              //   : 
                ListView.builder(
                padding: EdgeInsets.all(0),
                itemCount: nav.subFolders.length + nav.audioFiles.length,
                itemBuilder: (context, index) {
                   loggingSornaz("ListView itemCount = ${nav.subFolders.length + nav.audioFiles.length}");
                  // اول زیرفولدرها
                  if (index < nav.subFolders.length) {
                    final dir = nav.subFolders[index];
                    return ListTile(
                      leading: Icon(Icons.folder, color: AppColors.music_player_folder_list_view_leading_icon_color(isDark: isDark)),
                      title: Text(dir.path.split('/').last, style: AppTypography.musicPlayerFolderViewTitle(context)),
                      trailing: Icon(Icons.chevron_right, color: AppColors.music_player_folder_list_view_trailing_icon_color(isDark: isDark)),
                      onTap: () => nav.enterRealFolder(dir),
                    );
                  }

                  // بعد آهنگ‌ها
                  final audioIndex = index - nav.subFolders.length;
                  final audio = nav.audioFiles[audioIndex];

                  return AudioItem(
                    audio: audio,
                    index: audioIndex,
                    isPlaying: provider.currentAudio != null && provider.currentAudio!.file.path == audio.file.path,
                    onTap: () {
                      provider.playFromFolder(nav.audioFiles, audioIndex);
                    },
                  );
                },
              ),
            ),
            const BottomPlayerWidget(),
          ],
        );
      },
    );
  }
}
*/

class FolderView extends StatelessWidget {
  const FolderView({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<AppData>(context).isDark;

    return Consumer2<FolderNavigatorProvider, AudioPlayerProvider>(
      builder: (context, nav, provider, _) {
        if (nav.currentDir == null) return Center(child: Text(AppStrings.folder_list_view_preparing_folders.translate(context)));

        final hasContent = nav.subFolders.isNotEmpty || nav.audioFiles.isNotEmpty;

        if (!hasContent) return Center(child: Text(AppStrings.no_folder_or_audio_file_found_in_this_path.translate(context)));

        return Column(
          children: [
            const SearchBarWidget(),
            const BreadcrumbWidget(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    nav.showOnlyFoldersWithAudio 
                      ? AppStrings.show_folders_contains_audio_files.translate(context)
                      : AppStrings.show_all_folders.translate(context),
                    style: AppTypography.musicPlayerFolderListViewSwitchText(context),
                  ),
                  Switch(
                    value: nav.showOnlyFoldersWithAudio,
                    onChanged: (value) => nav.toggleShowOnlyAudioFolders()
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                
                children: [
                  ...nav.subFolders.map((dir) {
                    // loggingSornaz("  ==  ${dir.path.split('/').last}");
                    return ListTile(
                      leading: Icon(Icons.folder, color: AppColors.music_player_folder_list_view_leading_icon_color(isDark: isDark)),
                      title: Text(dir.path.split('/').last, style: AppTypography.musicPlayerFolderViewTitle(context)),
                      trailing: Icon(Icons.chevron_right, color: AppColors.music_player_folder_list_view_trailing_icon_color(isDark: isDark)),
                      onTap: () => nav.enterRealFolder(dir),
                    );
                  }),
                  ...nav.audioFiles.asMap().entries.map((entry) {
                    final i = entry.key;
                    final audio = entry.value;
                    return AudioItem(
                      audio: audio,
                      index: i,
                      isPlaying: provider.currentAudio != null && provider.currentAudio!.file.path == audio.file.path,
                      onTap: () => provider.playFromFolder(nav.audioFiles, i)
                    );
                  }),
                ],
              ),
            ),
            const BottomPlayerWidget(),
          ],
        );
      },
    );
  }
}

