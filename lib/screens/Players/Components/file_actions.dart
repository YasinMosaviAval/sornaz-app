import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sornaz/audio/scan/audio_file.dart';
import 'package:sornaz/audio/audio_player_provider.dart';
import 'package:sornaz/helpers/app_strings.dart';
import 'package:sornaz/helpers/app_translations.dart';


void showFileOptions(BuildContext context, AudioFile file) {
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (sheetCtx) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.edit),
            title: Text(AppStrings.file_action_change_filename.translate(context)),
            onTap: () {
              Navigator.pop(sheetCtx);
              showRenameDialog(context, file);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete),
            title: Text(AppStrings.file_action_remove.translate(context)),
            onTap: () {
              Navigator.pop(sheetCtx);
              showDeleteConfirm(context, file);
            },
          ),
        ],
      );
    },
  );
}


void showRenameDialog(BuildContext context, AudioFile file) {
  final controller = TextEditingController(
    text: file.fileName.split('.').first,
  );

  showDialog(
    context: context,
    builder: (dialogCtx) {
      return AlertDialog(
        title: Text(AppStrings.file_action_change_filename.translate(context)),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(hintText: AppStrings.file_action_new_filename.translate(context)),
        ),
        actions: [
          TextButton(
            child: Text(AppStrings.file_action_discard.translate(context)),
            onPressed: () => Navigator.pop(dialogCtx),
          ),
          TextButton(
            child: Text(AppStrings.file_action_save.translate(context)),
            onPressed: () {
              final newName = controller.text.trim();
              if (newName.isEmpty) return;
              final provider = Provider.of<AudioPlayerProvider>(context, listen: false);
              Navigator.pop(dialogCtx);

              Future.microtask(() async {
                if (!context.mounted) return;
                final success = await provider.renameFile(
                  file,
                  "$newName.${file.fileName.split('.').last}",
                  AppStrings.audio_player_provider_changed_filename.translate(context)
                );

                if (!context.mounted) return;

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? AppStrings.file_action_changed_filename.translate(context)
                          : AppStrings.file_action_error_in_changed_filename.translate(context),
                    ),
                  ),
                );
              });
            },
          ),
        ],
      );
    },
  );
}


void showDeleteConfirm(BuildContext context, AudioFile file) {
  showDialog(
    context: context,
    builder: (dialogCtx) {
      return AlertDialog(
        title: Text(AppStrings.file_action_remove_file.translate(context)),
        content: Text(AppStrings.file_action_remove_file_from_list_or_memory.translate(context)),
        actions: [

          TextButton(
            child: Text(AppStrings.file_action_discard.translate(context)),
            onPressed: () => Navigator.pop(dialogCtx),
          ),

          TextButton(
            child: Text(AppStrings.file_action_remove_file_from_list.translate(context)),
            onPressed: () {
              Navigator.pop(dialogCtx);

              final provider = Provider.of<AudioPlayerProvider>(context, listen: false);
              final removed = provider.removeFromList(file, AppStrings.audio_player_provider_remove_from_list.translate(context));

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        removed ? AppStrings.file_action_removed_file_from_list.translate(context) : AppStrings.file_action_error_in_removed_file_from_list.translate(context)),
                  ),
                );
              }
            },
          ),

          TextButton(
            child: Text(AppStrings.file_action_delete_file_from_memory.translate(context)),
            onPressed: () {
              final provider = Provider.of<AudioPlayerProvider>(context, listen: false);

              Navigator.pop(dialogCtx);

              Future.microtask(() async {
                if (!context.mounted) return;
                final success = await provider.deleteFromDevice(file, AppStrings.audio_player_provider_delete_from_memory.translate(context));
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        success ? AppStrings.file_action_deleted_file_from_memory.translate(context) : AppStrings.file_action_error_in_deleted_file_from_memory.translate(context)),
                  ),
                );
              });
            },
          ),
        ],
      );
    },
  );
}
