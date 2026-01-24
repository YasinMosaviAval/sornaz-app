import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:just_waveform/just_waveform.dart';
import 'package:sornaz/helpers/app_constants.dart';
import 'package:sornaz/screens/Voice%20Recorder/ui/components/delete_button.dart';
import 'package:sornaz/screens/Voice%20Recorder/ui/components/recorded_voice_information.dart';
import 'package:sornaz/screens/Voice%20Recorder/ui/components/rename_button.dart';
import 'package:sornaz/screens/Voice%20Recorder/ui/components/waveform_widget.dart';
import 'package:sornaz/helpers/app_colors.dart';
import 'package:sornaz/helpers/app_data.dart';
import 'package:sornaz/helpers/app_locale_provider.dart';
import 'package:sornaz/helpers/app_spacing.dart';
import 'package:sornaz/helpers/app_strings.dart';
import 'package:sornaz/helpers/app_translations.dart';
import 'package:sornaz/helpers/app_typography.dart';

class RecordDetailsPage extends StatefulWidget {
  final File file;
  final Function(String) onRename;
  final Function() onDelete;
  final String jalaliDate;

  const RecordDetailsPage({
    super.key,
    required this.file,
    required this.onRename,
    required this.onDelete,
    required this.jalaliDate,
  });

  @override
  State<RecordDetailsPage> createState() => _RecordDetailsPageState();
}

class _RecordDetailsPageState extends State<RecordDetailsPage> {
  late Future<List<int>> waveformFuture;
  late Future<Duration> durationFuture;

  double zoom = 1.0;

  @override
  void initState() {
    super.initState();
    waveformFuture = _loadWaveform(widget.file);
    durationFuture = _getAudioDuration(widget.file.path);
  }

  Future<List<int>> _loadWaveform(File file) async {
    final tmp = File("${file.path}.${AppConstants.WAVEFORM}");
    final stream = JustWaveform.extract(audioInFile: file, waveOutFile: tmp);
    final last = await stream.last;
    return last.waveform?.data ?? <int>[];
  }

  Future<Duration> _getAudioDuration(String path) async {
    final player = AudioPlayer();
    await player.setSource(DeviceFileSource(path));
    final duration = await player.getDuration() ?? Duration.zero;
    await player.dispose();
    return duration;
  }

  @override
  Widget build(BuildContext context) {
    final fileName = widget.file.path.split('/').last.replaceAll(AppConstants.DOT_M4A, "");
    final appData = Provider.of<AppData>(context);
    final isDark = appData.isDark;
    final localeProvider = Provider.of<LocaleProvider>(context, listen: false);
    final bool isEnglish = localeProvider.locale.languageCode == AppConstants.LOCALIZATION_EN;

    return Directionality(
      textDirection: isEnglish ? TextDirection.ltr : TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            AppStrings.record_details_record_information.translate(context),
            style: AppTypography.recordDetailsAppBar(context),
          ),
          backgroundColor: AppColors.voice_recorder_record_details_page_app_bar_background_color(isDark: isDark),
          foregroundColor: AppColors.voice_recorder_record_details_page_app_bar_foreground_color(isDark: isDark),
        ),
        backgroundColor: AppColors.voice_recorder_record_details_page_background_color(isDark: isDark),
        body: Padding(
          padding: const EdgeInsets.all(AppSpacing.space_16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RecordedVoiceInformationWidget(
                fileName: fileName,
                jalaliDate: widget.jalaliDate,
                isDark: isDark,
              ),
              AppSpacing.sizedBoxH24(),
              const Divider(),
              Expanded(
                child: FutureBuilder<List<int>>(
                  future: waveformFuture,
                  builder: (context, waveformSnap) {
                    if (!waveformSnap.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    return FutureBuilder<Duration>(
                      future: durationFuture,
                      builder: (context, durationSnap) {
                        if (!durationSnap.hasData) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        return WaveformPlayerView(
                          samples: waveformSnap.data!,
                          duration: durationSnap.data!,
                          filePath: widget.file.path,
                          color: AppColors.voice_recorder_record_details_page_waveform_player_view_background_color(isDark: isDark),
                        );
                      },
                    );
                  },
                ),
              ),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  RenameButtonWidget(
                    controller: TextEditingController(text: fileName),
                    onRename: widget.onRename,
                    isDark: isDark,
                  ),
                  AppSpacing.sizedBoxW16(),
                  DeleteButtonWidget(
                    onDelete: widget.onDelete,
                    file: widget.file,
                    onUndoRestore: (restoredFile, bytes) async {
                      await restoredFile.writeAsBytes(bytes);
                    },
                    isDark: isDark,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
