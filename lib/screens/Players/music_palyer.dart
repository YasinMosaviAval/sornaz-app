import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sornaz/components/audio_list.dart';
import 'package:sornaz/components/audio_player_search_bar.dart';
import 'package:sornaz/components/bottom_player.dart';
import 'package:sornaz/provider/audio_player_provider.dart';
import 'package:sornaz/components/bottom_nav.dart';
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
        Directory('/storage/emulated/0'),
        Directory('/storage'),
      ],
      onProgress: audio.update,
      onDone: audio.finish,
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
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(value: audio.progress),
                  const SizedBox(height: 16),
                  Text(
                    'در حال اسکن موسیقی‌ها ${(audio.progress * 100).toStringAsFixed(0)}٪',
                  ),
                ],
              ),
            );
          }

          return Column(
            children: const [
              Expanded(child: AudioList()),
              BottomPlayerWidget(),
            ],
          );
        },
      ),
      bottomNavigationBar: const BottomNavBarWidget(),
    );
  }
}
