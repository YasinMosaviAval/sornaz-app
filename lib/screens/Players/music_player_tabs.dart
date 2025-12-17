import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sornaz/components/music_player/audio_list.dart';
import 'package:sornaz/provider/audio_player_provider.dart';
import 'package:sornaz/screens/Players/equalizer.dart';
import 'package:sornaz/screens/Players/song_information.dart';

class MusicPlayerTabs extends StatefulWidget {
  const MusicPlayerTabs({super.key});

  @override
  State<MusicPlayerTabs> createState() => _MusicPlayerTabsState();
}

class _MusicPlayerTabsState extends State<MusicPlayerTabs> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    final audio = context.read<AudioPlayerProvider>();
    audio.addListener(_updateTabCount);
  }

  void _updateTabCount() {
    final audio = context.read<AudioPlayerProvider>();
    final hasPlaying = audio.currentAudio != null;
    final newLength = hasPlaying ? 3 : 2;
    if (_tabController.length != newLength) {
      final previousIndex = _tabController.index;
      _tabController.dispose();
      _tabController = TabController(
        length: newLength,
        vsync: this,
        initialIndex: previousIndex.clamp(0, newLength - 1),
      );
      if (hasPlaying && previousIndex == 1 && newLength == 3) {
        _tabController.index = 1;
      }
      setState(() {});
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final audio = context.watch<AudioPlayerProvider>();
    final hasPlaying = audio.currentAudio != null;
    return Column(
      children: [
        Expanded(
          child: TabBarView(
            controller: _tabController,
            physics: const BouncingScrollPhysics(),
            children: hasPlaying
              ? const [
                  AudioList(),
                  NowPlayingInfoTab(),
                  EqualizerTab(),
                ]
              : [
                  AudioList(),
                  EqualizerTab(),
                ],
          ),
        ),
      ],
    );
  }
}