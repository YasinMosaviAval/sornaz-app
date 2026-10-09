import '../../providers/audio_player_provider.dart';
import '../../services/player_settings.dart';
import '../components/player_dialog.dart';
import '../components/search_bar.dart';
import 'package:sornaz/components/scroll_aware_scaffold.dart';
import 'package:flutter/foundation.dart';
import 'browser_music_player.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:sornaz/helpers/app_constants.dart';
import 'package:sornaz/helpers/app_colors.dart';
import 'package:sornaz/helpers/app_data.dart';
import 'package:sornaz/helpers/app_locale_provider.dart';
import 'package:sornaz/helpers/app_typography.dart';
import 'package:sornaz/helpers/app_spacing.dart';

import 'package:sornaz/helpers/app_strings.dart';
import 'package:sornaz/helpers/app_translations.dart';
import 'package:sornaz/screens/Players/library/audio_library_manager.dart';
import 'package:sornaz/screens/Players/library/device_audio_scan.dart';
import 'package:sornaz/screens/Players/providers/folder_navigator_provider.dart';
import 'package:sornaz/screens/Players/ui/pages/music_player_tabs.dart';

class MusicPlayerPage extends StatefulWidget {
  const MusicPlayerPage({super.key});

  @override
  State<MusicPlayerPage> createState() => _MusicPlayerPageState();
}

class _MusicPlayerPageState extends State<MusicPlayerPage> {
  int activeTab = 0;
  AudioPlayerProvider? player;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    player = context.read<AudioPlayerProvider>();
  }

  @override
  void dispose() {
    player?.interrupt(PlaybackInterruption.leavePlayer);
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestPermissionsAndScan();
    });
  }

  Future<void> _requestPermissionsAndScan() async {
    if (kIsWeb) return;
    final allowed = await hasAudioStoragePermission(request: true);
    if (!mounted) return;
    if (!allowed) {
      _showPermissionDeniedDialog();
      return;
    }
    final player = context.read<AudioPlayerProvider>();
    await player.restoreLastPlayback();
    await _rescan(requestPermission: false);
    if (mounted && player.currentAudio == null) {
      await player.restoreLastPlayback();
    }
  }

  Future<void> _rescan({bool requestPermission = true}) async {
    final refreshed = await refreshDeviceAudioLibrary(
      library: context.read<AudioLibraryManager>(),
      folders: context.read<FolderNavigatorProvider>(),
      requestPermission: requestPermission,
    );
    if (!refreshed && mounted && requestPermission) {
      _showPermissionDeniedDialog();
    }
  }

  void _showPermissionDeniedDialog() {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PlayerDialog(
        title: Text(AppStrings.need_permission.translate(context)),
        content: Text(
          AppStrings.need_permission_for_scanning_audio_files.translate(
            context,
          ),
        ),
        actions: [
          PlayerDialogButton(
            primary: false,
            onPressed: () => Navigator.pop(context),
            child: Text(AppStrings.later.translate(context)),
          ),
          PlayerDialogButton(
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
        appBar: SearchBarWidget(tab: activeTab, onRescan: _rescan),
        pinTopBar: true,
        body: Consumer<AudioLibraryManager>(
          builder: (_, library, _) {
            if (library.isScanning && library.allFiles.isEmpty) {
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
                        LinearProgressIndicator(
                          value: library.totalFiles == 0
                              ? null
                              : library.progress,
                        ),
                        AppSpacing.sizedBoxH32(),
                        Text(
                          library.totalFiles == 0
                              ? '${library.scannedFiles} ${AppStrings.music_player_scanned_files.translate(context)}'
                              : '${library.scannedFiles} / ${library.totalFiles}   ${AppStrings.music_player_scanned_files.translate(context)}',
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
            return Column(
              children: [
                if (library.isScanning)
                  LinearProgressIndicator(
                    value: library.totalFiles == 0 ? null : library.progress,
                  ),
                Expanded(
                  child: MusicPlayerTabs(
                    onTabChanged: (tab) {
                      if (activeTab != tab) setState(() => activeTab = tab);
                    },
                  ),
                ),
              ],
            );
            // return Expanded(child: MusicPlayerTabs());
          },
        ),
      ),
    );
  }
}
