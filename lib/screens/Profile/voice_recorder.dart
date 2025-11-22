import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shamsi_date/shamsi_date.dart';
import 'package:sornaz/components/bottom_nav.dart';
import 'package:sornaz/helpers/app_colors.dart';
import 'package:sornaz/helpers/app_data.dart';

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

  // برای نمودار شدت صوت زنده
  List<double> _amplitudes = [];
  StreamSubscription? _amplitudeSubscription;

  double? _lastDB; // آخرین مقدار دسی‌بل دریافتی

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
          const SnackBar(
            content: Text('اجازه دسترسی به میکروفون و حافظه لازم است'),
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

  /*
  Future<void> _startRecording() async {
    if (await _recorder.hasPermission()) {
      final dir = await getApplicationDocumentsDirectory();
      _currentFilePath =
          '${dir.path}/Recordings/${DateTime.now().toString().replaceAll('-', '').replaceAll(':', '').replaceAll(' ', '').substring(0, 14)}.m4a';

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
      });
      _startTimer();

      // دریافت شدت صوت زنده
      _amplitudeSubscription?.cancel();
      _amplitudeSubscription = _recorder
          .onAmplitudeChanged(const Duration(milliseconds: 80))
          .listen((amp) {
            if (mounted && _isRecording && !_isPaused) {
              setState(() {
                final normalized = (-amp.current + 60).abs() / 60; // 0 تا 1
                _amplitudes.add(normalized.clamp(0.0, 1.0));
                if (_amplitudes.length > 120) _amplitudes.removeAt(0);
              });
            }
          });
    }
  }
*/
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

  /*
  Future<void> _startRecording() async {
    if (await _recorder.hasPermission()) {
      final dir = await getApplicationDocumentsDirectory();
      _currentFilePath =
          '${dir.path}/Recordings/ضبط_${DateTime.now().millisecondsSinceEpoch}.m4a';

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
      });
      _startTimer();

      // دریافت شدت صدا هر 10 میلی‌ثانیه
      _amplitudeSubscription?.cancel();
      _amplitudeSubscription = _recorder
          .onAmplitudeChanged(const Duration(milliseconds: 10))
          .listen((amp) {
            if (!mounted || !_isRecording || _isPaused) return;

            setState(() {
              // تبدیل دسی‌بل به مقدار 0-1 (دقیق و روان)
              final db = amp.current; // دسی‌بل (معمولاً بین -60 تا 0)
              final normalized = db < -60 ? 0.0 : (db + 60) / 60; // 0 تا 1

              _amplitudes.add(normalized);

              // حداکثر 300 نقطه (برای 3 ثانیه نمایش)
              if (_amplitudes.length > 300) {
                _amplitudes.removeAt(0);
              }
            });
          });
    }
  }
*/
  Future<void> _startRecording() async {
    if (await _recorder.hasPermission()) {
      final dir = await getApplicationDocumentsDirectory();
      _currentFilePath =
          '${dir.path}/Recordings/ضبط_${DateTime.now().millisecondsSinceEpoch}.m4a';

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
    return DefaultTabController(
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
                // const SizedBox(height: 40),
                Text(
                  _timerText,
                  style: const TextStyle(
                    fontSize: 56,
                    fontWeight: FontWeight.bold,
                    color: AppColors.text_primary_light,
                  ),
                ),
                // const SizedBox(height: 30),

                // نمودار شدت صوت زنده
                Container(
                  height: 250,
                  // width: double.infinity,
                  // margin: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.background_dark
                        : AppColors.background_light,
                    // borderRadius: BorderRadius.circular(4),
                    border: Border.symmetric(
                      horizontal: BorderSide(
                        width: 1,
                        color: AppColors.border_light,
                      ),
                    ),
                  ),
                  child: ClipRRect(
                    // borderRadius: BorderRadius.circular(24),
                    child: CustomPaint(
                      painter: WaveformPainter(
                        _amplitudes,
                        _isRecording && !_isPaused,
                      ),
                      size: Size.infinite,
                    ),
                  ),
                ),

                // جایگزین کامل قسمت CustomPaint در Tab 1
                Container(
                  height: 180,
                  margin: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.grey.shade300, width: 1),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Row(
                      children: [
                        // نمودار اصلی موج صوتی
                        Expanded(
                          child: CustomPaint(
                            painter: AdvancedWaveformPainter(
                              amplitudes: _amplitudes,
                              isActive: _isRecording && !_isPaused,
                              recordingSeconds: _seconds,
                            ),
                            size: Size.infinite,
                          ),
                        ),

                        // متر دسی‌بل در سمت راست
                        Container(
                          width: 80,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: CustomPaint(
                            painter: DBMeterPainter(
                              currentDB: _lastDB ?? -60,
                              isActive: _isRecording && !_isPaused,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // const SizedBox(height: 50),

                // دکمه‌های کنترل
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_isRecording)
                      FloatingActionButton(
                        heroTag: "pause",
                        backgroundColor: _isPaused
                            ? Colors.orange
                            : Colors.grey,
                        onPressed: _isPaused
                            ? _resumeRecording
                            : _pauseRecording,
                        child: Icon(
                          _isPaused ? Icons.play_arrow : Icons.pause,
                          size: 36,
                        ),
                      ),
                    const SizedBox(width: 30),
                    // دکمه اصلی (شروع / توقف)
                    FloatingActionButton.large(
                      heroTag: "main",
                      backgroundColor: _isRecording
                          ? Colors.red
                          : AppColors.text_primary_light,
                      onPressed: _isRecording
                          ? _stopRecording
                          : _startRecording,
                      child: Icon(
                        _isRecording ? Icons.stop : Icons.mic,
                        size: 44,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // TAB 2: لیست فایل‌ها
            _recordings.isEmpty
                ? const Center(
                    child: Text(
                      'هیچ ضبطی انجام نشده',
                      style: TextStyle(fontSize: 20, color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _recordings.length,
                    itemBuilder: (context, index) {
                      final file = _recordings[index];
                      final fileName = file.path
                          .split('/')
                          .last
                          .replaceAll('.m4a', '');
                      final date = _formatJalaliDate(file.lastModifiedSync());

                      return Card(
                        elevation: 3,
                        child: ListTile(
                          leading: IconButton(
                            iconSize: 50,
                            icon: Icon(
                              _currentlyPlayingPath == file.path && _isPlaying
                                  ? Icons.pause_circle_filled
                                  : Icons.play_circle_fill,
                              color: Colors.blue,
                            ),
                            onPressed: () => _playPause(file),
                          ),
                          title: Text(
                            fileName,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(date),
                          trailing: IconButton(
                            icon: const Icon(
                              Icons.delete_forever,
                              color: Colors.red,
                            ),
                            onPressed: () => _deleteRecording(file),
                          ),
                        ),
                      );
                    },
                  ),
          ],
        ),
        bottomNavigationBar: const BottomNavBarWidget(),
      ),
    );
  }
}

class WaveformPainter extends CustomPainter {
  final List<double> amplitudes;
  final bool isActive;

  WaveformPainter(this.amplitudes, this.isActive);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isActive ? const Color(0xFF00E676) : Colors.grey.shade400
      ..strokeWidth = 0.8
      // ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    if (amplitudes.isEmpty) {
      final centerY = size.height / 2;
      canvas.drawLine(
        Offset(0, centerY),
        Offset(size.width, centerY),
        paint..color = Colors.grey.shade300,
      );
      return;
    }

    final double barWidth = size.width / 200;
    final double centerY = size.height / 2;
    final int startIndex = 0;
    // final int startIndex = amplitudes.length > 300 ? 200 : 0;

    for (int i = startIndex; i < amplitudes.length; i++) {
      final double amplitude = amplitudes[i];
      final double height = amplitude * size.height * 2;
      final double x = (i - startIndex) * barWidth;

      canvas.drawLine(
        Offset(x, centerY - height / 5),
        Offset(x, centerY + height / 5),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class AdvancedWaveformPainter extends CustomPainter {
  final List<double> amplitudes;
  final bool isActive;
  final int recordingSeconds;

  AdvancedWaveformPainter({
    required this.amplitudes,
    required this.isActive,
    required this.recordingSeconds,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final wavePaint = Paint()
      ..color = isActive ? const Color(0xFF00E676) : Colors.grey.shade400
      ..strokeWidth = 2.8
      ..strokeCap = StrokeCap.round;

    final gridPaint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 1;

    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    final centerY = size.height / 2;

    // رسم خط‌کشی زمان
    const int samplesPerSecond = 100; // 10ms = 100 نمونه در ثانیه
    final int totalSamples = recordingSeconds * samplesPerSecond;
    final double pxPerSample = size.width / 400; // 400 نمونه نمایش داده میشه

    // خطوط عمودی هر 250ms (4 تا در ثانیه)
    for (int i = 0; i <= recordingSeconds * 4; i++) {
      final double x = (i * 25) * pxPerSample; // هر 25 نمونه = 250ms
      if (x > size.width) break;

      if (i % 4 == 0) {
        // خط اصلی هر ثانیه
        canvas.drawLine(
          Offset(x, 0),
          Offset(x, size.height),
          gridPaint..strokeWidth = 1.5,
        );

        // عدد ثانیه
        final seconds = i ~/ 4;
        textPainter.text = TextSpan(
          text: '$seconds',
          style: const TextStyle(color: Colors.grey, fontSize: 11),
        );
        textPainter.layout();
        textPainter.paint(canvas, Offset(x - 8, 8));
      } else {
        // خطوط فرعی
        canvas.drawLine(
          Offset(x, centerY - 10),
          Offset(x, centerY + 10),
          gridPaint,
        );
      }
    }

    // رسم موج صوتی
    if (amplitudes.isEmpty) return;

    final int startIndex = amplitudes.length > 400
        ? amplitudes.length - 400
        : 0;

    for (int i = startIndex; i < amplitudes.length; i++) {
      final double amplitude = amplitudes[i];
      final double height = amplitude * size.height * 0.9;
      final double x = (i - startIndex) * pxPerSample;

      canvas.drawLine(
        Offset(x, centerY - height / 2),
        Offset(x, centerY + height / 2),
        wavePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => true;
}

class DBMeterPainter extends CustomPainter {
  final double currentDB;
  final bool isActive;

  DBMeterPainter({required this.currentDB, required this.isActive});

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;

    // پس‌زمینه
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(8, 16, size.width - 16, size.height - 32),
        const Radius.circular(12),
      ),
      Paint()..color = Colors.black.withOpacity(0.1),
    );

    // مقیاس دسی‌بل
    final labels = ['-60', '-40', '-20', '-10', '0'];
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    for (int i = 0; i < labels.length; i++) {
      final double y = 20 + (i * (size.height - 40) / 4);
      textPainter.text = TextSpan(
        text: labels[i],
        style: TextStyle(color: Colors.grey.shade600, fontSize: 10),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(4, y - 8));
    }

    // نشانگر فعلی
    final double normalized = (currentDB + 60) / 60; // 0 تا 1
    final double barHeight = (size.height - 40) * normalized;
    final double barY = size.height - 20 - barHeight;

    final Color barColor = currentDB > -10
        ? Colors.red
        : currentDB > -20
        ? Colors.orange
        : Colors.green;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(16, barY, size.width - 32, barHeight),
        const Radius.circular(8),
      ),
      Paint()..color = barColor.withOpacity(isActive ? 0.9 : 0.4),
    );

    // عدد فعلی
    if (isActive) {
      textPainter.text = TextSpan(
        text: '${currentDB.toStringAsFixed(1)} dB',
        style: const TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(centerX - textPainter.width / 2, size.height - 50),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => true;
}

/*
import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shamsi_date/shamsi_date.dart';
import 'package:sornaz/components/bottom_nav.dart';
import 'package:sornaz/helpers/app_colors.dart';
import 'package:sornaz/helpers/app_spacing.dart';

class VoiceRecorderPage extends StatefulWidget {
  const VoiceRecorderPage({super.key});
  @override
  State<VoiceRecorderPage> createState() => _VoiceRecorderPageState();
}

class _VoiceRecorderPageState extends State<VoiceRecorderPage> {
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();

  bool _isRecording = false;
  bool _isPlaying = false;
  String _timerText = '00:00';
  int _seconds = 0;
  Timer? _timer;
  List<File> _recordings = [];
  String? _currentlyPlayingPath;

  List<double> amplitudes = [];

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
          const SnackBar(
            content: Text('اجازه دسترسی به میکروفون و حافظه لازم است'),
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

    if (mounted) {
      setState(() => _recordings = files.cast<File>());
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _seconds = 0;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isRecording) {
        timer.cancel();
        return;
      }
      setState(() {
        _seconds++;
        final m = _seconds ~/ 60;
        final s = _seconds % 60;
        _timerText =
            '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
      });
    });
  }

  Future<void> _startRecording() async {
    if (await _recorder.hasPermission()) {
      final dir = await getApplicationDocumentsDirectory();
      final filePath =
          '${dir.path}/Recordings/${DateTime.now().toString().replaceAll('-', '').replaceAll(' ', '').replaceAll(':', '').substring(0, 14)}.m4a';

      await _recorder.start(const RecordConfig(), path: filePath);
      setState(() => _isRecording = true);
      _startTimer();
    }
  }

  Future<void> _stopRecording() async {
    final path = await _recorder.stop();
    _timer?.cancel();
    setState(() {
      _isRecording = false;
      _timerText = '00:00';
    });
    if (path != null) {
      await _loadRecordings();
    }
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

  // تابع تبدیل تاریخ میلادی به شمسی
  String _formatJalaliDate(DateTime date) {
    final jalali = Jalali.fromDateTime(date);
    return '${jalali.year}/${jalali.month.toString().padLeft(2, '0')}/${jalali.day.toString().padLeft(2, '0')} - ${jalali.hour.toString().padLeft(2, '0')}:${jalali.minute.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _timer?.cancel();
    _recorder.dispose();
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
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
            tabs: [
              Tab(
                icon: Icon(Icons.mic, size: AppSpacing.space_32),
                height: AppSpacing.space_56,
              ),
              Tab(
                icon: Icon(Icons.list, size: AppSpacing.space_32),
                height: AppSpacing.space_56,
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            /// ---------------- TAB 1 : Recorder ----------------
            Column(
              children: [
                SizedBox(height: AppSpacing.space_32),
                Text(
                  _timerText,
                  style: const TextStyle(
                    color: AppColors.text_primary_light,
                    fontSize: 32,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 1,
                  ),
                ),
                SizedBox(height: AppSpacing.space_24),
                SizedBox(height: AppSpacing.space_24),
                SizedBox(
                  height: 60,
                  width: 60,
                  child: FloatingActionButton(
                    backgroundColor: _isRecording
                        ? AppColors.background_light
                        : AppColors.error,
                    elevation: 1,
                    splashColor: AppColors.surface_light,
                    onPressed: _isRecording ? _stopRecording : _startRecording,
                    foregroundColor: AppColors.text_primary_light,
                    child: Icon(
                      _isRecording ? Icons.stop : Icons.mic,
                      size: AppSpacing.space_32,
                    ),
                  ),
                ),
              ],
            ),

            /// ---------------- TAB 2 : Recordings List ----------------
            _recordings.isEmpty
                ? const Center(
                    child: Text(
                      'هیچ ضبطی انجام نشده',
                      style: TextStyle(fontSize: 20, color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _recordings.length,
                    itemBuilder: (context, index) {
                      final file = _recordings[index];
                      final fileName = file.path.substring(55);
                      // .split('/')
                      // .last
                      // .replaceAll('.m4a', '');
                      final modifiedDate = file.lastModifiedSync();
                      final jalaliDate = _formatJalaliDate(modifiedDate);

                      return Card(
                        elevation: 2,
                        child: ListTile(
                          leading: IconButton(
                            iconSize: 48,
                            icon: Icon(
                              _currentlyPlayingPath == file.path && _isPlaying
                                  ? Icons.pause_circle_filled
                                  : Icons.play_circle_fill,
                              color: Colors.blue,
                            ),
                            onPressed: () => _playPause(file),
                          ),
                          title: Text(
                            fileName,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(jalaliDate),
                          trailing: IconButton(
                            icon: const Icon(
                              Icons.delete_forever,
                              color: Colors.red,
                            ),
                            onPressed: () => _deleteRecording(file),
                          ),
                        ),
                      );
                    },
                  ),
          ],
        ),
        bottomNavigationBar: BottomNavBarWidget(),
      ),
    );
  }
}
*/
