import 'package:flutter/material.dart';
import 'package:sornaz/screens/Social/social_widgets.dart';
import '../components/flat_list_view.dart';
import '../components/folder_list_view.dart';
import '../components/bottom_player.dart';
import '../components/player_slide_navigation.dart';
import 'equalizer.dart';
import 'playlists.dart';

class MusicPlayerTabs extends StatefulWidget {
  const MusicPlayerTabs({
    super.key,
    this.pages = const [
      FlatListView(),
      FolderView(),
      PlaylistsTab(),
      EqualizerTab(),
    ],
    this.controls = const BottomPlayerWidget(),
  });
  final List<Widget> pages;
  final Widget controls;
  @override
  State<MusicPlayerTabs> createState() => _MusicPlayerTabsState();
}

class _MusicPlayerTabsState extends State<MusicPlayerTabs>
    with SingleTickerProviderStateMixin {
  late final tabs = TabController(length: widget.pages.length, vsync: this);
  @override
  void initState() {
    super.initState();
    tabs.addListener(changed);
  }

  void changed() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    tabs.removeListener(changed);
    tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PlayerSlideNavigation(
    page: tabs.index,
    count: widget.pages.length,
    go: tabs.animateTo,
    child: Column(
      children: [
        TabBar(
          controller: tabs,
          labelPadding: EdgeInsets.zero,
          labelStyle: const TextStyle(fontSize: 12),
          tabs: [
            Tab(text: socialText(context, 'آهنگ‌ها', 'Songs')),
            Tab(text: socialText(context, 'پوشه‌ها', 'Folders')),
            Tab(text: socialText(context, 'پلی‌لیست‌ها', 'Playlists')),
            Tab(text: socialText(context, 'اکولایزر', 'Equalizer')),
          ],
        ),
        Expanded(
          child: TabBarView(controller: tabs, children: widget.pages),
        ),
        widget.controls,
      ],
    ),
  );
}
