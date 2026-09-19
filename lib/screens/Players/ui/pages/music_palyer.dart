import 'package:sornaz/components/scroll_aware_scaffold.dart';
import 'package:flutter/foundation.dart';
import 'browser_music_player.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:sornaz/helpers/app_constants.dart';
import 'package:sornaz/helpers/app_colors.dart';
import 'package:sornaz/helpers/app_data.dart';
import 'package:sornaz/helpers/app_functions.dart';
import 'package:sornaz/helpers/app_locale_provider.dart';
import 'package:sornaz/helpers/app_typography.dart';
import 'package:sornaz/helpers/app_spacing.dart';

import 'package:sornaz/helpers/app_strings.dart';
import 'package:sornaz/helpers/app_translations.dart';
import 'package:sornaz/screens/Players/library/audio_library_manager.dart';
import 'package:sornaz/screens/Players/providers/folder_navigator_provider.dart';
import 'package:sornaz/screens/Players/ui/pages/music_player_tabs.dart';

class MusicPlayerPage extends StatefulWidget {
  const MusicPlayerPage({super.key});

  @override
  State<MusicPlayerPage> createState() => _MusicPlayerPageState();
}

class _MusicPlayerPageState extends State<MusicPlayerPage> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestPermissionsAndScan();
    });
  }

  Future<void> _requestPermissionsAndScan() async {
    if (kIsWeb) return;
    var storageStatus = await Permission.storage.request();

    if (storageStatus.isDenied) {
      var manageStatus = await Permission.manageExternalStorage.request();
      if (manageStatus.isDenied || manageStatus.isPermanentlyDenied) {
        if (mounted) _showPermissionDeniedDialog();
        return;
      }
    }

    if (storageStatus.isPermanentlyDenied) {
      if (mounted) _showPermissionDeniedDialog();
      return;
    }

    if (!mounted) return;

    final libraryManager = context.read<AudioLibraryManager>();
    final folderNav = context.read<FolderNavigatorProvider>();

    List<Directory> availableRoots = [];

    final internalStorage = Directory(AppConstants.STORAGE_EMULATED_0);
    if (await internalStorage.exists()) availableRoots.add(internalStorage);

    final storageDir = Directory(AppConstants.STORAGE);
    if (await storageDir.exists()) {
      try {
        final List<FileSystemEntity> entities = await storageDir
            .list(followLinks: false)
            .toList();
        for (var entity in entities) {
          if (entity is Directory) {
            final String path = entity.path;
            // if (path != AppConstants.STORAGE_EMULATED && path != AppConstants.STORAGE_SELF && !path.startsWith(AppConstants.STORAGE_0000_0000) && RegExp(r'^/storage/[A-F0-9]{4}-[A-F0-9]{4}$').hasMatch(path)) {
            if (path != AppConstants.STORAGE_EMULATED &&
                path != AppConstants.STORAGE_SELF &&
                !path.startsWith(AppConstants.STORAGE_0000_0000) &&
                RegExp(AppConstants.MUSIC_PLAYER_REGEX).hasMatch(path)) {
              if (await entity.exists()) {
                availableRoots.add(entity);
              }
            }
          }
        }
      } catch (e) {
        loggingSornaz(" ============= ");
      }
    }

    if (availableRoots.isEmpty && await internalStorage.exists())
      availableRoots.add(internalStorage);
    await libraryManager.setRoots(availableRoots);

    if (!mounted) return;

    if (availableRoots.isNotEmpty) {
      await folderNav.startRealNavigation(availableRoots.first);
    }
    await libraryManager.loadOrScan();
    if (mounted) await folderNav.indexFiles(libraryManager.allFiles);
  }

  void _showPermissionDeniedDialog() {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(AppStrings.need_permission.translate(context)),
        content: Text(
          AppStrings.need_permission_for_scanning_audio_files.translate(
            context,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppStrings.later.translate(context)),
          ),
          ElevatedButton(
            onPressed: () {
              openAppSettings();
              Navigator.pop(context);
            },
            child: Text(AppStrings.go_to_settings.translate(context)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) return const BrowserMusicPlayer();
    final appData = Provider.of<AppData>(context);
    final isDark = appData.isDark;
    final localeProvider = Provider.of<LocaleProvider>(context, listen: false);
    final bool isEnglish =
        localeProvider.locale.languageCode == AppConstants.LOCALIZATION_EN;
    return Directionality(
      textDirection: isEnglish ? TextDirection.ltr : TextDirection.rtl,
      child: ScrollAwareScaffold(
        body: Consumer<AudioLibraryManager>(
          builder: (_, library, _) {
            if (library.isScanning) {
              return Container(
                color: AppColors.music_player_is_scanning_background_color(
                  isDark: isDark,
                ),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.space_24,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          AppStrings.music_player_scanning_files.translate(
                            context,
                          ),
                          style: AppTypography.musicPlayerScanningFiles(
                            context,
                          ),
                        ),
                        AppSpacing.sizedBoxH32(),
                        LinearProgressIndicator(value: library.progress),
                        AppSpacing.sizedBoxH32(),
                        Text(
                          "${library.scannedFiles} / ${library.totalFiles}   ${AppStrings.music_player_scanned_files.translate(context)}",
                          style: AppTypography.musicPlayerScannedFiles(context),
                        ),
                        AppSpacing.sizedBoxH32(),
                        Text(
                          library.currentPath,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: AppTypography.musicPlayerCurrentFileAddress(
                            context,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }
            return MusicPlayerTabs();
            // return Expanded(child: MusicPlayerTabs());
          },
        ),
      ),
    );
  }
}
