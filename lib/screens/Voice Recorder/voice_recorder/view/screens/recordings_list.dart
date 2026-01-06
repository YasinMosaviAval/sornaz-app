/*
import 'dart:io';
import 'package:flutter/material.dart';
import 'record_item_tile.dart';

class RecordingsList extends StatelessWidget {
  final List<File> files;
  final void Function(File) onPlay;
  final void Function(File) onDelete;

  const RecordingsList({
    super.key,
    required this.files,
    required this.onPlay,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (files.isEmpty) {
      return const Center(child: Text('No recordings'));
    }

    return ListView.builder(
      itemCount: files.length,
      itemBuilder: (_, i) {
        final file = files[i];
        return RecordItemTile(
          file: file,
          onPlay: () => onPlay(file),
          onDelete: () => onDelete(file),
        );
      },
    );
  }
}
*/


// recorded_files_page.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sornaz/components/no_file_found.dart';
import 'package:sornaz/helpers/app_colors.dart';
import 'package:sornaz/helpers/app_data.dart';
import 'package:sornaz/helpers/app_functions.dart';
import 'package:sornaz/helpers/app_spacing.dart';
import 'package:sornaz/helpers/app_strings.dart';
import 'package:sornaz/helpers/app_translations.dart';
import 'package:sornaz/helpers/app_typography.dart';
import 'package:sornaz/screens/Voice%20Recorder/voice_recorder/provider/voice_recorder_provider.dart';

class RecordedFilesPage extends StatelessWidget {
  const RecordedFilesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final appData = context.watch<AppData>();
    final isDark = appData.isDark;

    return Consumer<VoiceRecorderProvider>(
      builder: (context, vm, _) {
        return Scaffold(
          appBar: AppBar(
            title: Text(
              "Recordings List",
              // AppStrings.voice_recorder_recording_list_title.translate(context),
              style: AppTypography.RecordingsListAppBarTitle(context),
            ),
            foregroundColor: isDark ? AppColors.text_primary_dark : AppColors.text_primary_light,
            backgroundColor: isDark ? AppColors.surface_dark : AppColors.surface_light,
          ),
          backgroundColor: isDark ? AppColors.surface_dark : AppColors.surface_light,
          body: vm.files.isEmpty
              ? NoFilesFoundWidget(message: AppStrings.no_records_file.translate(context))
              : ListView.builder(
                  // padding: const EdgeInsets.all(12),
                  itemCount: vm.files.length,
                  itemBuilder: (context, index) {
                    final file = vm.files[index];
                    final fileName = file.path.split('/').last.replaceAll(AppStrings.file_type_dot_m4a, '');
                    final date = formatJalali(file.lastModifiedSync());

                    return AnimatedSwitcher(
                      duration: const Duration(milliseconds: 350),
                      transitionBuilder: (child, animation) => SizeTransition(
                        sizeFactor: animation,
                        child: child,
                      ),
                      child: Card(
                        key: ValueKey(file.path),
                        elevation: 0,
                        color: isDark ? AppColors.background_dark.withAlpha(200) : AppColors.background_light.withAlpha(200),
                        margin: EdgeInsets.all(0),
                        shape: Border(
                          bottom: BorderSide(
                            width: AppSpacing.space_1,
                            color: isDark ? AppColors.surface_dark : AppColors.surface_light,
                          )
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.space_16),
                          leading: IconButton(
                            iconSize: AppSpacing.space_32,
                            icon: Icon(
                              Icons.play_arrow_rounded,
                              color: isDark ? AppColors.text_primary_dark : AppColors.text_primary_light,
                            ),
                            onPressed: () {
                              // playback UI-only (مثل قبل)
                            },
                          ),
                          title: Text(fileName, style: AppTypography.voiceRecorderFilename(context)),
                          subtitle: Text(date, style: AppTypography.voiceRecorderDate(context)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                iconSize: AppSpacing.space_24,
                                icon: const Icon(Icons.edit, color: AppColors.info),
                                onPressed: () => _renameRecording(context, file, isDark),
                              ),
                              IconButton(
                                iconSize: AppSpacing.space_24,
                                icon: const Icon(Icons.delete_forever, color: AppColors.error),
                                onPressed: () => _confirmDelete(context, file, isDark, vm),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        );
      },
    );
  }

  // ------------------------------------------------------------
  // 📝 Rename Recording
  // ------------------------------------------------------------
  Future<void> _renameRecording(
    BuildContext context,
    File file,
    bool isDark,
  ) async {
    final oldName = file.path
        .split('/')
        .last
        .replaceAll(AppStrings.file_type_dot_m4a, '');

    final controller = TextEditingController(text: oldName);

    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor:
            isDark ? AppColors.surface_dark : AppColors.surface_light,
        title: Text(
          AppStrings.voice_recorder_rename_file.translate(context),
          textAlign: TextAlign.center,
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: AppStrings
                .voice_recorder_rename_file
                .translate(context),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppStrings.voice_recorder_discard.translate(context)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: Text(AppStrings.voice_recorder_save.translate(context)),
          ),
        ],
      ),
    );

    if (newName == null || newName.isEmpty || newName == oldName) return;

    final newPath = file.path.replaceFirst(
      '$oldName${AppStrings.file_type_dot_m4a}',
      '$newName${AppStrings.file_type_dot_m4a}',
    );

    await file.rename(newPath);
    context.read<VoiceRecorderProvider>().init();
  }

  // ------------------------------------------------------------
  // ❌ Confirm Delete
  // ------------------------------------------------------------
  Future<void> _confirmDelete(
    BuildContext context,
    File file,
    bool isDark,
    VoiceRecorderProvider vm,
  ) async {
    final fileName = file.path
        .split('/')
        .last
        .replaceAll(AppStrings.file_type_dot_m4a, '');

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor:
            isDark ? AppColors.surface_dark : AppColors.surface_light,
        title: Text(
          AppStrings.voice_recorder_delete_recording
              .translate(context),
          textAlign: TextAlign.center,
        ),
        content: Text(
          "$fileName حذف شود؟",
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppStrings.voice_recorder_no
                .translate(context)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(AppStrings.voice_recorder_yes_delete
                .translate(context)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await file.delete();
      await vm.init();
    }
  }
}
