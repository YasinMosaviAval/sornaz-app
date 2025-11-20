// ignore_for_file: use_build_context_synchronously

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sornaz/components/bottom_nav.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:sornaz/helpers/app_colors.dart';
import 'package:sornaz/helpers/app_data.dart';
import 'package:sornaz/helpers/app_spacing.dart';
import 'package:sornaz/helpers/app_strings.dart';
import 'dart:io';
import 'dart:async';

class MusicPlayerPage extends StatefulWidget {
  const MusicPlayerPage({super.key});

  @override
  State<MusicPlayerPage> createState() => _MusicPlayerPageState();
}

class AudioFile {
  final File file;
  final Duration duration;

  AudioFile(this.file, this.duration);

  String get fileName => file.path.split('/').last;
  String get folderName => file.parent.path;
  // String get folderName => file.parent.path.split('/').last;
}

class _MusicPlayerPageState extends State<MusicPlayerPage> {
  List<AudioFile> allAudioFiles = [];
  List<AudioFile> filteredAudioFiles = [];
  String searchQuery = '';

  final AudioPlayer _audioPlayer = AudioPlayer();

  int currentIndex = -1;
  bool isPlaying = false;
  Duration duration = Duration.zero;
  Duration position = Duration.zero;

  List<Duration> seekHistory = [];
  bool isInUndoMode = false;
  Timer? _resetUndoModeTimer;

  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _requestPermissionAndLoadFiles();

    _audioPlayer.onPlayerStateChanged.listen((state) {
      setState(() {
        isPlaying = state == PlayerState.playing;
        if (state == PlayerState.completed) {
          _playNext();
        }
      });
    });

    _audioPlayer.onDurationChanged.listen((d) {
      setState(() => duration = d);
    });

    // آپدیت موقعیت هر 500ms
    Timer.periodic(const Duration(milliseconds: 500), (_) async {
      if (mounted && isPlaying) {
        final p = await _audioPlayer.getCurrentPosition();
        if (mounted && p != null) {
          setState(() => position = p);
        }
      }
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _resetUndoModeTimer?.cancel();
    super.dispose();
  }

  // شروع تایمر 10 ثانیه‌ای برای ریست حالت undo
  void _startResetUndoModeTimer() {
    _resetUndoModeTimer?.cancel();
    _resetUndoModeTimer = Timer(const Duration(seconds: 10), () {
      if (mounted) {
        setState(() {
          isInUndoMode = false;
          seekHistory.clear();
        });
      }
    });
  }

  Future<void> _requestPermissionAndLoadFiles() async {
    var status = await Permission.storage.request();
    if (!status.isGranted) status = await Permission.audio.request();

    if (status.isGranted) {
      await _loadAudioFiles();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'لطفاً اجازه دسترسی به فایل‌های صوتی را در تنظیمات اپ بدهید',
          ),
        ),
      );
      openAppSettings();
    }
  }

  Future<void> _loadAudioFiles() async {
    setState(() => isLoading = true);

    try {
      final result = await FilePicker.platform.getDirectoryPath();
      if (result == null) {
        setState(() => isLoading = false);
        return;
      }

      final directory = Directory(result);
      final files = await directory.list(recursive: true).toList();

      List<AudioFile> audioFiles = [];

      for (var entity in files) {
        if (entity is File &&
            (entity.path.toLowerCase().endsWith('.mp3') ||
                entity.path.toLowerCase().endsWith('.wav') ||
                entity.path.toLowerCase().endsWith('.m4a'))) {
          final tempPlayer = AudioPlayer();
          await tempPlayer.setSource(DeviceFileSource(entity.path));
          final dur = await tempPlayer.getDuration() ?? Duration.zero;
          await tempPlayer.dispose();

          audioFiles.add(AudioFile(entity, dur));
        }
      }

      setState(() {
        allAudioFiles = audioFiles;
        filteredAudioFiles = audioFiles;
        isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('خطا در لود فایل‌ها: $e')));
      setState(() => isLoading = false);
    }
  }

  void _filterAudioFiles(String query) {
    setState(() {
      searchQuery = query;
      filteredAudioFiles = allAudioFiles
          .where(
            (audio) =>
                audio.file.path.toLowerCase().contains(query.toLowerCase()),
          )
          .toList();
    });
  }

  Future<void> _playAudio(int index) async {
    currentIndex = index;
    isInUndoMode = false;
    seekHistory.clear();
    _resetUndoModeTimer?.cancel();

    await _audioPlayer.play(
      DeviceFileSource(filteredAudioFiles[index].file.path),
    );
    setState(() => isPlaying = true);
  }

  Future<void> _pauseAudio() async {
    await _audioPlayer.pause();
    setState(() => isPlaying = false);
  }

  void _playNext() {
    if (currentIndex < filteredAudioFiles.length - 1) {
      _playAudio(currentIndex + 1);
    }
  }

  void _handlePreviousOrUndo() {
    if (isInUndoMode && seekHistory.isNotEmpty) {
      // undo مرحله به مرحله: pop آخرین موقعیت و seek به قبلی
      final previousPosition = seekHistory.removeLast();
      _audioPlayer.seek(previousPosition);

      // اگر history خالی شد، ریست حالت
      if (seekHistory.isEmpty) {
        setState(() {
          isInUndoMode = false;
        });
        _resetUndoModeTimer?.cancel();
      } else {
        // تایمر رو ری‌استارت کن برای فرصت دوباره 10 ثانیه
        _startResetUndoModeTimer();
      }
      setState(() {});
    } else {
      // رفتار عادی
      if (position > const Duration(seconds: 3)) {
        _audioPlayer.seek(Duration.zero);
      } else if (currentIndex > 0) {
        _playAudio(currentIndex - 1);
      }
    }
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(d.inMinutes.remainder(60));
    final seconds = twoDigits(d.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final appData = Provider.of<AppData>(context);
    final isDark = appData.isDark;
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: TextField(
          textDirection: TextDirection.ltr,
          onChanged: _filterAudioFiles,
          decoration: InputDecoration(
            hintText: AppStrings.music_player_searchbar_hint,
            hintTextDirection: TextDirection.ltr,
            prefixIcon: const Icon(Icons.search),
            border: InputBorder.none,
            fillColor: isDark
                ? AppColors.surface_dark
                : AppColors.surface_light,
            focusColor: isDark
                ? AppColors.clicked_dark
                : AppColors.clicked_light,
          ),
        ),
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          children: [
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : filteredAudioFiles.isEmpty
                  ? const Center(child: Text('بدون فایل صوتی یافت‌شده'))
                  : ListView.builder(
                      itemCount: filteredAudioFiles.length,
                      itemBuilder: (context, index) {
                        final audio = filteredAudioFiles[index];
                        final bool isCurrentlyPlaying = (index == currentIndex);
                        final durationText = audio.duration.inSeconds > 0
                            ? _formatDuration(audio.duration)
                            : '--:--';
                        return musicListItem(
                          isDark,
                          isCurrentlyPlaying,
                          audio,
                          durationText,
                          index,
                        );
                      },
                    ),
            ),

            if (currentIndex != -1) ...[
              Container(
                padding: const EdgeInsets.all(AppSpacing.space_16),
                color: isDark
                    ? AppColors.hovered_dark
                    : AppColors.hovered_light,
                child: Column(
                  children: [
                    /*
                    Text(
                      filteredAudioFiles[currentIndex].fileName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    */
                    SizedBox(
                      height: AppSpacing.space_24,
                      child: Row(
                        children: [
                          Text(_formatDuration(duration)),
                          Expanded(
                            child: Directionality(
                              textDirection: TextDirection.ltr,
                              child: Slider(
                                value: position.inSeconds.toDouble().clamp(
                                  0,
                                  duration.inSeconds.toDouble(),
                                ),
                                max: duration.inSeconds.toDouble() > 0
                                    ? duration.inSeconds.toDouble()
                                    : 1,
                                onChangeStart: (value) {
                                  if (seekHistory.isEmpty ||
                                      seekHistory.last != position) {
                                    seekHistory.add(position);
                                  }
                                  setState(() => isInUndoMode = true);
                                  _startResetUndoModeTimer();
                                },
                                onChanged: (value) {
                                  setState(() {
                                    position = Duration(seconds: value.toInt());
                                  });
                                },
                                onChangeEnd: (value) async {
                                  await _audioPlayer.seek(
                                    Duration(seconds: value.toInt()),
                                  );
                                  _startResetUndoModeTimer();
                                },
                              ),
                            ),
                          ),
                          Text(_formatDuration(position)),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: 36,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.skip_next),
                            iconSize: 36,
                            onPressed: _playNext,
                          ),
                          IconButton(
                            iconSize: 36,
                            icon: Icon(
                              isPlaying ? Icons.pause : Icons.play_arrow,
                            ),
                            onPressed: isPlaying
                                ? _pauseAudio
                                : () => _playAudio(currentIndex),
                          ),
                          IconButton(
                            icon: Icon(
                              isInUndoMode ? Icons.undo : Icons.skip_previous,
                            ),
                            iconSize: 36,
                            onPressed: _handlePreviousOrUndo,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      bottomNavigationBar: const BottomNavBarWidget(),
    );
  }

  Container musicListItem(
    bool isDark,
    bool isCurrentlyPlaying,
    AudioFile audio,
    String durationText,
    int index,
  ) {
    return Container(
      // اگر این فایل در حال پخش است → بک‌گراند رنگی
      decoration: BoxDecoration(
        border: Border.all(
          width: 0.8,
          color: isDark ? AppColors.border_dark : AppColors.border_light,
        ),
        color: isCurrentlyPlaying
            ? isDark
                  ? AppColors.clicked_dark
                  : AppColors.clicked_light
            : Colors.transparent,
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(
          horizontal: AppSpacing.space_24,
          vertical: AppSpacing.space_2,
        ),
        minTileHeight: AppSpacing.space_24,
        title: isCurrentlyPlaying
            ? MarqueeText(
                text: audio.fileName,
                textStyle: TextStyle(
                  fontSize: 14,
                  color: isDark
                      ? AppColors.text_primary_dark
                      : AppColors.text_primary_light,
                  fontWeight: FontWeight.w500,
                ),
              )
            : Text(
                audio.fileName,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                textDirection: TextDirection.ltr,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark
                      ? AppColors.text_primary_dark
                      : AppColors.text_primary_light,
                  fontWeight: isCurrentlyPlaying
                      ? FontWeight.w900
                      : FontWeight.normal,
                ),
              ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: AppSpacing.space_4),
            Row(
              children: [
                Text(
                  durationText,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? AppColors.text_secondary_dark
                        : AppColors.text_secondary_light,
                  ),
                ),
                SizedBox(width: AppSpacing.space_16),
                Expanded(
                  child: Text(
                    audio.folderName.substring(1),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    textDirection: TextDirection.ltr,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? AppColors.text_secondary_dark
                          : AppColors.text_secondary_light,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        onTap: () => _playAudio(index),
      ),
    );
  }
}

class MarqueeText extends StatefulWidget {
  final String text;
  final TextStyle textStyle;
  final double speed; // پیکسل در ثانیه
  final double gap; // فاصله بین انتها و شروع دوباره

  const MarqueeText({
    super.key,
    required this.text,
    required this.textStyle,
    this.speed = 60,
    this.gap = 50,
  });

  @override
  State<MarqueeText> createState() => _MarqueeTextState();
}

class _MarqueeTextState extends State<MarqueeText>
    with SingleTickerProviderStateMixin {
  late ScrollController _scrollController;
  late AnimationController _animationController;
  double _textWidth = 0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _animationController =
        AnimationController(vsync: this, duration: const Duration(seconds: 10))
          ..addListener(() {
            if (_scrollController.hasClients) {
              final maxScroll = _scrollController.position.maxScrollExtent;
              final position = _scrollController.offset;
              final newOffset = position + (widget.speed / 60); // 60fps

              if (maxScroll > 0 && newOffset >= maxScroll) {
                _scrollController.jumpTo(0);
              } else {
                _scrollController.jumpTo(newOffset);
              }
            }
          });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _startAnimationIfNeeded();
      }
    });
  }

  void _startAnimationIfNeeded() {
    if (!mounted) return;
    final renderBox = context.findRenderObject() as RenderBox?;
    final containerWidth = renderBox?.size.width ?? 0;

    final textPainter = TextPainter(
      text: TextSpan(text: widget.text, style: widget.textStyle),
      textDirection: TextDirection.ltr,
    )..layout();

    _textWidth = textPainter.width;

    if (_textWidth > containerWidth - widget.gap) {
      _animationController.repeat();
    }
  }

  @override
  void didUpdateWidget(MarqueeText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text ||
        oldWidget.textStyle != widget.textStyle) {
      _scrollController.jumpTo(0);
      _startAnimationIfNeeded();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SizedBox(
          // height: 20,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            controller: _scrollController,
            physics: const NeverScrollableScrollPhysics(),
            child: Row(
              children: [
                Text(
                  widget.text,
                  textDirection: TextDirection.ltr,
                  style: widget.textStyle,
                ),
                SizedBox(width: widget.gap),
                if (_textWidth > constraints.maxWidth) ...{
                  Text(widget.text, style: widget.textStyle),
                },
              ],
            ),
          ),
        );
      },
    );
  }
}
