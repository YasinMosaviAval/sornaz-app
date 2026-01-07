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

/*
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
*/



import 'dart:io'; 
import 'package:flutter/material.dart'; 
import 'package:provider/provider.dart'; 
import 'package:sornaz/components/no_file_found.dart'; 
import 'package:sornaz/helpers/app_colors.dart'; 
import 'package:sornaz/helpers/app_data.dart'; 
import 'package:sornaz/helpers/app_spacing.dart'; 
import 'package:sornaz/helpers/app_translations.dart'; 
import 'package:sornaz/helpers/app_typography.dart';
import 'package:sornaz/helpers/app_functions.dart'; 
import 'package:sornaz/helpers/app_strings.dart'; 
import 'package:sornaz/screens/Voice%20Recorder/voice_recorder/provider/voice_recorder_provider.dart';

class RecordedFilesPage extends StatefulWidget {
  const RecordedFilesPage({super.key});

  @override State<RecordedFilesPage> createState() => _RecordedFilesPageState(); 
} 

class _RecordedFilesPageState extends State<RecordedFilesPage> {
  bool _isSearching = false;
  String _query = ''; 
  
  final Set<File> _selectedFiles = {};
  
  bool get _isSelectionMode => _selectedFiles.isNotEmpty;

  @override Widget build(BuildContext context) {
    final appData = context.watch<AppData>(); 
    final isDark = appData.isDark;

    return Consumer<VoiceRecorderProvider>( builder: (context, vm, _) {
      final files = vm.files.where((file) {
        final name = file.path.split('/').last.toLowerCase();
        return name.contains(_query);
      }).toList();
      return PopScope(
        canPop: !_isSelectionMode,
        onPopInvoked: (didPop) {
          if (_isSelectionMode) {
            setState(() {
              _selectedFiles.clear();
            });
          }
        },
        child: Scaffold(
          appBar: AppBar(
            foregroundColor: isDark ? AppColors.text_primary_dark : AppColors.text_primary_light,
            backgroundColor: isDark ? AppColors.surface_dark : AppColors.surface_light, 
            title: _isSelectionMode
              ? Text('${_selectedFiles.length} selected')
              : _isSearching ? TextField(
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search recordings...',
                  border: InputBorder.none,
                ),
                onChanged: (value) {
                  setState(() => _query = value.toLowerCase());
                },
              ) 
              : Text(
                "Recordings List",
                style: AppTypography.RecordingsListAppBarTitle(context),
              ), 
            actions: [
              IconButton(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.space_16),
                icon: Icon(_isSearching ? Icons.close : Icons.search),
                onPressed: () {
                  setState(() {
                    _isSearching = !_isSearching;
                    _query = '';
                  });
                },
              ),
            ],
          ),
          backgroundColor: isDark ? AppColors.surface_dark : AppColors.surface_light,
          body: files.isEmpty 
            ? NoFilesFoundWidget(message: AppStrings.no_records_file.translate(context)) 
            : ListView.builder(
              itemCount: files.length,
              itemBuilder: (context, index) {
                final File file = files[index];
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
                    margin: EdgeInsets.zero,
                    color: _selectedFiles.contains(file)
                      ? (isDark ? AppColors.primary_dark.withAlpha(20) : AppColors.primary_light.withAlpha(20))
                      : (isDark ? AppColors.background_dark.withAlpha(200) : AppColors.background_light.withAlpha(200)),
                    shape: Border(
                      bottom: BorderSide(
                        width: AppSpacing.space_1,
                        color: isDark ? AppColors.surface_dark : AppColors.surface_light,
                      ),
                    ),
                    child: InkWell(
                      onLongPress: () {
                        setState(() {
                          _selectedFiles.add(file);
                        });
                      },
                      onTap: () {
                        if (_isSelectionMode) {
                          setState(() {
                            _selectedFiles.contains(file)
                                ? _selectedFiles.remove(file)
                                : _selectedFiles.add(file);
                          });
                        }
                      },
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.space_16),
                        leading: IconButton(
                          iconSize: AppSpacing.space_32,
                          icon: Icon(
                            Icons.play_arrow_rounded,
                            color: isDark ? AppColors.text_primary_dark : AppColors.text_primary_light,
                          ),
                          onPressed: () {
                            // playback (UI-only مثل قبل) 
                          },
                        ),
                        title: Text(
                          fileName,
                          style: AppTypography.voiceRecorderFilename(context),
                        ),
                        subtitle: Text(
                          date,
                          style: AppTypography.voiceRecorderDate(context),
                        ),
                        trailing: _isSelectionMode
                          ? null
                          : PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert),
                            onSelected: (value) async {
                              switch (value) {
                                case 'share': 
                                  // share logic
                                  break;
                                case 'favorite':
                                  // favorite logic 
                                  break; 
                                case 'edit':
                                  _renameRecording(context, file, isDark);
                                break;
                                case 'delete':
                                  if (_isSelectionMode) {
                                    for (final f in _selectedFiles) {
                                      await f.delete();
                                    }
                                    _selectedFiles.clear();
                                    await vm.init();
                                    setState(() {});
                                  } else {
                                    _confirmDelete(context, file, isDark, vm);
                                  }
                                  break;
                              }
                            },
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                padding: EdgeInsets.symmetric(horizontal: AppSpacing.space_4),
                                value: 'share',
                                child: ListTile(
                                  leading: Icon(
                                    Icons.share,
                                    color: isDark ? AppColors.text_primary_dark : AppColors.text_primary_light,
                                  ),
                                  title: Text('Share'),
                                ),
                              ),
                              PopupMenuItem(
                                padding: EdgeInsets.symmetric(horizontal: AppSpacing.space_4),
                                value: 'favorite',
                                child: ListTile(
                                  leading: Icon(
                                    Icons.favorite_border,
                                    color: isDark ? AppColors.text_primary_dark : AppColors.text_primary_light,
                                  ),
                                  title: Text('Favorite')
                                ),
                              ),
                              if (!_isSelectionMode)
                                PopupMenuItem(
                                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.space_4),
                                  value: 'edit',
                                  child: ListTile(
                                    leading: Icon(
                                      Icons.edit,
                                      color: isDark ? AppColors.text_primary_dark : AppColors.text_primary_light,
                                    ),
                                    title: Text('Rename'),
                                  ),
                                ),
                              PopupMenuItem(
                                padding: EdgeInsets.symmetric(horizontal: AppSpacing.space_4),
                                value: 'delete',
                                child: ListTile(
                                  leading: Icon(
                                    Icons.delete,
                                    color: isDark ? AppColors.text_primary_dark : AppColors.text_primary_light,
                                  ),
                                  title: Text('Delete'),
                                ),
                              ),
                            ],
                          ),
                      ),
                    ),
                  ),
                );
              },
            ),
            bottomNavigationBar: AnimatedSlide(
              offset: _isSelectionMode ? Offset.zero : const Offset(0, 1),
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              child: AnimatedOpacity(
                opacity: _isSelectionMode ? 1 : 0,
                duration: const Duration(milliseconds: 200),
                child: SafeArea(
                  child: _SelectionBottomBar(
                    selectedCount: _selectedFiles.length,
                    onDelete: _deleteSelected,
                    onShare: _shareSelected,
                    onFavorite: _favoriteSelected,
                  ),
                ),
              ),
            ),
          ),
      );
      },
    );
  }


  Future<void> _deleteSelected() async {
  final isDark = context.read<AppData>().isDark;

  final confirm = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: isDark ? AppColors.surface_dark : AppColors.surface_light,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      title: Text(
        AppStrings.voice_recorder_delete_recording.translate(context),
        textAlign: TextAlign.center,
      ),
      content: Text(
        '${_selectedFiles.length} فایل حذف شود؟',
        textAlign: TextAlign.center,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(AppStrings.voice_recorder_no.translate(context)),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(
            AppStrings.voice_recorder_yes_delete.translate(context),
            style: const TextStyle(color: AppColors.error),
          ),
        ),
      ],
    ),
  );

  if (confirm != true || !mounted) return;

  for (final file in _selectedFiles) {
    await file.delete();
  }

  _selectedFiles.clear();
  context.read<VoiceRecorderProvider>().init();
  setState(() {});
}


  void _shareSelected() {
    // اتصال به share_plus یا منطق فعلی خودت
    _selectedFiles.clear();
    setState(() {});
  }


  void _favoriteSelected() {
    // اگر favorite واقعی داری، اینجا وصلش کن
    _selectedFiles.clear();
    setState(() {});
  }

}


class _SelectionBottomBar extends StatelessWidget {
  final int selectedCount;
  final VoidCallback onDelete;
  final VoidCallback onShare;
  final VoidCallback onFavorite;

  const _SelectionBottomBar({
    required this.selectedCount,
    required this.onDelete,
    required this.onShare,
    required this.onFavorite,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: kBottomNavigationBarHeight,
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.space_16),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.surface_dark
            : AppColors.surface_light,
        border: Border(
          top: BorderSide(
            color: isDark
                ? AppColors.surface_dark
                : AppColors.surface_light,
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$selectedCount selected',
            style: AppTypography.body2(context),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.share),
                onPressed: onShare,
              ),
              IconButton(
                icon: const Icon(Icons.favorite),
                onPressed: onFavorite,
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: AppColors.error),
                onPressed: onDelete,
              ),
            ],
          ),
        ],
      ),
    );
  }
}



// ------------------------------------------------------------ 
// 📝 Rename Recording 
// ------------------------------------------------------------ 
Future<void> _renameRecording(
  BuildContext context,
  File file,
  bool isDark,
) async {
  final oldName = file.path.split('/').last.replaceAll(AppStrings.file_type_dot_m4a, '');
  final controller = TextEditingController(text: oldName);
  final newName = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: isDark ? AppColors.surface_dark : AppColors.surface_light,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      actionsPadding: EdgeInsets.all(AppSpacing.space_0),
      contentPadding: EdgeInsets.all(AppSpacing.space_24),
      title: Text(
        AppStrings.voice_recorder_rename_file.translate(context),
        textAlign: TextAlign.center
      ),
      titleTextStyle: AppTypography.headline3(context),
      content: TextField(
        controller: controller,
        autofocus: true,
        decoration: InputDecoration(
          hintText: AppStrings.voice_recorder_rename_file.translate(context),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          style: TextButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.space_4),
            ),
          ),
          child: Text(
            AppStrings.voice_recorder_discard.translate(context),
            style: AppTypography.subtitle3(context)
          ),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, controller.text.trim()),
          style: TextButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.space_4),
            ),
          ),
          child: Text(
            AppStrings.voice_recorder_save.translate(context),
            style: AppTypography.body2(context).copyWith(
              color: isDark ? AppColors.primary_dark : AppColors.primary_light,
              fontWeight: FontWeight.w600
            )
          ),
        ),
      ],
    ),
  );
  if (newName == null || newName.isEmpty || newName == oldName) return; 
  final newPath = file.path.replaceFirst(
    '$oldName${AppStrings.file_type_dot_m4a}',
    '$newName${AppStrings.file_type_dot_m4a}'
  );
  await file.rename(newPath);
  if (!context.mounted) return;
  context.read<VoiceRecorderProvider>().init();
}



// ------------------------------------------------------------ 
// ❌ Confirm Delete 
// ------------------------------------------------------------ 
Future<void> _confirmDelete(
  BuildContext context,
  File file,
  bool isDark,
  VoiceRecorderProvider vm
) async {
  final fileName = file.path.split('/').last.replaceAll(AppStrings.file_type_dot_m4a, '');
  final confirm = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: isDark ? AppColors.surface_dark : AppColors.surface_light,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      actionsPadding: EdgeInsets.all(AppSpacing.space_0),
      contentPadding: EdgeInsets.all(AppSpacing.space_24),
      title: Text(
        AppStrings.voice_recorder_delete_recording.translate(context),
        textAlign: TextAlign.center
      ),
      titleTextStyle: AppTypography.headline3(context),
      content: Text(
        "$fileName حذف شود؟",
        textAlign: TextAlign.center
      ),
      contentTextStyle: AppTypography.body1(context),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          style: TextButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.space_4),
            ),
          ),
          child: Text(
            AppStrings.voice_recorder_no.translate(context),
            style: AppTypography.subtitle3(context)
          ),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          style: TextButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.space_4),
            ),
          ),
          child: Text(
            AppStrings.voice_recorder_yes_delete.translate(context),
            style: AppTypography.body2(context).copyWith(
              color: AppColors.error,
              fontWeight: FontWeight.w600
            )
          ),
        ),
      ],
    ),
  );
  if (confirm == true) {
    await file.delete();
    await vm.init();
  }
}