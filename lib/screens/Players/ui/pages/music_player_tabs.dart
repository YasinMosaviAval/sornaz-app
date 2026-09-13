import 'package:flutter/material.dart';
import '../components/audio_list.dart';
import '../components/bottom_player.dart';
import '../components/player_slide_navigation.dart';
import 'equalizer.dart';
import 'playlists.dart';
import 'song_information.dart';

class MusicPlayerTabs extends StatefulWidget {
  const MusicPlayerTabs({
    super.key,
    this.pages = const [NowPlayingInfoTab(), AudioList(), EqualizerTab(), PlaylistsTab()],
    this.controls = const BottomPlayerWidget(),
  });
  final List<Widget> pages;
  final Widget controls;
  @override
  State<MusicPlayerTabs> createState() => _MusicPlayerTabsState();
}

class _MusicPlayerTabsState extends State<MusicPlayerTabs> {
  final controller = PageController(initialPage: 1);
  int page = 1;
  void go(int value) {
    if (controller.hasClients)
      controller.animateToPage(
        value,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
      );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final direction = Directionality.of(context);
    return PlayerSlideNavigation(
      page: page,
      count: widget.pages.length,
      go: go,
      child: Column(
        children: [
          Expanded(
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: PageView(
                controller: controller,
                onPageChanged: (v) => setState(() => page = v),
                children: [
                  for (var i = 0; i < widget.pages.length; i++)
                    Directionality(
                      key: ValueKey('player-slide-$i'),
                      textDirection: direction,
                      child: widget.pages[i],
                    ),
                ],
              ),
            ),
          ),
          widget.controls,
        ],
      ),
    );
  }
}
