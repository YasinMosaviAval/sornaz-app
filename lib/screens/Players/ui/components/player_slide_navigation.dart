import 'package:flutter/material.dart';

class PlayerSlideNavigation extends InheritedWidget {
  const PlayerSlideNavigation({
    super.key,
    required this.page,
    this.count = 3,
    required this.go,
    required super.child,
  });
  final int page, count;
  final ValueChanged<int> go;
  VoidCallback? get left => page > 0 ? () => go(page - 1) : null;
  VoidCallback? get right => page < count - 1 ? () => go(page + 1) : null;
  static PlayerSlideNavigation? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<PlayerSlideNavigation>();
  @override
  bool updateShouldNotify(PlayerSlideNavigation old) => page != old.page || count != old.count;
}
