import 'package:sornaz/components/scroll_aware_scaffold.dart';
import 'package:flutter/material.dart';
import 'main_tabs.dart';

/// Registers the fixed chrome with the shell and scrolls only the page body.
class MainTabScaffold extends StatefulWidget {
  const MainTabScaffold({
    super.key,
    required this.index,
    required this.body,
    this.appBar,
    this.drawer,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.backgroundColor,
  });
  final int index;
  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? drawer, bottomNavigationBar, floatingActionButton;
  final Color? backgroundColor;
  @override
  State<MainTabScaffold> createState() => _MainTabScaffoldState();
}

class _MainTabScaffoldState extends State<MainTabScaffold> {
  MainTabsScope? scope;
  void publish() {
    final bar = widget.appBar;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) scope?.setChrome(widget.index, bar);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    scope = MainTabsScope.maybeOf(context);
    publish();
  }

  @override
  void didUpdateWidget(MainTabScaffold old) {
    super.didUpdateWidget(old);
    if (old.appBar != widget.appBar) publish();
  }

  @override
  Widget build(BuildContext context) => ScrollAwareScaffold(
    appBar: scope == null ? widget.appBar : null,
    drawer: scope == null ? widget.drawer : null,
    bottomNavigationBar: scope == null ? widget.bottomNavigationBar : null,
    backgroundColor: widget.backgroundColor,
    body: widget.body,
    floatingActionButton: widget.floatingActionButton,
  );
}
