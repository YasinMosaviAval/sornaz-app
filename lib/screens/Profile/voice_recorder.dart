/*
import 'package:flutter/material.dart';
import 'package:sornaz/components/bottom_nav.dart';
import 'package:sornaz/helpers/app_strings.dart';

class VoiceRecorderPage extends StatelessWidget {
  const VoiceRecorderPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.voiceRecorderTitle)),
      body: Text(AppStrings.voiceRecorderTitle),
      bottomNavigationBar: const BottomNavBarWidget(),
    );
  }
}
*/

import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shamsi_date/shamsi_date.dart';
import 'package:sornaz/components/bottom_nav.dart';

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
          '${dir.path}/Recordings/ضبط_${DateTime.now().millisecondsSinceEpoch}.m4a';

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
    return Scaffold(
      /*
      appBar: AppBar(
        title: const Text('ضبط صدا'),
        automaticallyImplyLeading: false,
      ),
      */
      body: Column(
        children: [
          SizedBox(height: 100),
          Expanded(
            flex: 3,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _timerText,
                    style: const TextStyle(
                      fontSize: 60,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 50),
                  FloatingActionButton.large(
                    backgroundColor: _isRecording ? Colors.red : Colors.blue,
                    onPressed: _isRecording ? _stopRecording : _startRecording,
                    child: Icon(
                      _isRecording ? Icons.stop : Icons.mic,
                      size: 50,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            flex: 3,
            child: _recordings.isEmpty
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
          ),
        ],
      ),
      bottomNavigationBar: const BottomNavBarWidget(),
    );
  }
}
