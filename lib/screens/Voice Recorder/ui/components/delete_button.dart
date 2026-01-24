// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:sornaz/helpers/app_colors.dart';
import 'package:sornaz/helpers/app_strings.dart';
import 'package:sornaz/helpers/app_translations.dart';
import 'package:sornaz/helpers/app_typography.dart';
import 'package:sornaz/helpers/app_constants.dart';

class DeleteButtonWidget extends StatelessWidget {
  const DeleteButtonWidget({
    super.key,
    required this.onDelete,
    required this.file,
    required this.onUndoRestore,
    required this.isDark
  });

  final Function() onDelete;
  final File file;
  final bool isDark;
  final Future<void> Function(File restoredFile, List<int> bytes) onUndoRestore;

  @override
  Widget build(BuildContext context) {
    final fileName = file.path.split('/').last;
    return Expanded(
      child: ElevatedButton.icon(
        icon: Icon(Icons.delete_forever, color: AppColors.voice_recorder_delete_button_icon_color(isDark: isDark)),
        style: ElevatedButton.styleFrom(backgroundColor: AppColors.voice_recorder_delete_button_icon_style_color(isDark: isDark)),
        label: Text(
          AppStrings.delete_button_widget_delete.translate(context),
          style: AppTypography.recordDetailsDeleteDialogueLabel(context),
        ),
        onPressed: () async {
          final confirm = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(
                AppStrings.delete_button_widget_confirm_delete.translate(context),
                style: AppTypography.recordDetailsDeleteDialogueTitle(context),
              ),
              content: Text("""${AppStrings.delete_button_widget_delete_question_before_filename_part.translate(context)}$fileName${AppStrings.delete_button_widget_delete_question_after_filename_part.translate(context)}""",
                style: AppTypography.recordDetailsDeleteDialogueContent(context),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(
                    AppStrings.delete_button_widget_discard_button.translate(context),
                    style: AppTypography.recordDetailsDeleteDialogueCancelButton(context)
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.voice_recorder_delete_button_icon_style_color(isDark: isDark)),
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(
                    AppStrings.delete_button_widget_confirm_delete_button.translate(context),
                    style: AppTypography.recordDetailsDeleteDialogueConfirmButton(context)
                  ),
                ),
              ],
            ),
          );

          if (confirm == true) {
            final bytes = await file.readAsBytes();
            final originalPath = file.path;

            await onDelete();

            Navigator.pop(context, {
              AppConstants.DELETED: true,
              AppConstants.BYTES: bytes,
              AppConstants.PATH: originalPath,
            });
          }
        },
      ),
    );
  }
}



