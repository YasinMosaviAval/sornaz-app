// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:sornaz/helpers/app_colors.dart';
import 'package:sornaz/helpers/app_strings.dart';
import 'package:sornaz/helpers/app_translations.dart';
import 'package:sornaz/helpers/app_typography.dart';

class RenameButtonWidget extends StatelessWidget {
  const RenameButtonWidget({
    super.key,
    required this.controller,
    required this.onRename,
    required this.isDark,
  });

  final TextEditingController controller;
  final Function(String) onRename;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ElevatedButton.icon(
        icon: Icon(Icons.edit, color: AppColors.voice_recorder_rename_button_icon_color(isDark: isDark)),
        style: ElevatedButton.styleFrom(backgroundColor: AppColors.voice_recorder_rename_button_icon_style_color(isDark: isDark)),
        label: Text(
          AppStrings.rename_button_widget_rename.translate(context),
          style: AppTypography.recordDetailsRenameTitle(context),
        ),
        onPressed: () async {
          final newName = await showDialog<String>(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(
                AppStrings.rename_button_widget_rename.translate(context),
                style: AppTypography.recordDetailsRenameDialogueTitle(context),
              ),
              content: TextField(
                controller: controller,
                decoration: InputDecoration(
                  labelText: AppStrings.rename_button_widget_new_filename.translate(context),
                  border: OutlineInputBorder(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    AppStrings.rename_button_widget_discard.translate(context),
                    style: AppTypography.recordDetailsRenameDialogueCancelButton(context),
                  ),
                ),
                ElevatedButton(
                  onPressed: () =>
                      Navigator.pop(context, controller.text.trim()),
                  child: Text(
                    AppStrings.rename_button_widget_save.translate(context),
                    style: AppTypography.recordDetailsRenameDialogueConfirmButton(context)
                  ),
                ),
              ],
            ),
          );

          if (newName != null && newName.isNotEmpty) {
            onRename(newName);
            Navigator.pop(context);
          }
        },
      ),
    );
  }
}
