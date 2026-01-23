import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sornaz/helpers/app_constants.dart';
import 'package:sornaz/helpers/app_strings.dart';
import 'package:sornaz/helpers/app_translations.dart';
import 'package:sornaz/screens/Voice%20Recorder/basic_waveform.dart';
import 'package:sornaz/components/bottom_nav.dart';
import 'package:sornaz/helpers/app_colors.dart';
import 'package:sornaz/helpers/app_data.dart';
import 'package:sornaz/helpers/app_navigation.dart';
import 'package:sornaz/helpers/app_spacing.dart';
import 'package:sornaz/helpers/app_typography.dart';
import 'package:sornaz/screens/Voice%20Recorder/voice_recorder/provider/voice_recorder_provider.dart';
import 'package:sornaz/screens/Voice%20Recorder/voice_recorder/view/screens/recordings_list.dart';


class VoiceRecorderPage extends StatelessWidget {
  const VoiceRecorderPage({super.key});

  @override
  Widget build(BuildContext context) {
    final appData = context.watch<AppData>();
    final isDark = appData.isDark;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VoiceRecorderProvider>().requestPermissions(context);
    });

    return Consumer<VoiceRecorderProvider>(
      builder: (context, vm, _) {
        return Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            actions: [
              if (vm.isRecording || vm.isPaused)
                IconButton(
                  icon: Icon(
                    vm.isFavorite ? Icons.favorite_rounded : Icons.favorite_outline_rounded,
                    size: AppSpacing.space_32,
                    color: vm.isFavorite
                        ? AppColors.voice_recorder_favorite_icon_active_color(isDark: isDark)
                        : AppColors.voice_recorder_icon_color(isDark: isDark),
                  ),
                  onPressed: vm.toggleFavorite,
                ),

              if (!vm.isRecording && !vm.isPaused)
                IconButton(
                  icon: Icon(
                    Icons.folder_open,
                    color: AppColors.voice_recorder_icon_color(isDark: isDark),
                  ),
                  tooltip: AppStrings.voice_recorder_recording_icon_button_tooltip.translate(context),
                  onPressed: () {
                    navigateWithFade(context, RecordedFilesPage());
                  },
                ),
            ],
            backgroundColor: AppColors.voice_recorder_app_bar_background_color(isDark: isDark),
          ),
          backgroundColor: AppColors.voice_recorder_body_background_color(isDark: isDark),
          body: Column(
            children: [
              _RecorderSection(vm: vm, isDark: isDark),
            ],
          ),
          bottomNavigationBar: const BottomNavBarWidget(),
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

  const _RecorderSection({
    required this.vm,
    required this.isDark,
  });

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
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.space_24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        vm.timer,
                        style: AppTypography.voiceRecorderRecordingTimer(context),
                      ),
                    ],
                  ),
                ),
                BasicWaveformWidget(
                  amplitudes: vm.amplitudes,
                  isRecording: vm.isRecording,
                  isPaused: vm.isPaused,
                ),
                AppSpacing.sizedBoxH4(),
                if (vm.isRecording || vm.isPaused)
                  TextButton(
                    onPressed: null,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppStrings.voice_recorder_bookmark_text_button.translate(context),
                          style: AppTypography.voiceRecorderBookmarkTextButton(context, isDark),
                        ),
                        AppSpacing.sizedBoxW4(),
                        Icon(
                          Icons.bookmark_rounded,
                          size: AppSpacing.space_16,
                          color: AppColors.voice_recorder_bookmark_icon_color(isDark: isDark),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                if (vm.isRecording || vm.isPaused)
                  FloatingActionButton(
                    heroTag: AppConstants.STOP_HERO_TAG,
                    elevation: 0,
                    hoverElevation: 0,
                    highlightElevation: 0,
                    shape: const CircleBorder(),
                    backgroundColor: AppColors.voice_recorder_stop_icon_background_color(isDark: isDark),
                    onPressed: vm.stopRecording,
                    child: Icon(
                      Icons.stop_rounded,
                      size: AppSpacing.space_36,
                      color: AppColors.voice_recorder_stop_icon_color(isDark: isDark),
                    ),
                  ),
                
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: AppColors.voice_recorder_record_button_border_color(isDark: isDark),
                      width: 2,
                    ),
                    borderRadius: BorderRadius.all(Radius.circular(50))
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
                        ? AppColors.voice_recorder_record_button_inactive_background_color(isDark: isDark)
                        : AppColors.voice_recorder_record_button_active_background_color(isDark: isDark),
                      heroTag: AppConstants.MAIN_HERO_TAG,
                      onPressed: vm.isRecording ? vm.pauseRecording : vm.resumeRecording,
                      child: vm.isRecording ? Icon(
                        Icons.pause_rounded,
                        size: AppSpacing.space_36,
                        color: AppColors.voice_recorder_pause_icon_color(isDark: isDark),
                      ) : null,
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
                    backgroundColor: AppColors.voice_recorder_play_icon_background_color(isDark: isDark),
                    onPressed: vm.isPaused ? vm.playCurrent : null,
                    child: Icon(
                      vm.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      size: AppSpacing.space_36,
                      color: vm.isPaused
                        ? AppColors.voice_recorder_play_icon_active_color(isDark: isDark)
                        : AppColors.voice_recorder_play_icon_inactive_color(isDark: isDark),
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
