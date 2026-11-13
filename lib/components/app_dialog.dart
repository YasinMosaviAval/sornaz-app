import 'package:flutter/material.dart';
import '../helpers/app_appearance.dart';

/// Shared typography, surface and corners for application dialogs.
class AppDialog extends StatelessWidget {
  const AppDialog({super.key, this.title, this.content, this.actions});
  final Widget? title, content;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: appRadius(context)),
      backgroundColor: theme.colorScheme.surface,
      titleTextStyle: theme.textTheme.titleMedium?.copyWith(
        fontSize: 14,
        color: theme.colorScheme.onSurface,
      ),
      contentTextStyle: theme.textTheme.bodyMedium?.copyWith(
        fontSize: 12,
        color: theme.colorScheme.onSurface,
      ),
      title: title,
      content: content,
      actions: actions,
    );
  }
}

enum AppDialogActionRole { cancel, destructive, primary }

class AppDialogAction extends StatelessWidget {
  const AppDialogAction({
    super.key,
    required this.onPressed,
    required this.child,
    this.role = AppDialogActionRole.primary,
  });
  final VoidCallback? onPressed;
  final Widget child;
  final AppDialogActionRole role;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: switch (role) {
          AppDialogActionRole.cancel => Colors.grey,
          AppDialogActionRole.destructive => Colors.red,
          AppDialogActionRole.primary => theme.colorScheme.primary,
        },
        textStyle: theme.textTheme.labelLarge?.copyWith(fontSize: 12),
        shape: RoundedRectangleBorder(borderRadius: appRadius(context)),
      ),
      child: child,
    );
  }
}

class DeleteConfirmationDialog extends StatelessWidget {
  const DeleteConfirmationDialog({
    super.key,
    required this.title,
    this.message,
    this.deleteLabel,
    this.cancelLabel,
  });
  final String title;
  final String? message, deleteLabel, cancelLabel;

  @override
  Widget build(BuildContext context) {
    final en = Localizations.localeOf(context).languageCode == 'en';
    return AppDialog(
      title: Text(title),
      content: message == null ? null : Text(message!),
      actions: [
        AppDialogAction(
          role: AppDialogActionRole.cancel,
          onPressed: () => Navigator.pop(context, false),
          child: Text(cancelLabel ?? (en ? 'Cancel' : 'انصراف')),
        ),
        AppDialogAction(
          role: AppDialogActionRole.destructive,
          onPressed: () => Navigator.pop(context, true),
          child: Text(deleteLabel ?? (en ? 'Delete' : 'حذف')),
        ),
      ],
    );
  }
}

Future<bool> showDeleteConfirmation(
  BuildContext context, {
  required String title,
  String? message,
  String? deleteLabel,
  String? cancelLabel,
}) async =>
    await showDialog<bool>(
      context: context,
      builder: (_) => DeleteConfirmationDialog(
        title: title,
        message: message,
        deleteLabel: deleteLabel,
        cancelLabel: cancelLabel,
      ),
    ) ??
    false;
