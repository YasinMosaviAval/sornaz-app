import 'dart:io'; 
import 'package:flutter/material.dart'; 
import 'package:provider/provider.dart'; 
import 'package:sornaz/components/no_file_found.dart'; 
import 'package:sornaz/helpers/app_colors.dart';
import 'package:sornaz/helpers/app_constants.dart'; 
import 'package:sornaz/helpers/app_data.dart'; 
import 'package:sornaz/helpers/app_spacing.dart'; 
import 'package:sornaz/helpers/app_translations.dart'; 
import 'package:sornaz/helpers/app_typography.dart';
import 'package:sornaz/helpers/app_functions.dart'; 
import 'package:sornaz/helpers/app_strings.dart'; 
import 'package:sornaz/screens/Voice%20Recorder/provider/voice_recorder_provider.dart';

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
            foregroundColor: AppColors.voice_recorder_recordings_list_page_app_bar_foreground_color(isDark: isDark),
            backgroundColor: AppColors.voice_recorder_recordings_list_page_app_bar_background_color(isDark: isDark),
            title: _isSelectionMode
              ? Text('${_selectedFiles.length} ${AppStrings.recording_list_multi_item_selected.translate(context)}')
              : _isSearching ? TextField(
                autofocus: true,
                decoration: InputDecoration(
                  hintText: AppStrings.recording_list_search_hint.translate(context),
                  border: InputBorder.none,
                ),
                onChanged: (value) {
                  setState(() => _query = value.toLowerCase());
                },
              ) 
              : Text(
                AppStrings.recording_list_title.translate(context),
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
          backgroundColor: AppColors.voice_recorder_recordings_list_page_background_color(isDark: isDark),
          body: files.isEmpty 
            ? NoFilesFoundWidget(message: AppStrings.no_records_file.translate(context)) 
            : ListView.builder(
              itemCount: files.length,
              itemBuilder: (context, index) {
                final File file = files[index];
                final fileName = file.path.split('/').last.replaceAll(AppConstants.DOT_M4A, '');
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
                      ? AppColors.voice_recorder_recordings_list_page_selected_file_card_color(isDark: isDark)
                      : AppColors.voice_recorder_recordings_list_page_not_selected_file_card_color(isDark: isDark),
                    shape: Border(
                      bottom: BorderSide(
                        width: AppSpacing.space_1,
                        color: AppColors.voice_recorder_recordings_list_page_card_border_color(isDark: isDark),
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
                            color: AppColors.voice_recorder_recordings_list_page_card_leading_icon_color(isDark: isDark),
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
                                case AppConstants.SHARE:
                                  // share logic
                                  break;
                                case AppConstants.FAVORITE:
                                  // favorite logic 
                                  break; 
                                case AppConstants.EDIT:
                                  _renameRecording(context, file, isDark);
                                break;
                                case AppConstants.DELETE:
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
                                // value: 'share',
                                value: AppConstants.SHARE,
                                child: ListTile(
                                  leading: Icon(
                                    Icons.share,
                                    color: AppColors.voice_recorder_recordings_list_page_card_trailing_icons_color(isDark: isDark),
                                  ),
                                  title: Text(AppStrings.recording_list_share.translate(context)),
                                ),
                              ),
                              PopupMenuItem(
                                padding: EdgeInsets.symmetric(horizontal: AppSpacing.space_4),
                                value: AppConstants.FAVORITE,
                                // value: 'favorite',
                                child: ListTile(
                                  leading: Icon(
                                    Icons.favorite_border,
                                    color: AppColors.voice_recorder_recordings_list_page_card_trailing_icons_color(isDark: isDark),
                                  ),
                                  title: Text(AppStrings.recording_list_favorite.translate(context))
                                ),
                              ),
                              if (!_isSelectionMode)
                                PopupMenuItem(
                                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.space_4),
                                  value: AppConstants.EDIT,
                                  // value: 'edit',
                                  child: ListTile(
                                    leading: Icon(
                                      Icons.edit,
                                      color: AppColors.voice_recorder_recordings_list_page_card_trailing_icons_color(isDark: isDark),
                                    ),
                                    title: Text(AppStrings.recording_list_rename.translate(context)),
                                  ),
                                ),
                              PopupMenuItem(
                                padding: EdgeInsets.symmetric(horizontal: AppSpacing.space_4),
                                value: AppConstants.DELETE,
                                // value: 'delete',
                                child: ListTile(
                                  leading: Icon(
                                    Icons.delete,
                                    color: AppColors.voice_recorder_recordings_list_page_card_trailing_icons_color(isDark: isDark),
                                  ),
                                  title: Text(AppStrings.recording_list_delete.translate(context)),
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
        backgroundColor: AppColors.voice_recorder_recordings_list_page_dialog_background_color(isDark: isDark),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        title: Text(
          AppStrings.voice_recorder_delete_recording.translate(context),
          textAlign: TextAlign.center,
        ),
        content: Text(
          '${_selectedFiles.length} ${AppStrings.recording_list_multi_item_delete_content.translate(context)}',
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
              style: AppTypography.voiceRecorderConfirmDelete(context, isDark),
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
        color: AppColors.voice_recorder_recordings_list_page_selection_bottom_bar_background_color(isDark: isDark),
        border: Border(
          top: BorderSide(
            color: AppColors.voice_recorder_recordings_list_page_selection_bottom_bar_border_color(isDark: isDark),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$selectedCount ${AppStrings.recording_list_multi_item_selected.translate(context)}',
            style: AppTypography.recordingListMultiItemSelected(context),
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
                icon: Icon(Icons.delete, color: AppColors.voice_recorder_recordings_list_page_selection_bottom_bar_delete_icon_color(isDark: isDark)),
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
  final oldName = file.path.split('/').last.replaceAll(AppConstants.DOT_M4A, '');
  final controller = TextEditingController(text: oldName);
  final newName = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: AppColors.voice_recorder_recordings_list_page_dialog_background_color(isDark: isDark),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      actionsPadding: EdgeInsets.all(AppSpacing.space_0),
      contentPadding: EdgeInsets.all(AppSpacing.space_24),
      title: Text(
        AppStrings.voice_recorder_rename_file.translate(context),
        textAlign: TextAlign.center
      ),
      titleTextStyle: AppTypography.recordingListDialogTitle(context),
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
            style: AppTypography.recordingListDiscardDialog(context)
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
            style: AppTypography.recordingsListRenameSaveText(context, isDark)
          ),
        ),
      ],
    ),
  );
  if (newName == null || newName.isEmpty || newName == oldName) return; 
  final newPath = file.path.replaceFirst(
    '$oldName${AppConstants.DOT_M4A}',
    '$newName${AppConstants.DOT_M4A}'
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
  final fileName = file.path.split('/').last.replaceAll(AppConstants.DOT_M4A, '');
  final confirm = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: AppColors.voice_recorder_recordings_list_page_dialog_background_color(isDark: isDark),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      actionsPadding: EdgeInsets.all(AppSpacing.space_0),
      contentPadding: EdgeInsets.all(AppSpacing.space_24),
      title: Text(
        AppStrings.voice_recorder_delete_recording.translate(context),
        textAlign: TextAlign.center
      ),
      titleTextStyle: AppTypography.recordingListDialogTitle(context),
      content: Text(
        "$fileName ${AppStrings.recording_list_delete_content.translate(context)}",
        textAlign: TextAlign.center
      ),
      contentTextStyle: AppTypography.recordingListDialogContent(context),
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
            style: AppTypography.recordingListDiscardDialog(context)
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
            style: AppTypography.voiceRecorderConfirmDelete(context, isDark)
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