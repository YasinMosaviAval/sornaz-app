import 'package:flutter/material.dart';
import 'package:sornaz/helpers/app_strings.dart';
import 'package:sornaz/helpers/app_translations.dart';

Future<bool?> showDeleteConfirmDialog(
  BuildContext context,
  String fileName,
) {
  return showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(AppStrings.delete_confirm_dialog_title.translate(context)),
      content: Text('${AppStrings.delete_confirm_dialog_content_before_filename.translate(context)} "$fileName"${AppStrings.delete_confirm_dialog_content_after_filename.translate(context)}'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(AppStrings.delete_confirm_dialog_cancel_button.translate(context)),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(AppStrings.delete_confirm_dialog_delete_button.translate(context)),
        ),
      ],
    ),
  );
}
