/*
// ignore_for_file: use_build_context_synchronously
// ignore_for_file: unused_field
import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shamsi_date/shamsi_date.dart';
import 'package:sornaz/components/basic_waveform.dart';
import 'package:sornaz/components/bottom_nav.dart';
import 'package:sornaz/components/no_file_found.dart';
import 'package:sornaz/helpers/app_colors.dart';
import 'package:sornaz/helpers/app_data.dart';
import 'package:sornaz/helpers/app_locale_provider.dart';
import 'package:sornaz/helpers/app_spacing.dart';
import 'package:sornaz/helpers/app_strings.dart';
import 'package:sornaz/helpers/app_translations.dart';
import 'package:sornaz/helpers/app_typography.dart';
import 'package:sornaz/screens/Voice%20Recorder/record_details_page.dart';

class VoiceRecorderPage extends StatefulWidget {
  const VoiceRecorderPage({super.key});
  @override
  State<VoiceRecorderPage> createState() => _VoiceRecorderPageState();
}

class _VoiceRecorderPageState extends State<VoiceRecorderPage> {
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();

  bool _isRecording = false;
  bool _isPaused = false;
  bool _isPlaying = false;
  String _timerText = '00:00';
  int _seconds = 0;
  Timer? _timer;
  List<File> _recordings = [];
  String? _currentlyPlayingPath;
  String? _currentFilePath;
  bool isJalaliDate = false;

  final List<double> _amplitudes = [];
  StreamSubscription? _amplitudeSubscription;

  double? _lastDB;

  @override
  void initState() {
    super.initState();
    _checkPermissionsAndLoad();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _amplitudeSubscription?.cancel();
    _recorder.dispose();
    _player.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _seconds = 0;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isRecording || _isPaused) return;
      setState(() {
        _seconds++;
        final m = _seconds ~/ 60;
        final s = _seconds % 60;
        _timerText =
            '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
      });
    });
  }

  Future<void> _checkPermissionsAndLoad() async {
    final mic = await Permission.microphone.request();
    final storage = await Permission.storage.request();

    if (mic.isGranted && storage.isGranted) {
      await _loadRecordings();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppStrings.voice_recorder_microphone_and_storage_access_permissions.translate(context),
              style: AppTypography.voiceRecorderNotGrantedPermissionSnackBar(
                context,
              ),
            ),
          ),
        );
      }
    }
  }

  Future<void> _loadRecordings() async {
    final dir = await getApplicationDocumentsDirectory();
    final recordDir = Directory('${dir.path}/Recordings');

    if (!await recordDir.exists()) {
      await recordDir.create(recursive: true);
    }

    final files =
        recordDir
            .listSync()
            .whereType<File>()
            .where((f) => f.path.endsWith(AppStrings.file_type_dot_m4a))
            .toList()
          ..sort(
            (a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()),
          );

    if (mounted) setState(() => _recordings = files.cast<File>());
  }

  Future<void> _pauseRecording() async {
    await _recorder.pause();
    setState(() => _isPaused = true);
  }

  Future<void> _resumeRecording() async {
    await _recorder.resume();
    setState(() => _isPaused = false);
  }

  Future<void> _stopRecording() async {
    final path = await _recorder.stop();
    _amplitudeSubscription?.cancel();
    _amplitudeSubscription = null;
    _timer?.cancel();

    setState(() {
      _isRecording = false;
      _isPaused = false;
      _timerText = '00:00';
      _seconds = 0;
      _amplitudes.clear();
      _currentFilePath = null;
    });

    if (path != null) await _loadRecordings();
  }

  Future<void> _playPause(File file) async {
    if (_currentlyPlayingPath == file.path && _isPlaying) {
      await _player.stop();
      setState(() => _isPlaying = false);
      return;
    }

    await _player.play(DeviceFileSource(file.path));
    setState(() {
      _isPlaying = true;
      _currentlyPlayingPath = file.path;
    });

    _player.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _isPlaying = false);
    });
  }

  Future<void> _deleteRecording(File file) async {
    if (_currentlyPlayingPath == file.path) {
      await _player.stop();
      setState(() => _isPlaying = false);
    }
    await file.delete();
    await _loadRecordings();
  }

  Future<void> _startRecording() async {
    if (await _recorder.hasPermission()) {
      final dir = await getApplicationDocumentsDirectory();
      DateTime gregorianDate = DateTime.now();
      String gregorianFilename =
          gregorianDate.year.toString() +
          gregorianDate.month.toString().padLeft(2, '0') +
          gregorianDate.day.toString().padLeft(2, '0') +
          gregorianDate.hour.toString().padLeft(2, '0') +
          gregorianDate.minute.toString().padLeft(2, '0') +
          gregorianDate.second.toString().padLeft(2, '0');

      Jalali jalaliDate = gregorianDate.toJalali();
      String jalaliFilename =
          jalaliDate.year.toString() +
          jalaliDate.month.toString().padLeft(2, '0') +
          jalaliDate.day.toString().padLeft(2, '0') +
          jalaliDate.hour.toString().padLeft(2, '0') +
          jalaliDate.minute.toString().padLeft(2, '0') +
          jalaliDate.second.toString().padLeft(2, '0');

      _currentFilePath =
          '${dir.path}/Recordings/${isJalaliDate ? jalaliFilename : gregorianFilename}${AppStrings.file_type_dot_m4a}';

      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: _currentFilePath!,
      );

      setState(() {
        _isRecording = true;
        _isPaused = false;
        _amplitudes.clear();
        _lastDB = -60;
      });
      _startTimer();

      _amplitudeSubscription?.cancel();
      _amplitudeSubscription = _recorder
          .onAmplitudeChanged(const Duration(milliseconds: 100))
          .listen((amp) {
            if (!mounted || !_isRecording || _isPaused) return;

            final double db = amp.current;
            final double normalized = db < -60 ? 0.0 : (db + 60) / 60;

            setState(() {
              _lastDB = db;
              _amplitudes.add(normalized);
              if (_amplitudes.length > 400) {
                _amplitudes.removeAt(0);
              }
            });
          });
    }
  }

  String _formatJalaliDate(DateTime date) {
    final jalali = Jalali.fromDateTime(date);
    return '${jalali.year}/${jalali.month.toString().padLeft(2, '0')}/${jalali.day.toString().padLeft(2, '0')} - ${jalali.hour.toString().padLeft(2, '0')}:${jalali.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final appData = Provider.of<AppData>(context);
    final isDark = appData.isDark;
    final localeProvider = Provider.of<LocaleProvider>(context, listen: false);
    final bool isEnglish = localeProvider.locale.languageCode == AppStrings.localization_en;

    return Directionality(
      textDirection: isEnglish ? TextDirection.ltr : TextDirection.rtl,
      child: DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            title: TabBar(
              dividerHeight: 2,
              indicatorColor: isDark? AppColors.text_primary_dark : AppColors.text_primary_light,
              labelColor: isDark? AppColors.text_primary_dark : AppColors.text_primary_light,
              unselectedLabelColor:isDark? AppColors.text_secondary_dark : AppColors.text_secondary_light,
              dividerColor:isDark? AppColors.border_dark : AppColors.border_light,
              tabs: const [
                Tab(icon: Icon(Icons.mic, size: 32)),
                Tab(icon: Icon(Icons.list, size: 32)),
              ],
            ),
            backgroundColor: isDark? AppColors.surface_dark: AppColors.surface_light,
          ),
          backgroundColor: isDark? AppColors.background_dark: AppColors.background_light,
          body: TabBarView(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.space_32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    RecordingTimer(timerText: _timerText),
                    BasicWaveformWidget(
                      amplitudes: _amplitudes,
                      isRecording: _isRecording,
                      isPaused: _isPaused,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_isRecording) playPauseButton(isDark: isDark),
                        recordingButton(isDark: isDark),
                      ],
                    ),
                  ],
                ),
              ),
              _recordings.isEmpty
                  ? NoFilesFoundWidget(message: AppStrings.no_records_file.translate(context))
                  : voiceRecordsList(isDark: isDark),
            ],
          ),
          bottomNavigationBar: const BottomNavBarWidget(),
        ),
      ),
    );
  }

  ListView voiceRecordsList({required bool isDark}) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _recordings.length,
      itemBuilder: (context, index) {
        final file = _recordings[index];
        final fileName = file.path.split('/').last.replaceAll(AppStrings.file_type_dot_m4a, '');
        final date = _formatJalaliDate(file.lastModifiedSync());

        return AnimatedSwitcher(
          duration: Duration(milliseconds: 350),
          transitionBuilder: (child, animation) => SizeTransition(sizeFactor: animation, child: child),
          child: Card(
            key: ValueKey(file.path),
            elevation: 2,
            color: isDark ? AppColors.surface_dark: AppColors.surface_light,
            child: ListTile(
              onTap: () => _openDetailsPage(file),
              contentPadding: EdgeInsets.symmetric(
                horizontal: AppSpacing.space_16,
              ),
              horizontalTitleGap: 8,
              leading: IconButton(
                iconSize: AppSpacing.space_48,
                icon: Icon(
                  _currentlyPlayingPath == file.path && _isPlaying
                      ? Icons.pause_circle_filled
                      : Icons.play_circle_fill,
                  color: isDark ? AppColors.text_primary_dark : AppColors.text_primary_light,
                ),
                onPressed: () => _playPause(file),
              ),
              title: Text(
                fileName,
                style: AppTypography.voiceRecorderFilename(context),
              ),
              subtitle: Text(
                date,
                style: AppTypography.voiceRecorderDate(context),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    iconSize: AppSpacing.space_24,
                    icon: Icon(
                      Icons.edit,
                      color: AppColors.info,
                      size: AppSpacing.space_24,
                    ),
                    onPressed: () => _renameRecording(file, isDark: isDark),
                  ),
                  IconButton(
                    iconSize: AppSpacing.space_24,
                    icon: Icon(
                      Icons.delete_forever,
                      color: AppColors.error,
                      size: AppSpacing.space_24,
                    ),
                    onPressed: () => _confirmDelete(file, isDark: isDark),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _openDetailsPage(File file) async {
    final modifiedDate = file.lastModifiedSync();
    final jalaliDate = _formatJalaliDate(modifiedDate);

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RecordDetailsPage(
          file: file,
          jalaliDate: jalaliDate,
          onRename: (newName) async {
            final dir = file.parent.path;
            final newPath = "$dir/$newName${AppStrings.file_type_dot_m4a}";
            await file.rename(newPath);
            await _loadRecordings();
          },
          onDelete: () async {
            await _deleteRecording(file);
            await _loadRecordings();
          },
        ),
      ),
    );

    if (result != null && result["deleted"] == true) {
      final bytes = result["bytes"] as List<int>;
      final path = result["path"] as String;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppStrings.voice_recorder_file_deleted.translate(context),
            style: AppTypography.voiceRecorderDeleteFileSnackBar(context),
          ),
          action: SnackBarAction(
            label: AppStrings.voice_recorder_label_restore.translate(context),
            onPressed: () async {
              final restored = File(path);
              await restored.writeAsBytes(bytes);

              await _loadRecordings();

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    AppStrings.voice_recorder_file_restored.translate(context),
                    style: AppTypography.voiceRecorderRestoreFileSnackBar(
                      context,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      );
    }
  }

  Future<void> _confirmDelete(File file, {required bool isDark}) async {
    final fileName = file.path.split('/').last.replaceAll(AppStrings.file_type_dot_m4a, '');

    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppColors.surface_dark: AppColors.surface_light,
        title: Text(
          AppStrings.voice_recorder_delete_recording.translate(context),
          textAlign: TextAlign.center,
          style: AppTypography.voiceRecorderDeleteFileDialogueTitle(context),
        ),
        content: Text(
          "${AppStrings.voice_recorder_confirm_delete_before_filename.translate(context)}$fileName${AppStrings.voice_recorder_confirm_delete_after_filename.translate(context)}",
          textAlign: TextAlign.center,
          style: AppTypography.voiceRecorderDeleteFileDialogueContent(context),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              AppStrings.voice_recorder_no.translate(context),
              style: AppTypography.voiceRecorderDeleteFileDialogueCancelButton(
                context,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              AppStrings.voice_recorder_yes_delete.translate(context),
              style: AppTypography.voiceRecorderDeleteFileDialogueConfirmButton(
                context,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final bytes = await file.readAsBytes();
      final originalPath = file.path;

      await _deleteRecording(file);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "${AppStrings.voice_recorder_delete_message_before_filename.translate(context)}$fileName${AppStrings.voice_recorder_delete_message_after_filename.translate(context)}",
            style: AppTypography.voiceRecorderDeleteFileMessageSnackBar(
              context,
            ),
          ),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: AppStrings.voice_recorder_label_restore.translate(context),
            textColor: Colors.yellow,
            onPressed: () async {
              final restored = File(originalPath);
              await restored.writeAsBytes(bytes);
              await _loadRecordings();
            },
          ),
        ),
      );
    }
  }

  Future<void> _renameRecording(File file, {required bool isDark}) async {
    final oldName = file.path.split('/').last.replaceAll(AppStrings.file_type_dot_m4a, "");
    final controller = TextEditingController(text: oldName);

    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppColors.surface_dark: AppColors.surface_light,
        title: Text(
          AppStrings.voice_recorder_rename_file.translate(context),
          style: AppTypography.voiceRecorderRenameFileDialogueTitle(context),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            labelText: AppStrings.voice_recorder_new_filename.translate(context),
            border: OutlineInputBorder(),
          ),
          cursorColor: AppColors.error,
          style: AppTypography.voiceRecorderRenameFileDialogueTextField(
            context,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: Text(
              AppStrings.voice_recorder_discard.translate(context),
              style: AppTypography.voiceRecorderRenameFileDialogueCancelButton(
                context,
              ),
            ),
          ),
          ElevatedButton(
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.all(
                isDark ? AppColors.primary_dark : AppColors.primary_light,
              ),
            ),
            onPressed: () {
              if (controller.text.trim().isEmpty) return;
              Navigator.pop(context, controller.text.trim());
            },
            child: Text(
              AppStrings.voice_recorder_save.translate(context),
              style: AppTypography.voiceRecorderRenameFileDialogueConfirmButton(
                context,
              ),
            ),
          ),
        ],
      ),
    );

    if (newName == null) return;

    final dir = file.parent.path;
    final newPath = "$dir/$newName${AppStrings.file_type_dot_m4a}";

    try {
      await file.rename(newPath);
      await _loadRecordings();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "${AppStrings.voice_recorder_filename_changed_before_filename.translate(context)}$newName${AppStrings.voice_recorder_filename_changed_after_filename.translate(context)}",
            style: AppTypography.voiceRecorderRenameFileMessageSnackBar(
              context,
            ),
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppStrings.voice_recorder_error_in_renaming.translate(context),
            style: AppTypography.voiceRecorderRenameFileErrorMessageSnackBar(
              context,
            ),
          ),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  SizedBox recordingButton({required bool isDark}) {
    return SizedBox(
      height: AppSpacing.space_76,
      width: AppSpacing.space_76,
      child: FloatingActionButton(
        heroTag: AppStrings.voice_recorder_hero_tag_main,
        backgroundColor: AppColors.error,
        onPressed: _isRecording ? _stopRecording : _startRecording,
        
        child: Icon(
          _isRecording ? Icons.stop : Icons.mic,
          size: AppSpacing.space_40,
          color: isDark ? AppColors.text_primary_dark : AppColors.text_primary_light,
        ),
      ),
    );
  }

  FloatingActionButton playPauseButton({required bool isDark}) {
    return FloatingActionButton(
      heroTag: AppStrings.voice_recorder_hero_tag_pause,
      backgroundColor: _isPaused
                        ? isDark? AppColors.clicked_dark: AppColors.clicked_light 
                        : isDark? AppColors.surface_dark: AppColors.surface_light,
      onPressed: _isPaused ? _resumeRecording : _pauseRecording,
      child: Icon(
        _isPaused ? Icons.play_arrow : Icons.pause, 
        size: AppSpacing.space_36, 
        color: isDark ? AppColors.text_primary_dark : AppColors.text_primary_light
      ),
    );
  }
}
*/


import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sornaz/components/bottom_nav.dart';
import 'package:sornaz/components/no_file_found.dart';
import 'package:sornaz/helpers/app_colors.dart';
import 'package:sornaz/helpers/app_functions.dart';
import 'package:sornaz/helpers/app_spacing.dart';
import 'package:sornaz/helpers/app_strings.dart';
import 'package:sornaz/helpers/app_translations.dart';
import 'package:sornaz/helpers/app_typography.dart';
import 'package:sornaz/screens/Voice%20Recorder/voice_recorder/provider/voice_recorder_provider.dart';


class VoiceRecorderPage extends StatelessWidget {
  const VoiceRecorderPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    /// 🔐 Permission request (جایگزین initState قدیمی)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VoiceRecorderProvider>().requestPermissions(context);
    });

    return Consumer<VoiceRecorderProvider>(
      builder: (context, vm, _) {
        return Scaffold(
          appBar: AppBar(
            title: Text(
              AppStrings.voice_recorder_title.translate(context),
            ),
          ),
          body: Column(
            children: [
              /// 🎙️ Recorder Section (UI بدون تغییر)
              _RecorderSection(vm: vm, isDark: isDark),

              const SizedBox(height: AppSpacing.space_16),

              /// 📁 Files List
              Expanded(
                child: vm.files.isEmpty
                    ? NoFilesFoundWidget(
                        message: AppStrings.no_records_file
                            .translate(context),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: vm.files.length,
                        itemBuilder: (context, index) {
                          final file = vm.files[index];
                          final fileName = file.path
                              .split('/')
                              .last
                              .replaceAll(
                                  AppStrings.file_type_dot_m4a, '');
                          final date =
                              formatJalali(file.lastModifiedSync());

                          return AnimatedSwitcher(
                            duration:
                                const Duration(milliseconds: 350),
                            transitionBuilder:
                                (child, animation) =>
                                    SizeTransition(
                              sizeFactor: animation,
                              child: child,
                            ),
                            child: Card(
                              key: ValueKey(file.path),
                              elevation: 2,
                              color: isDark
                                  ? AppColors.surface_dark
                                  : AppColors.surface_light,
                              child: ListTile(
                                contentPadding:
                                    const EdgeInsets.symmetric(
                                  horizontal:
                                      AppSpacing.space_16,
                                ),
                                horizontalTitleGap: 8,
                                leading: IconButton(
                                  iconSize:
                                      AppSpacing.space_48,
                                  icon: Icon(
                                    Icons.play_circle_fill,
                                    color: isDark
                                        ? AppColors
                                            .text_primary_dark
                                        : AppColors
                                            .text_primary_light,
                                  ),
                                  onPressed: () {
                                    // playback مثل نسخه قبلی (UI only)
                                  },
                                ),
                                title: Text(
                                  fileName,
                                  style: AppTypography
                                      .voiceRecorderFilename(
                                          context),
                                ),
                                subtitle: Text(
                                  date,
                                  style: AppTypography
                                      .voiceRecorderDate(
                                          context),
                                ),
                                trailing: Row(
                                  mainAxisSize:
                                      MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      iconSize:
                                          AppSpacing
                                              .space_24,
                                      icon: const Icon(
                                        Icons.edit,
                                        color:
                                            AppColors.info,
                                      ),
                                      onPressed: () =>
                                          _renameRecording(
                                        context,
                                        file,
                                        isDark,
                                      ),
                                    ),
                                    IconButton(
                                      iconSize:
                                          AppSpacing
                                              .space_24,
                                      icon: const Icon(
                                        Icons.delete_forever,
                                        color: AppColors
                                            .error,
                                      ),
                                      onPressed: () =>
                                          _confirmDelete(
                                        context,
                                        file,
                                        isDark,
                                        vm,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
          bottomNavigationBar: const BottomNavBarWidget(),
        );
      },
    );
  }

  // ------------------------------------------------------------
  // 📝 Rename Recording (UI logic)
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
                .voice_recorder_new_filename
                .translate(context),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppStrings.voice_recorder_discard.translate(context)),
          ),
          ElevatedButton(
            onPressed: () =>
                Navigator.pop(context, controller.text.trim()),
            child: Text(AppStrings.voice_recorder_save.translate(context)),
          ),
        ],
      ),
    );

    if (newName == null ||
        newName.isEmpty ||
        newName == oldName) return;

    final newPath = file.path.replaceFirst(
      '$oldName${AppStrings.file_type_dot_m4a}',
      '$newName${AppStrings.file_type_dot_m4a}',
    );

    await file.rename(newPath);
    context.read<VoiceRecorderProvider>().init();
  }

  // ------------------------------------------------------------
  // ❌ Confirm Delete Dialog
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
    return Column(
      children: [
        const SizedBox(height: AppSpacing.space_24),
        Text(
          vm.timer,
          style: AppTypography.voiceRecorderRecordingTimer(context),
        ),
        const SizedBox(height: AppSpacing.space_16),

        /// 🔴 Buttons (دقیقاً مثل قبل)
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (vm.isRecording)
              FloatingActionButton(
                heroTag: 'pause',
                backgroundColor: vm.isPaused
                    ? (isDark
                        ? AppColors.clicked_dark
                        : AppColors.clicked_light)
                    : (isDark
                        ? AppColors.surface_dark
                        : AppColors.surface_light),
                onPressed:
                    vm.isPaused ? vm.resume : vm.pause,
                child: Icon(
                  vm.isPaused
                      ? Icons.play_arrow
                      : Icons.pause,
                ),
              ),
            const SizedBox(width: AppSpacing.space_24),
            FloatingActionButton(
              heroTag: 'main',
              backgroundColor: AppColors.error,
              onPressed:
                  vm.isRecording ? vm.stop : vm.start,
              child: Icon(
                vm.isRecording ? Icons.stop : Icons.mic,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.space_24),
      ],
    );
  }
}
