import 'package:sornaz/components/app_dialog.dart';
import 'package:flutter/material.dart';
import 'package:sornaz/helpers/app_strings.dart';
import 'package:sornaz/helpers/app_translations.dart';

Future<bool?> showDeleteConfirmDialog(BuildContext context, String fileName) {
  return showDeleteConfirmation(
    context,
    title: AppStrings.delete_confirm_dialog_title.translate(context),
    message:
        '${AppStrings.delete_confirm_dialog_content_before_filename.translate(context)} "$fileName"${AppStrings.delete_confirm_dialog_content_after_filename.translate(context)}',
  );
}
