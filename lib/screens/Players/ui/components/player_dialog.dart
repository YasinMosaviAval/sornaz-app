import 'package:flutter/material.dart';
import 'package:sornaz/components/app_dialog.dart';

class PlayerDialog extends StatelessWidget {
  const PlayerDialog({super.key, this.title, this.content, this.actions});
  final Widget? title, content;
  final List<Widget>? actions;
  @override
  Widget build(BuildContext context) {
    return AppDialog(title: title, content: content, actions: actions);
  }
}

class PlayerDialogButton extends StatelessWidget {
  const PlayerDialogButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.primary = true,
  });
  final VoidCallback? onPressed;
  final Widget child;
  final bool primary;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: primary ? colors.onPrimary : colors.onSurfaceVariant,
        backgroundColor: primary ? colors.primary : Colors.transparent,
        shape: theme.cardTheme.shape as OutlinedBorder?,
        textStyle: theme.textTheme.labelLarge,
      ),
      child: child,
    );
  }
}
