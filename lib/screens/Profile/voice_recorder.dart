// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shamsi_date/shamsi_date.dart';
// import 'package:sornaz/components/advanced_waveform.dart';
import 'package:sornaz/components/basic_waveform.dart';
import 'package:sornaz/components/bottom_nav.dart';
// import 'package:sornaz/components/db_meter.dart';
import 'package:sornaz/components/no_file_found.dart';
import 'package:sornaz/helpers/app_colors.dart';
import 'package:sornaz/helpers/app_data.dart';
import 'package:sornaz/helpers/app_locale_provider.dart';
import 'package:sornaz/helpers/app_spacing.dart';
import 'package:sornaz/helpers/app_strings.dart';
import 'package:sornaz/helpers/app_translations.dart';
import 'package:sornaz/helpers/app_typography.dart';
import 'package:sornaz/screens/Profile/record_details_page.dart';

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

  // برای نمودار شدت صوت زنده
  final List<double> _amplitudes = [];
  StreamSubscription? _amplitudeSubscription;

  // ignore: unused_field
  double? _lastDB;

  @override
  void initState() {
    super.initState();
    _checkPermissionsAndLoad();
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
              'اجازه دسترسی به میکروفون و حافظه لازم است',
              style: AppTypography.voiceRecorderNotGrantedPermissionSnackBar,
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
            .where((f) => f.path.endsWith('.m4a'))
            .toList()
          ..sort(
            (a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()),
          );

    if (mounted) setState(() => _recordings = files.cast<File>());
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

  String _formatJalaliDate(DateTime date) {
    final jalali = Jalali.fromDateTime(date);
    return '${jalali.year}/${jalali.month.toString().padLeft(2, '0')}/${jalali.day.toString().padLeft(2, '0')} - ${jalali.hour.toString().padLeft(2, '0')}:${jalali.minute.toString().padLeft(2, '0')}';
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
          '${dir.path}/Recordings/${isJalaliDate ? jalaliFilename : gregorianFilename}.m4a';

      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          // bitRate: 128000,
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
          .onAmplitudeChanged(const Duration(milliseconds: 10))
          .listen((amp) {
            if (!mounted || !_isRecording || _isPaused) return;

            final double db = amp.current; // دسی‌بل واقعی
            final double normalized = db < -60 ? 0.0 : (db + 60) / 60; // 0 تا 1

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

  @override
  void dispose() {
    _timer?.cancel();
    _amplitudeSubscription?.cancel();
    _recorder.dispose();
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appData = Provider.of<AppData>(context);
    final isDark = appData.isDark;

    final localeProvider = Provider.of<LocaleProvider>(context, listen: false);
    // final theme = Theme.of(context);
    final bool isEnglish = localeProvider.locale.languageCode == 'en';

    return Directionality(
      textDirection: isEnglish ? TextDirection.ltr : TextDirection.rtl,
      child: DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            title: TabBar(
              dividerHeight: 2,
              indicatorColor: AppColors.text_primary_light,
              labelColor: AppColors.text_primary_light,
              unselectedLabelColor: AppColors.text_secondary_light,
              dividerColor: AppColors.border_light,
              tabs: const [
                Tab(icon: Icon(Icons.mic, size: 32)),
                Tab(icon: Icon(Icons.list, size: 32)),
              ],
            ),
          ),
          body: TabBarView(
            children: [
              // TAB 1: ضبط صدا
              Column(
                children: [
                  RecordingTimer(timerText: _timerText),

                  BasicWaveformWidget(
                    isDark: isDark,
                    amplitudes: _amplitudes,
                    isRecording: _isRecording,
                    isPaused: _isPaused,
                  ),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_isRecording) playPauseButton(),
                      const SizedBox(width: 30),
                      recordingButton(),
                    ],
                  ),
                ],
              ),

              // TAB 2: لیست فایل‌ها
              _recordings.isEmpty
                  ? NoFilesFoundWidget(
                      message: AppStrings.no_records_file.translate(context),
                    )
                  : voiceRecordsList(),
            ],
          ),
          bottomNavigationBar: const BottomNavBarWidget(),
        ),
      ),
    );
  }

  ListView voiceRecordsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _recordings.length,
      itemBuilder: (context, index) {
        final file = _recordings[index];
        final fileName = file.path.split('/').last.replaceAll('.m4a', '');
        final date = _formatJalaliDate(file.lastModifiedSync());

        return AnimatedSwitcher(
          duration: Duration(milliseconds: 350),
          transitionBuilder: (child, animation) =>
              SizeTransition(sizeFactor: animation, child: child),
          child: Card(
            key: ValueKey(file.path),
            elevation: 2,
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
                  color: Colors.blue,
                ),
                onPressed: () => _playPause(file),
              ),
              title: Text(fileName, style: AppTypography.voiceRecorderFilename),
              subtitle: Text(date, style: AppTypography.voiceRecorderDate),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    iconSize: AppSpacing.space_24,
                    icon: Icon(
                      Icons.edit,
                      color: Colors.orange,
                      size: AppSpacing.space_24,
                    ),
                    onPressed: () => _renameRecording(file),
                  ),
                  IconButton(
                    iconSize: AppSpacing.space_24,
                    icon: Icon(
                      Icons.delete_forever,
                      color: Colors.red,
                      size: AppSpacing.space_24,
                    ),
                    onPressed: () => _confirmDelete(file),
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
            final newPath = "$dir/$newName.m4a";
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
            "فایل حذف شد",
            style: AppTypography.voiceRecorderDeleteFileSnackBar,
          ),
          action: SnackBarAction(
            label: "UNDO",
            onPressed: () async {
              final restored = File(path);
              await restored.writeAsBytes(bytes);

              await _loadRecordings(); // 🔥 فوراً آیتم برمی‌گردد

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    "فایل برگردانده شد",
                    style: AppTypography.voiceRecorderRestoreFileSnackBar,
                  ),
                ),
              );
            },
          ),
        ),
      );
    }
  }

  Future<void> _confirmDelete(File file) async {
    final fileName = file.path.split('/').last.replaceAll('.m4a', '');

    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          "حذف ضبط",
          textAlign: TextAlign.center,
          style: AppTypography.voiceRecorderDeleteFileDialogueTitle,
        ),
        content: Text(
          "آیا از حذف فایل «$fileName» مطمئن هستید؟",
          textAlign: TextAlign.center,
          style: AppTypography.voiceRecorderDeleteFileDialogueContent,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              "خیر",
              style: AppTypography.voiceRecorderDeleteFileDialogueCancelButton,
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              "بله، حذف کن",
              style: AppTypography.voiceRecorderDeleteFileDialogueConfirmButton,
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      // 1) خواندن محتوا جهت امکان Undo
      final bytes = await file.readAsBytes();
      final originalPath = file.path;

      // 2) حذف فایل
      await _deleteRecording(file);

      // 3) Snackbar با دکمه Undo
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "فایل «$fileName» حذف شد",
            style: AppTypography.voiceRecorderDeleteFileMessageSnackBar,
          ),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: "Undo",
            textColor: Colors.yellow,
            onPressed: () async {
              // فایل را دوباره ایجاد می‌کنیم
              final restored = File(originalPath);
              await restored.writeAsBytes(bytes);

              // لیست را دوباره لود کن
              await _loadRecordings();
            },
          ),
        ),
      );
    }
  }

  Future<void> _renameRecording(File file) async {
    final oldName = file.path.split('/').last.replaceAll(".m4a", "");
    final controller = TextEditingController(text: oldName);

    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          "تغییر نام فایل",
          style: AppTypography.voiceRecorderRenameFileDialogueTitle,
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: "نام جدید",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: Text(
              "انصراف",
              style: AppTypography.voiceRecorderRenameFileDialogueCancelButton,
            ),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isEmpty) return;
              Navigator.pop(context, controller.text.trim());
            },
            child: Text(
              "ذخیره",
              style: AppTypography.voiceRecorderRenameFileDialogueConfirmButton,
            ),
          ),
        ],
      ),
    );

    if (newName == null) return;

    // مسیر جدید
    final dir = file.parent.path;
    final newPath = "$dir/$newName.m4a";

    try {
      await file.rename(newPath);
      await _loadRecordings();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "نام فایل به «$newName» تغییر کرد.",
            style: AppTypography.voiceRecorderRenameFileMessageSnackBar,
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "خطا در تغییر نام!",
            style: AppTypography.voiceRecorderRenameFileErrorMessageSnackBar,
          ),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  FloatingActionButton recordingButton() {
    return FloatingActionButton.large(
      heroTag: "main",
      backgroundColor: _isRecording ? Colors.red : AppColors.text_primary_light,
      onPressed: _isRecording ? _stopRecording : _startRecording,
      child: Icon(
        _isRecording ? Icons.stop : Icons.mic,
        size: 44,
        color: Colors.white,
      ),
    );
  }

  FloatingActionButton playPauseButton() {
    return FloatingActionButton(
      heroTag: "pause",
      backgroundColor: _isPaused ? Colors.orange : Colors.grey,
      onPressed: _isPaused ? _resumeRecording : _pauseRecording,
      child: Icon(_isPaused ? Icons.play_arrow : Icons.pause, size: 36),
    );
  }
}

class RecordingTimer extends StatelessWidget {
  const RecordingTimer({super.key, required String timerText})
    : _timerText = timerText;

  final String _timerText;

  @override
  Widget build(BuildContext context) {
    return Text(_timerText, style: AppTypography.voiceRecorderRecordingTimer);
  }
}
