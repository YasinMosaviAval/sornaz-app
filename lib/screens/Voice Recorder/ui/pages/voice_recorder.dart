import 'package:sornaz/components/app_top_bar_direction.dart';
import '../components/seekable_waveform.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sornaz/screens/Social/social_widgets.dart';
import 'package:provider/provider.dart';
import 'package:sornaz/helpers/app_constants.dart';
import 'package:sornaz/helpers/app_strings.dart';
import 'package:sornaz/helpers/app_translations.dart';
import 'package:sornaz/screens/Voice%20Recorder/ui/components/basic_waveform.dart';

import 'package:sornaz/helpers/app_colors.dart';
import 'package:sornaz/helpers/app_data.dart';
import 'package:sornaz/helpers/app_navigation.dart';
import 'package:sornaz/helpers/app_spacing.dart';
import 'package:sornaz/helpers/app_typography.dart';
import 'package:sornaz/screens/Voice%20Recorder/provider/voice_recorder_provider.dart';
import 'package:sornaz/screens/Voice%20Recorder/ui/pages/recordings_list.dart';

class VoiceRecorderPage extends StatelessWidget {
  const VoiceRecorderPage({super.key});

  @override
  Widget build(BuildContext context) {
    final appData = context.watch<AppData>();
    final isDark = appData.isDark;

    return Consumer<VoiceRecorderProvider>(
      builder: (context, vm, _) {
        return Scaffold(
          appBar: AppTopBarDirection(
            child: AppBar(
              automaticallyImplyLeading: false,
              actions: [
                if (vm.isRecording || vm.isPaused)
                  IconButton(
                    icon: Icon(
                      vm.isFavorite
                          ? Icons.favorite_rounded
                          : Icons.favorite_outline_rounded,
                      size: AppSpacing.space_32,
                      color: vm.isFavorite
                          ? AppColors.voice_recorder_favorite_icon_active_color(
                              isDark: isDark,
                            )
                          : AppColors.voice_recorder_icon_color(isDark: isDark),
                    ),
                    onPressed: vm.toggleFavorite,
                  ),

                if (!vm.isRecording && !vm.isPaused)
                  IconButton(
                    icon: Icon(
                      Icons.folder_open,
                      color: AppColors.voice_recorder_icon_color(
                        isDark: isDark,
                      ),
                    ),
                    tooltip: AppStrings
                        .voice_recorder_recording_icon_button_tooltip
                        .translate(context),
                    onPressed: () {
                      navigateWithFade(context, RecordedFilesPage());
                    },
                  ),
              ],
              backgroundColor:
                  AppColors.voice_recorder_app_bar_background_color(
                    isDark: isDark,
                  ),
            ),
          ),
          backgroundColor: AppColors.voice_recorder_body_background_color(
            isDark: isDark,
          ),
          body: Column(
            children: [_RecorderSection(vm: vm, isDark: isDark)],
          ),
        );
      },
    );
  }
}

/// ------------------------------------------------------------
/// 🎙️ Recorder Section Widget (UI unchanged)
/// ------------------------------------------------------------
class _RecorderSection extends StatelessWidget {
  final VoiceRecorderProvider vm;
  final bool isDark;

  const _RecorderSection({required this.vm, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.space_32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.space_24,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        vm.timer,
                        style: AppTypography.voiceRecorderRecordingTimer(
                          context,
                        ),
                      ),
                    ],
                  ),
                ),
                if (vm.isPaused)
                  SizedBox(
                    height: 250,
                    child: SeekableWaveform(
                      samples: vm.amplitudes,
                      duration: vm.recordingMilliseconds,
                      position: vm.playbackService.position.inMilliseconds,
                      markers: vm.recordingBookmarks,
                      onSeek: (at) =>
                          vm.playbackService.seek(Duration(milliseconds: at)),
                    ),
                  )
                else
                  BasicWaveformWidget(
                    amplitudes: vm.amplitudes,
                    totalSamples: vm.totalSamples,
                    bookmarks: vm.recordingBookmarks,
                    elapsedMilliseconds: vm.recordingMilliseconds,
                    isRecording: vm.isRecording,
                    isPaused: vm.isPaused,
                  ),
                AppSpacing.sizedBoxH4(),
                if (vm.isRecording || vm.isPaused)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton.icon(
                        onPressed: vm.canBookmarkRecording
                            ? () => _recordAction(
                                context,
                                vm.addRecordingBookmark,
                              )
                            : null,
                        icon: const Icon(Icons.bookmark_add_outlined),
                        label: const Text('نشانه‌گذاری'),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Badge(
                          isLabelVisible: vm.recordingBookmarks.isNotEmpty,
                          label: Text(vm.recordingBookmarks.length.toString()),
                          child: const Icon(Icons.bookmark_border),
                        ),
                      ),
                    ],
                  ),
              ],
            ),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                if (vm.isRecording || vm.isPaused)
                  FloatingActionButton(
                    heroTag: AppConstants.STOP_HERO_TAG,
                    tooltip: socialText(context, 'پایان ضبط', 'Stop recording'),
                    elevation: 0,
                    hoverElevation: 0,
                    highlightElevation: 0,
                    shape: const CircleBorder(),
                    backgroundColor:
                        AppColors.voice_recorder_stop_icon_background_color(
                          isDark: isDark,
                        ),
                    onPressed: vm.isBusy
                        ? null
                        : () => _recordAction(context, vm.stopRecording),
                    child: Icon(
                      Icons.stop_rounded,
                      size: AppSpacing.space_36,
                      color: AppColors.voice_recorder_stop_icon_color(
                        isDark: isDark,
                      ),
                    ),
                  ),

                Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color:
                          AppColors.voice_recorder_record_button_border_color(
                            isDark: isDark,
                          ),
                      width: 2,
                    ),
                    borderRadius: BorderRadius.all(Radius.circular(50)),
                  ),
                  padding: EdgeInsets.all(AppSpacing.space_8),
                  child: SizedBox(
                    height: AppSpacing.space_48,
                    width: AppSpacing.space_48,
                    child: FloatingActionButton(
                      elevation: 0,
                      hoverElevation: 0,
                      highlightElevation: 0,
                      shape: const CircleBorder(),
                      backgroundColor: vm.isRecording
                          ? AppColors.voice_recorder_record_button_inactive_background_color(
                              isDark: isDark,
                            )
                          : AppColors.voice_recorder_record_button_active_background_color(
                              isDark: isDark,
                            ),
                      heroTag: AppConstants.MAIN_HERO_TAG,
                      tooltip: vm.isRecording
                          ? socialText(context, 'مکث ضبط', 'Pause recording')
                          : vm.isPaused
                          ? socialText(context, 'ادامه ضبط', 'Resume recording')
                          : socialText(context, 'شروع ضبط', 'Start recording'),
                      onPressed: vm.isBusy
                          ? null
                          : () => _recordAction(
                              context,
                              vm.isRecording
                                  ? vm.pauseRecording
                                  : vm.isPaused
                                  ? vm.resumeRecording
                                  : vm.startRecording,
                            ),
                      child: vm.isRecording
                          ? Icon(
                              Icons.pause_rounded,
                              size: AppSpacing.space_36,
                              color: AppColors.voice_recorder_pause_icon_color(
                                isDark: isDark,
                              ),
                            )
                          : null,
                    ),
                  ),
                ),

                if (vm.isRecording || vm.isPaused)
                  FloatingActionButton(
                    heroTag: AppConstants.PLAY_HERO_TAG,
                    elevation: 0,
                    hoverElevation: 0,
                    highlightElevation: 0,
                    shape: const CircleBorder(),
                    backgroundColor:
                        AppColors.voice_recorder_play_icon_background_color(
                          isDark: isDark,
                        ),
                    onPressed: vm.isPaused && !kIsWeb ? vm.playCurrent : null,
                    child: Icon(
                      vm.isPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      size: AppSpacing.space_36,
                      color: vm.isPaused
                          ? AppColors.voice_recorder_play_icon_active_color(
                              isDark: isDark,
                            )
                          : AppColors.voice_recorder_play_icon_inactive_color(
                              isDark: isDark,
                            ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _recordAction(
  BuildContext context,
  Future<void> Function() action,
) async {
  try {
    await action();
  } catch (error) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          error is MicrophonePermissionDenied
              ? socialText(
                  context,
                  'برای ضبط صدا، اجازه دسترسی به میکروفون لازم است.',
                  'Microphone permission is required to record audio.',
                )
              : socialText(
                  context,
                  'ضبط صدا انجام نشد. دوباره تلاش کنید.',
                  'Recording failed. Please try again.',
                ),
        ),
      ),
    );
  }
}
