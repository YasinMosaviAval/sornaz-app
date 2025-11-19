// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:sornaz/components/bottom_nav.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:file_picker/file_picker.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:io';
import 'dart:async';

class MusicPlayerPage extends StatefulWidget {
  const MusicPlayerPage({super.key});

  @override
  State<MusicPlayerPage> createState() => _MusicPlayerPageState();
}

class _MusicPlayerPageState extends State<MusicPlayerPage> {
  List<File> allAudioFiles = [];
  List<File> filteredAudioFiles = [];
  String searchQuery = '';
  final AudioPlayer _audioPlayer = AudioPlayer();
  int currentIndex = -1;
  bool isPlaying = false;
  Duration duration = Duration.zero;
  Duration position = Duration.zero;
  Timer? _positionTimer;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _requestPermissionAndLoadFiles();
    _audioPlayer.onPlayerStateChanged.listen((state) {
      setState(() {
        isPlaying = state == PlayerState.playing;
        if (state == PlayerState.completed) {
          _playNext(); // پخش بعدی وقتی تمام شد
        }
      });
    });
    _audioPlayer.onDurationChanged.listen((d) {
      setState(() {
        duration = d;
      });
    });
    // تایمر برای آپدیت position هر ثانیه
    _positionTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (isPlaying) {
        _audioPlayer.onPositionChanged.listen((p) {
          setState(() {
            position = p;
          });
        });
      }
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _positionTimer?.cancel();
    super.dispose();
  }

  // درخواست مجوز و لود فایل‌ها
  Future<void> _requestPermissionAndLoadFiles() async {
    var status = await Permission.audio.request();
    if (status.isGranted) {
      await _loadAudioFiles();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('اجازه دسترسی به فایل‌ها لازم است')),
      );
    }
  }

  // لود فایل‌های صوتی از حافظه (mp3, wav, m4a)
  Future<void> _loadAudioFiles() async {
    setState(() {
      isLoading = true;
    });
    try {
      final result = await FilePicker.platform.getDirectoryPath();
      if (result != null) {
        final directory = Directory(result);
        final files = await directory.list(recursive: true).toList();
        allAudioFiles = files
            .where(
              (file) =>
                  file is File &&
                  (file.path.endsWith('.mp3') ||
                      file.path.endsWith('.wav') ||
                      file.path.endsWith('.m4a')),
            )
            .cast<File>()
            .toList();
        filteredAudioFiles = allAudioFiles;
        setState(() {});
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('خطا در لود فایل‌ها: $e')));
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // فیلتر جستجو
  void _filterAudioFiles(String query) {
    setState(() {
      searchQuery = query;
      filteredAudioFiles = allAudioFiles
          .where(
            (file) => file.path.toLowerCase().contains(query.toLowerCase()),
          )
          .toList();
    });
  }

  // پخش فایل
  Future<void> _playAudio(int index) async {
    currentIndex = index;
    await _audioPlayer.play(DeviceFileSource(filteredAudioFiles[index].path));
    setState(() {
      isPlaying = true;
    });
  }

  // مکث
  Future<void> _pauseAudio() async {
    await _audioPlayer.pause();
    setState(() {
      isPlaying = false;
    });
  }

  // بعدی
  void _playNext() {
    if (currentIndex < filteredAudioFiles.length - 1) {
      _playAudio(currentIndex + 1);
    }
  }

  // قبلی
  void _playPrevious() {
    if (currentIndex > 0) {
      _playAudio(currentIndex - 1);
    }
  }

  // seek
  Future<void> _seek(Duration position) async {
    await _audioPlayer.seek(position);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('موزیک پلیر')),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          children: [
            // سرچ بار
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                onChanged: _filterAudioFiles,
                decoration: InputDecoration(
                  hintText: 'جستجو در فایل‌ها...',
                  suffixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : filteredAudioFiles.isEmpty
                  ? const Center(child: Text('بدون فایل صوتی یافت‌شده'))
                  : ListView.builder(
                      itemCount: filteredAudioFiles.length,
                      itemBuilder: (context, index) {
                        final file = filteredAudioFiles[index];
                        return ListTile(
                          title: Text(file.path.split('/').last),
                          trailing: IconButton(
                            icon: const Icon(Icons.play_arrow),
                            onPressed: () => _playAudio(index),
                          ),
                          onTap: () => _playAudio(index),
                        );
                      },
                    ),
            ),
            // پخش‌کننده پایین
            if (currentIndex != -1)
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.grey[200],
                child: Column(
                  children: [
                    Text(filteredAudioFiles[currentIndex].path.split('/').last),
                    Slider(
                      value: position.inSeconds.toDouble(),
                      max: duration.inSeconds.toDouble(),
                      onChanged: (value) =>
                          _seek(Duration(seconds: value.toInt())),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.skip_previous),
                          onPressed: _playPrevious,
                        ),
                        IconButton(
                          icon: Icon(
                            isPlaying ? Icons.pause : Icons.play_arrow,
                          ),
                          onPressed: isPlaying
                              ? _pauseAudio
                              : () => _playAudio(currentIndex),
                        ),
                        IconButton(
                          icon: const Icon(Icons.skip_next),
                          onPressed: _playNext,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNavBarWidget(),
    );
  }
}
