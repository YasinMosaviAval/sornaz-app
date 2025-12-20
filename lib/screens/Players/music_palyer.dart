import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:sornaz/audio/library/audio_library_manager.dart';
import 'package:sornaz/helpers/app_colors.dart';
import 'package:sornaz/helpers/app_data.dart';
import 'package:sornaz/helpers/app_locale_provider.dart';
import 'package:sornaz/helpers/app_typography.dart';
import 'package:sornaz/helpers/app_spacing.dart';
import 'package:sornaz/components/bottom_nav.dart';
import 'package:sornaz/audio/folder_navigator_provider.dart';
import 'package:sornaz/helpers/app_strings.dart';
import 'package:sornaz/helpers/app_translations.dart';
import 'package:sornaz/screens/Players/music_player_tabs.dart';

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

    if(!mounted) return;
    
    final libraryManager = context.read<AudioLibraryManager>();
    final folderNav = context.read<FolderNavigatorProvider>();

    List<Directory> availableRoots = [];

    final internalStorage = Directory('/storage/emulated/0');
    if (await internalStorage.exists()) availableRoots.add(internalStorage);

    final storageDir = Directory('/storage');
    if (await storageDir.exists()) {
      try {
        final List<FileSystemEntity> entities = storageDir.listSync();
        for (var entity in entities) {
          if (entity is Directory) {
            final String path = entity.path;
            if (path != '/storage/emulated' && path != '/storage/self' && !path.startsWith('/storage/0000-0000') && RegExp(r'^/storage/[A-F0-9]{4}-[A-F0-9]{4}$').hasMatch(path)) {
              if (await entity.exists()) {
                availableRoots.add(entity);
              }
            }
          }
        }
      } catch (e) {
        //
      }
    }

    if (availableRoots.isEmpty && await internalStorage.exists()) availableRoots.add(internalStorage);
    await libraryManager.setRoots(availableRoots);

    if (!mounted) return;

    await libraryManager.loadOrScan();

    if (libraryManager.allFiles.isNotEmpty && mounted) {
      final folderPaths = libraryManager.allFiles.map((f) => f.file.parent.path).toSet().toList();
      final folderMap = {
        for (var path in folderPaths)
          path: libraryManager.allFiles.where((f) => f.file.parent.path == path).toList()
      };
      folderNav.setRoots(folderPaths.map((p) => Directory(p)).toList(), folderMap);
    }
  }

  void _showPermissionDeniedDialog() {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("دسترسی لازم است"),
        content: const Text(
          "برای اسکن فایل‌های موسیقی، دسترسی به حافظه دستگاه لازم است. لطفاً در تنظیمات برنامه مجوز را فعال کنید.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("بعداً"),
          ),
          ElevatedButton(
            onPressed: () {
              openAppSettings();
              Navigator.pop(context);
            },
            child: const Text("رفتن به تنظیمات"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appData = Provider.of<AppData>(context);
    final isDark = appData.isDark;
    final localeProvider = Provider.of<LocaleProvider>(context, listen: false);
    final bool isEnglish = localeProvider.locale.languageCode == AppStrings.localization_en;
    return Directionality(
      textDirection: isEnglish ? TextDirection.ltr : TextDirection.rtl,
      child: Scaffold(
        body: Consumer<AudioLibraryManager>(
          builder: (_, library, _) {
            if (library.isScanning) {
              return Container(
                color: isDark ? AppColors.background_dark : AppColors.background_light,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space_24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          AppStrings.music_player_scanning_files.translate(context),
                          style: AppTypography.musicPlayerScanningFiles(context)
                        ),
                        AppSpacing.sizedBoxH32(),
                        LinearProgressIndicator(value: library.progress),
                        AppSpacing.sizedBoxH32(),
                        Text(
                          "${library.scannedFiles} / ${library.totalFiles}   ${AppStrings.music_player_scanned_files.translate(context)}",
                          style: AppTypography.musicPlayerScannedFiles(context)
                        ),
                        AppSpacing.sizedBoxH32(),
                        Text(
                          library.currentPath, 
                          maxLines: 2, 
                          overflow: TextOverflow.ellipsis, 
                          textAlign: TextAlign.center, 
                          style: AppTypography.musicPlayerCurrentFileAddress(context)
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }
            return Expanded(child: MusicPlayerTabs());
          },
        ),
        bottomNavigationBar: const BottomNavBarWidget(),
      ),
    );
  }
}
