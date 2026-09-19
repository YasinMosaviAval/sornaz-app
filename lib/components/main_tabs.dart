import 'package:sornaz/components/scroll_aware_scaffold.dart';
import 'bottom_nav.dart';
import 'home_top_bar.dart';
import 'package:sornaz/screens/Home/ui/components/app_drawer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:sornaz/helpers/app_data.dart';
import 'package:sornaz/screens/Home/ui/pages/home.dart';
import 'package:sornaz/screens/Home/ui/pages/music_tools.dart';
import 'package:sornaz/screens/Social/my_profile_page.dart';
import 'package:sornaz/screens/Site/site_panel_page.dart';
import 'package:sornaz/screens/Social/user_panel.dart';

class MainTabsScope extends InheritedWidget {
  const MainTabsScope({
    super.key,
    required this.index,
    required this.select,
    required this.setEditorOpen,
    required this.setChrome,
    required super.child,
  });
  final int index;
  final ValueChanged<int> select;
  final ValueChanged<bool> setEditorOpen;
  final void Function(int, PreferredSizeWidget?) setChrome;
  static MainTabsScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<MainTabsScope>();
  @override
  bool updateShouldNotify(MainTabsScope oldWidget) => index != oldWidget.index;
}

/// One route for the five destinations, so back never walks through tab history.
class MainTabs extends StatefulWidget {
  const MainTabs({
    super.key,
    this.initialIndex = 0,
    this.initialChild,
    this.pages,
  });
  final int initialIndex;
  final Widget? initialChild;
  final List<Widget>? pages;
  @override
  State<MainTabs> createState() => _MainTabsState();
}

class _MainTabsState extends State<MainTabs> {
  late int index = widget.initialIndex;
  bool editorOpen = false;
  final Map<int, PreferredSizeWidget?> chrome = {};
  late final pages =
      widget.pages ??
      [
        for (var i = 0; i < 5; i++)
          i == widget.initialIndex && widget.initialChild != null
              ? widget.initialChild!
              : const [
                  HomePage(),
                  SitePanelPage(),
                  UserPanelPage(),
                  MusicToolsPage(),
                  MyProfilePage(),
                ][i],
      ];
  void setChrome(int page, PreferredSizeWidget? bar) {
    if (!mounted || identical(chrome[page], bar)) return;
    chrome[page] = bar;
    if (page == index) setState(() {});
  }

  void setEditorOpen(bool value) {
    if (editorOpen == value) return;
    editorOpen = value;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
  }

  late final controller = PageController(initialPage: index);
  void select(int value) {
    if (value == index || editorOpen) return;
    if ((value - index).abs() > 1) {
      controller.jumpToPage(value);
      return;
    }
    controller.animateToPage(
      value,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MainTabsScope(
    index: index,
    select: select,
    setEditorOpen: setEditorOpen,
    setChrome: setChrome,
    child: PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        // An editor's own PopScope gets first responsibility for unsaved changes.
        final route = ModalRoute.of(context);
        if (route?.willHandlePopInternally == true) {
          Navigator.of(context).pop();
          return;
        }
        if (editorOpen) return;
        if (index != 0) {
          select(0);
        } else {
          SystemNavigator.pop();
        }
      },
      child: ScrollAwareScaffold(
        appBar: chrome[index] ?? const HomeTopBar(),
        drawer: const AppDrawer(),
        bottomNavigationBar: editorOpen
            ? null
            : BottomNavBarWidget(selectedIndex: index),
        body: PageView.builder(
          reverse: true,
          controller: controller,
          physics: editorOpen ? const NeverScrollableScrollPhysics() : null,
          itemCount: 5,
          onPageChanged: (value) {
            setState(() => index = value);
            context.read<AppData>().setBottomNavIndex(value);
          },
          itemBuilder: (_, value) =>
              _RetainedTab(index: value, child: pages[value]),
        ),
      ),
    ),
  );
}

class _RetainedTab extends StatefulWidget {
  const _RetainedTab({required this.index, required this.child});
  final int index;
  final Widget child;
  @override
  State<_RetainedTab> createState() => _RetainedTabState();
}

class _RetainedTabState extends State<_RetainedTab>
    with AutomaticKeepAliveClientMixin {
  bool visited = false;
  @override
  bool get wantKeepAlive => true;
  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (MainTabsScope.maybeOf(context)?.index == widget.index) visited = true;
    if (!visited) return const SizedBox.shrink();
    final primary = PrimaryScrollController.maybeOf(context);
    return MainTabsScope.maybeOf(context)?.index == widget.index &&
            primary != null
        ? PrimaryScrollController(controller: primary, child: widget.child)
        : PrimaryScrollController.none(child: widget.child);
  }
}
