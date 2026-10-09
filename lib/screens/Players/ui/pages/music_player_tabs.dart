import 'package:flutter/material.dart';
import 'package:sornaz/screens/Social/social_widgets.dart';
import '../components/flat_list_view.dart';
import '../components/folder_list_view.dart';
import '../components/bottom_player.dart';
import '../components/player_slide_navigation.dart';
import 'equalizer.dart';
import 'playlists.dart';
import '../../services/player_settings.dart';

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
    this.onTabChanged,
  });
  final List<Widget> pages;
  final Widget controls;
  final ValueChanged<int>? onTabChanged;
  @override
  State<MusicPlayerTabs> createState() => _MusicPlayerTabsState();
}

class _MusicPlayerTabsState extends State<MusicPlayerTabs>
    with TickerProviderStateMixin {
  late TabController tabs;
  List<int> visible = [];
  final settings = PlayerSettings.instance;
  void syncTabs() {
    final next = settings.tabOrder
        .map(int.parse)
        .where(
          (i) => i < widget.pages.length && !settings.hiddenTabs.contains('$i'),
        )
        .toList();
    if (next.isEmpty) next.add(0);
    if (visible.join(',') == next.join(',')) return;
    final selected = visible.isEmpty ? 0 : visible[tabs.index];
    if (visible.isNotEmpty) {
      tabs.removeListener(changed);
      tabs.dispose();
    }
    visible = next;
    tabs = TabController(
      length: visible.length,
      vsync: this,
      initialIndex: visible.contains(selected) ? visible.indexOf(selected) : 0,
    );
    tabs.addListener(changed);
    if (mounted) setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onTabChanged?.call(visible[tabs.index]);
    });
  }

  @override
  void initState() {
    super.initState();
    syncTabs();
    settings.addListener(syncTabs);
    settings.load();
  }

  void changed() {
    if (mounted) setState(() {});
    widget.onTabChanged?.call(visible[tabs.index]);
  }

  @override
  void dispose() {
    settings.removeListener(syncTabs);
    tabs.removeListener(changed);
    tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PlayerSlideNavigation(
    page: tabs.index,
    count: visible.length,
    go: tabs.animateTo,
    child: Column(
      children: [
        TabBar(
          controller: tabs,
          labelPadding: EdgeInsets.zero,
          labelStyle: Theme.of(context).textTheme.labelLarge,
          tabs: [
            for (final i in visible)
              Tab(
                text: socialText(
                  context,
                  const ['آهنگ‌ها', 'پوشه‌ها', 'لیست پخش‌ها', 'اکولایزر'][i],
                  const ['Songs', 'Folders', 'Playlists', 'Equalizer'][i],
                ),
              ),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: tabs,
            children: [for (final i in visible) widget.pages[i]],
          ),
        ),
        widget.controls,
      ],
    ),
  );
}
