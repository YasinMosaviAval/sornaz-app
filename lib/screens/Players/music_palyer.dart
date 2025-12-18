import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:sornaz/helpers/app_colors.dart';
import 'package:sornaz/helpers/app_data.dart';
import 'package:sornaz/helpers/app_locale_provider.dart';
import 'package:sornaz/helpers/app_typography.dart';
import 'package:sornaz/helpers/app_spacing.dart';
import 'package:sornaz/audio/audio_player_provider.dart';
import 'package:sornaz/components/bottom_nav.dart';
import 'package:sornaz/audio/folder_navigator_provider.dart';
import 'package:sornaz/helpers/app_strings.dart';
import 'package:sornaz/helpers/app_translations.dart';
import 'package:sornaz/screens/Players/music_player_tabs.dart';
import 'package:sornaz/audio/scan/audio_file_loader.dart';

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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final audio = context.read<AudioPlayerProvider>();
      final folderNav = context.read<FolderNavigatorProvider>();

      audio.start();

      AudioFileLoader.scanWithIsolate(
        roots: [
          Directory('/storage/emulated/0/'),
          Directory('/storage/9C33-6BBD/Music/')
        ],
        onProgress: (status) => audio.update(status),
        onDone: (result) {
          audio.finish(result);

          final folderPaths = result.map((f) => f.file.parent.path).toSet().toList();
          final folderMap = {for (var path in folderPaths) path: result.where((f) => f.file.parent.path == path).toList()};

          folderNav.setRoots(folderPaths.map((p) => Directory(p)).toList(), folderMap);
        },
      );
    });
  }

  Future<void> _requestPermissionsAndScan() async {
    var storageStatus = await Permission.storage.request();

    if (storageStatus.isDenied) {
      var manageStatus = await Permission.manageExternalStorage.request();
      if (manageStatus.isDenied || manageStatus.isPermanentlyDenied) {
        _showPermissionDeniedDialog();
        return;
      }
    }if (storageStatus.isPermanentlyDenied) {
      _showPermissionDeniedDialog();
      return;
    }

    if(!mounted) return;
    final audio = context.read<AudioPlayerProvider>();
    final folderNav = context.read<FolderNavigatorProvider>();

    audio.start();

    AudioFileLoader.scanWithIsolate(
      roots: [
        Directory('/storage/emulated/0/'),
        Directory('/storage/9C33-6BBD'),
      ],
      onProgress: (status) => audio.update(status),
      onDone: (result) {
        audio.finish(result);
        
        final folderPaths = result.map((f) => f.file.parent.path).toSet().toList();
        final folderMap = {
          for (var path in folderPaths)
            path: result.where((f) => f.file.parent.path == path).toList()
        };
        folderNav.setRoots(
          folderPaths.map((p) => Directory(p)).toList(),
          folderMap,
        );
      },
    ).catchError((error) {
      if (!mounted) return;
      audio.isScanning = false;
      audio.isLoading = false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("خطا در اسکن: $error")),
      );
    });
  }

void _showPermissionDeniedDialog() {
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
              openAppSettings();  // کاربر رو ببر به تنظیمات برنامه
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
        body: Consumer<AudioPlayerProvider>(
          builder: (_, audio, _) {
            if (audio.isScanning) {
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
                        LinearProgressIndicator(value: audio.progress),
                        AppSpacing.sizedBoxH32(),
                        Text(
                          "${audio.scannedFiles} / ${audio.totalFiles}   ${AppStrings.music_player_scanned_files.translate(context)}",
                          style: AppTypography.musicPlayerScannedFiles(context)
                        ),
                        AppSpacing.sizedBoxH32(),
                        Text(
                          audio.currentPath, 
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
            // if (audio.isLoading) return const Center(child: CircularProgressIndicator());
            return Expanded(child: MusicPlayerTabs());
          },
        ),
        bottomNavigationBar: const BottomNavBarWidget(),
      ),
    );
  }
}
