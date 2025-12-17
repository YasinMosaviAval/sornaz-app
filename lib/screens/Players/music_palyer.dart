import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sornaz/components/music_player/search_bar.dart';
import 'package:sornaz/helpers/app_spacing.dart';
import 'package:sornaz/audio/audio_player_provider.dart';
import 'package:sornaz/components/bottom_nav.dart';
import 'package:sornaz/audio/folder_navigator_provider.dart';
import 'package:sornaz/screens/Players/music_player_tabs.dart';
import 'package:sornaz/audio/scan/audio_file_loader.dart';

class MusicPlayerPage extends StatefulWidget {
  const MusicPlayerPage({super.key});

  @override
  State<MusicPlayerPage> createState() => _MusicPlayerPageState();
}

class _MusicPlayerPageState extends State<MusicPlayerPage> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final audio = context.read<AudioPlayerProvider>();
      final folderNav = context.read<FolderNavigatorProvider>();

      audio.start();

      AudioFileLoader.scanWithIsolate(
        roots: [
          Directory('/storage/emulated/0/'),
          Directory('/storage/9C33-6BBD/Music/')
        ],
        onProgress: (status) => audio.update(status),
        onDone: (result) {
          audio.finish(result);

          final folderPaths = result.map((f) => f.file.parent.path).toSet().toList();
          final folderMap = {for (var path in folderPaths) path: result.where((f) => f.file.parent.path == path).toList()};

          folderNav.setRoots(folderPaths.map((p) => Directory(p)).toList(), folderMap);
        },
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const SearchBarWidget(),
      body: Consumer<AudioPlayerProvider>(
        builder: (_, audio, _) {
          if (audio.isScanning) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space_24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "در حال اسکن فایل‌ها",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)
                    ),
                    const SizedBox(height: AppSpacing.space_32),
                    LinearProgressIndicator(value: audio.progress),
                    const SizedBox(height: AppSpacing.space_32),
                    Text(
                      "${audio.scannedFiles} / ${audio.totalFiles} فایل اسکن شد",
                      style: const TextStyle(fontSize: 16)
                    ),
                    const SizedBox(height: AppSpacing.space_32),
                    Text(
                      audio.currentPath, 
                      maxLines: 2, 
                      overflow: TextOverflow.ellipsis, 
                      textAlign: TextAlign.center, 
                      style: const TextStyle(
                        fontSize: 12, 
                        color: Colors.grey
                      )
                    ),
                  ],
                ),
              ),
            );
          }
          // if (audio.isLoading) return const Center(child: CircularProgressIndicator());
          return Expanded(child: MusicPlayerTabs());
        },
      ),
      bottomNavigationBar: const BottomNavBarWidget(),
    );
  }
}
