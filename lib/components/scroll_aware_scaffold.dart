import 'package:flutter/material.dart';

/// Hides only toolbar chrome for downward vertical scrolling. Horizontal
/// carousels and programmatic scrolling do not change toolbar visibility.
class ScrollAwareScaffold extends StatefulWidget {
  const ScrollAwareScaffold({
    super.key,
    this.scaffoldKey,
    this.appBar,
    this.pinTopBar = false,
    this.body,
    this.drawer,
    this.endDrawer,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.backgroundColor,
    this.resizeToAvoidBottomInset,
    this.extendBody = false,
    this.extendBodyBehindAppBar = false,
    this.drawerEnableOpenDragGesture = true,
    this.endDrawerEnableOpenDragGesture = true,
    this.onDrawerChanged,
    this.onEndDrawerChanged,
    this.bottomSheet,
    this.persistentFooterButtons,
    this.drawerScrimColor,
    this.primary = true,
    this.restorationId,
  });
  final Key? scaffoldKey;
  final bool pinTopBar;
  final PreferredSizeWidget? appBar;
  final Widget? body,
      drawer,
      endDrawer,
      bottomNavigationBar,
      floatingActionButton,
      bottomSheet;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final Color? backgroundColor, drawerScrimColor;
  final bool? resizeToAvoidBottomInset;
  final bool extendBody,
      extendBodyBehindAppBar,
      drawerEnableOpenDragGesture,
      endDrawerEnableOpenDragGesture,
      primary;
  final ValueChanged<bool>? onDrawerChanged, onEndDrawerChanged;
  final List<Widget>? persistentFooterButtons;
  final String? restorationId;
  @override
  State<ScrollAwareScaffold> createState() => _ScrollAwareScaffoldState();
}

class _ScrollAwareScaffoldState extends State<ScrollAwareScaffold> {
  final nestedKey = GlobalKey<NestedScrollViewState>();
  bool get contentOverflows {
    final state = nestedKey.currentState;
    if (state == null) return false;
    if (state.outerController.hasClients && state.outerController.offset > 0)
      return true;
    return state.innerController.positions.any(
      (p) => p.hasContentDimensions && p.maxScrollExtent > p.minScrollExtent,
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    key: widget.scaffoldKey,
    appBar: widget.pinTopBar ? widget.appBar : null,
    body: widget.appBar == null || widget.pinTopBar
        ? widget.body
        : SafeArea(
            bottom: false,
            child: NestedScrollView(
              key: nestedKey,
              physics: _ContentDrivenHeaderPhysics(
                canScroll: () => contentOverflows,
              ),
              headerSliverBuilder: (context, innerScrolled) => [
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: widget.appBar!.preferredSize.height,
                    child: MediaQuery.removePadding(
                      context: context,
                      removeTop: true,
                      child: widget.appBar!,
                    ),
                  ),
                ),
              ],
              body: widget.body ?? const SizedBox.shrink(),
            ),
          ),
    drawer: widget.drawer,
    endDrawer: widget.endDrawer,
    bottomNavigationBar: widget.bottomNavigationBar,
    floatingActionButton: widget.floatingActionButton,
    floatingActionButtonLocation: widget.floatingActionButtonLocation,
    backgroundColor: widget.backgroundColor,
    resizeToAvoidBottomInset: widget.resizeToAvoidBottomInset,
    extendBody: widget.extendBody,
    extendBodyBehindAppBar: widget.extendBodyBehindAppBar,
    drawerEnableOpenDragGesture: widget.drawerEnableOpenDragGesture,
    endDrawerEnableOpenDragGesture: widget.endDrawerEnableOpenDragGesture,
    onDrawerChanged: widget.onDrawerChanged,
    onEndDrawerChanged: widget.onEndDrawerChanged,
    bottomSheet: widget.bottomSheet,
    persistentFooterButtons: widget.persistentFooterButtons,
    drawerScrimColor: widget.drawerScrimColor,
    primary: widget.primary,
    restorationId: widget.restorationId,
  );
}

/// The header alone must never make a short page draggable. NestedScrollView
/// enables dragging when its inner content actually has a scroll extent.
class _ContentDrivenHeaderPhysics extends ClampingScrollPhysics {
  const _ContentDrivenHeaderPhysics({required this.canScroll, super.parent});
  final bool Function() canScroll;
  @override
  _ContentDrivenHeaderPhysics applyTo(ScrollPhysics? ancestor) =>
      _ContentDrivenHeaderPhysics(
        canScroll: canScroll,
        parent: buildParent(ancestor),
      );
  @override
  bool shouldAcceptUserOffset(ScrollMetrics position) => canScroll();
  @override
  double applyBoundaryConditions(ScrollMetrics position, double value) =>
      canScroll()
      ? super.applyBoundaryConditions(position, value)
      : value - position.pixels;
}
