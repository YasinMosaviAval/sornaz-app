import 'package:flutter/material.dart';

class PanelListItem extends StatelessWidget {
  const PanelListItem({super.key, required this.child, this.color});
  final Widget child;
  final Color? color;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      ColoredBox(color: color ?? Colors.transparent, child: child),
      Divider(
        height: .2,
        thickness: .2,
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .04),
      ),
    ],
  );
}
