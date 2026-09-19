import 'package:flutter/material.dart';

/// Reverse toolbar chrome while keeping page content in its own direction.
class AppTopBarDirection extends StatelessWidget
    implements PreferredSizeWidget {
  const AppTopBarDirection({super.key, required this.child});
  final PreferredSizeWidget child;
  @override
  Size get preferredSize => child.preferredSize;
  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: Localizations.localeOf(context).languageCode == 'fa'
        ? TextDirection.ltr
        : TextDirection.rtl,
    child: child,
  );
}
