import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sornaz/components/audio_list.dart';
import 'package:sornaz/components/audio_player_search_bar.dart';
import 'package:sornaz/components/bottom_player.dart';
import 'package:sornaz/helpers/app_spacing.dart';
import 'package:sornaz/provider/audio_player_provider.dart';
import 'package:sornaz/components/bottom_nav.dart';
import 'package:sornaz/provider/folder_navigator_provider.dart';
import 'package:sornaz/services/audio_file_loader.dart';

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

    audio.start();


    AudioFileLoader.scanWithIsolate(
      roots: [
        Directory('/storage/emulated/0/'), // 79
        Directory('/storage/9C33-6BBD/Music/'),
      ],
      onProgress: audio.update,
      onDone: (result) {
        audio.setFileList(result);
        final folderNav = context.read<FolderNavigatorProvider>();

        final folderPaths = result.map((f) => f.file.parent.path).toSet().toList();

        final folderMap = {
          for (var path in folderPaths)
            path: result.where((f) => f.file.parent.path == path).toList()
        };

        folderNav.setRoots(
          folderPaths.map((p) => Directory(p)).toList(),
          folderMap,
        );
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
          if (audio.isLoading) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space_24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "در حال اسکن فایل‌ها",
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: AppSpacing.space_32),
                    LinearProgressIndicator(value: audio.progress),
                    const SizedBox(height: AppSpacing.space_32),
                    Text(
                      "${audio.scannedFiles} / ${audio.totalFiles} فایل اسکن شد",
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: AppSpacing.space_32),
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
              ),
            );
          }

          return Column(
            children: const [
              // Expanded(child: AudioList()),
              Expanded(
                child: MusicPlayerTabs(),
              ),
              BottomPlayerWidget(),
            ],
          );
        },
      ),
      bottomNavigationBar: const BottomNavBarWidget(),
    );
  }
}



class MusicPlayerTabs extends StatelessWidget {
  const MusicPlayerTabs({super.key});

  @override
  Widget build(BuildContext context) {
    final audio = context.watch<AudioPlayerProvider>();
    final bool hasPlaying = audio.currentIndex != null;

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          // 🔹 TabBar
          TabBar(
            indicatorColor: Theme.of(context).colorScheme.primary,
            tabs: [
              Tab(
                icon: Icon(
                  Icons.music_note,
                  color: hasPlaying ? null : Colors.grey,
                ),
                text: 'اطلاعات آهنگ',
              ),
              const Tab(
                icon: Icon(Icons.music_note),
                text: 'Music Player',
              ),
              const Tab(
                icon: Icon(Icons.equalizer),
                text: 'اکولایزر',
              ),
            ],
          ),

          // 🔹 TabBarView
          Expanded(
            child: TabBarView(
              physics: hasPlaying
                  ? const BouncingScrollPhysics()
                  : const NeverScrollableScrollPhysics(), // غیرفعال swipe
              children: [
                // تب اطلاعات آهنگ
                hasPlaying
                    ? const NowPlayingInfoTab()
                    : const DisabledNowPlayingTab(),

                // تب اکولایزر
                const AudioList(),
                const EqualizerTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


class NowPlayingInfoTab extends StatelessWidget {
  const NowPlayingInfoTab({super.key});

  @override
  Widget build(BuildContext context) {
    final audio = context.watch<AudioPlayerProvider>();
    final file = audio.currentAudio;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Text(
          //   file?.title ?? '',
          //   style: Theme.of(context).textTheme.titleLarge,
          // ),
          const SizedBox(height: 8),
          // Text(
          //   file?.artist ?? 'نامشخص',
          //   style: Theme.of(context).textTheme.bodyMedium,
          // ),
          const SizedBox(height: 16),
          Text('مسیر فایل:'),
          Text(
            file?.file.path ?? '',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class DisabledNowPlayingTab extends StatelessWidget {
  const DisabledNowPlayingTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.music_off, size: 48, color: Colors.grey),
          const SizedBox(height: 12),
          const Text(
            'هیچ آهنگی در حال پخش نیست',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}


class EqualizerTab extends StatelessWidget {
  const EqualizerTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        EqualizerSlider(label: 'Bass'),
        EqualizerSlider(label: 'Mid'),
        EqualizerSlider(label: 'Treble'),
      ],
    );
  }
}

class EqualizerSlider extends StatelessWidget {
  final String label;
  const EqualizerSlider({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        Slider(
          min: -10,
          max: 10,
          value: 0,
          onChanged: (_) {},
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}



