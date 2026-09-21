import 'package:flutter/material.dart';

class PlayerDialog extends StatelessWidget {
  const PlayerDialog({super.key, this.title, this.content, this.actions});
  final Widget? title, content;
  final List<Widget>? actions;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context), colors = Theme.of(context).colorScheme;
    return AlertDialog(
      backgroundColor: colors.surface,
      title: title,
      content: content,
      actions: actions,
      titleTextStyle: theme.textTheme.titleMedium?.copyWith(
        fontSize: 16,
        color: colors.onSurface,
        fontWeight: FontWeight.w500,
      ),
      contentTextStyle: theme.textTheme.bodyMedium?.copyWith(
        fontSize: 14,
        color: colors.onSurface,
      ),
    );
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
    final colors = Theme.of(context).colorScheme;
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: primary ? colors.onPrimary : colors.onSurfaceVariant,
        backgroundColor: primary ? colors.primary : Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        textStyle: const TextStyle(fontSize: 14),
      ),
      child: child,
    );
  }
}
