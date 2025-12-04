// ignore_for_file: use_build_context_synchronously, non_constant_identifier_names

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sornaz/classes/audio_file.dart';
import 'package:sornaz/components/bottom_nav.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:sornaz/components/marquee_text.dart';
import 'package:sornaz/helpers/app_colors.dart';
import 'package:sornaz/helpers/app_data.dart';
import 'package:sornaz/helpers/app_locale_provider.dart';
import 'package:sornaz/helpers/app_spacing.dart';
import 'package:sornaz/helpers/app_strings.dart';
import 'dart:io';
import 'dart:async';

import 'package:sornaz/helpers/app_translations.dart';
import 'package:sornaz/helpers/app_typography.dart';

class MusicPlayerPage extends StatefulWidget {
  const MusicPlayerPage({super.key});

  @override
  State<MusicPlayerPage> createState() => _MusicPlayerPageState();
}

class _MusicPlayerPageState extends State<MusicPlayerPage> {
  List<AudioFile> allAudioFiles = [];
  List<AudioFile> filteredAudioFiles = [];
  String searchQuery = AppStrings.epmty_text;

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
        SnackBar(
          content: Text(
            AppStrings.grant_audio_permission.translate(context),
            style: AppTypography.musicPlayerNotGrantedPermissionSnackBar(
              context,
            ),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${AppStrings.error_in_loading.translate(context)}: $e',
            style: AppTypography.musicPlayerErrorInLoadingSnackBar(context),
          ),
        ),
      );
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
      final previousPosition = seekHistory.removeLast();
      _audioPlayer.seek(previousPosition);

      if (seekHistory.isEmpty) {
        setState(() {
          isInUndoMode = false;
        });
        _resetUndoModeTimer?.cancel();
      } else {
        _startResetUndoModeTimer();
      }
      setState(() {});
    } else {
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
    final localeProvider = Provider.of<LocaleProvider>(context, listen: false);
    // final theme = Theme.of(context);
    final bool isEnglish = localeProvider.locale.languageCode == 'en';

    return Directionality(
      textDirection: isEnglish ? TextDirection.ltr : TextDirection.rtl,
      child: Scaffold(
        backgroundColor: isDark
            ? AppColors.background_dark
            : AppColors.background_light,
        appBar: appBarSearchBox(isDark),
        body: Directionality(
          textDirection: TextDirection.rtl,
          child: Column(
            children: [
              showAudioFileList(isDark),
              if (currentIndex != -1) ...[audioWidget(isDark)],
            ],
          ),
        ),
        bottomNavigationBar: const BottomNavBarWidget(),
      ),
    );
  }

  Container audioWidget(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space_16),
      color: isDark ? AppColors.hovered_dark : AppColors.hovered_light,
      child: Column(
        children: [AudioWidgetTimesAndSlider(), audioWidgetButtons()],
      ),
    );
  }

  AppBar appBarSearchBox(bool isDark) {
    return AppBar(
      elevation: 0,
      automaticallyImplyLeading: false,
      title: TextField(
        textDirection: TextDirection.ltr,
        onChanged: _filterAudioFiles,
        decoration: InputDecoration(
          hintText: AppStrings.music_player_search_hint.translate(context),
          hintTextDirection: TextDirection.ltr,
          prefixIcon: const Icon(Icons.search),
          border: InputBorder.none,
          fillColor: isDark ? AppColors.surface_dark : AppColors.surface_light,
          focusColor: isDark ? AppColors.clicked_dark : AppColors.clicked_light,
        ),
      ),
      backgroundColor: isDark
          ? AppColors.surface_dark
          : AppColors.surface_light,
      iconTheme: IconThemeData(
        color: isDark
            ? AppColors.text_primary_dark
            : AppColors.text_primary_light,
      ),
    );
  }

  SizedBox AudioWidgetTimesAndSlider() {
    return SizedBox(
      height: AppSpacing.space_24,
      child: Row(
        children: [
          Text(
            _formatDuration(duration),
            style: AppTypography.musicPlayerAudioWidgetDurationTime(context),
          ),
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
                  if (seekHistory.isEmpty || seekHistory.last != position) {
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
                  await _audioPlayer.seek(Duration(seconds: value.toInt()));
                  _startResetUndoModeTimer();
                },
              ),
            ),
          ),
          Text(
            _formatDuration(position),
            style: AppTypography.musicPlayerAudioWidgetPositionTime(context),
          ),
        ],
      ),
    );
  }

  SizedBox audioWidgetButtons() {
    return SizedBox(
      height: AppSpacing.space_36,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            icon: const Icon(Icons.skip_next),
            iconSize: AppSpacing.space_36,
            onPressed: _playNext,
          ),
          IconButton(
            iconSize: AppSpacing.space_36,
            icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
            onPressed: isPlaying ? _pauseAudio : () => _playAudio(currentIndex),
          ),
          IconButton(
            icon: Icon(isInUndoMode ? Icons.undo : Icons.skip_previous),
            iconSize: AppSpacing.space_36,
            onPressed: _handlePreviousOrUndo,
          ),
        ],
      ),
    );
  }

  Expanded showAudioFileList(bool isDark) {
    return Expanded(
      child: isLoading
          ? const Center(child: CircularProgressIndicator())
          : filteredAudioFiles.isEmpty
          ? Center(
              child: Text(
                AppStrings.audio_file_not_found.translate(context),
                style: AppTypography.musicPlayerAudioFileNotFound(context),
              ),
            )
          : ListView.builder(
              itemCount: filteredAudioFiles.length,
              itemBuilder: (context, index) {
                final audio = filteredAudioFiles[index];
                final bool isCurrentlyPlaying = (index == currentIndex);
                final durationText = audio.duration.inSeconds > 0
                    ? _formatDuration(audio.duration)
                    : AppStrings.empty_duration_time;
                return musicListItem(
                  isDark,
                  isCurrentlyPlaying,
                  audio,
                  durationText,
                  index,
                );
              },
            ),
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
                textStyle: AppTypography.musicPlayerPlayingAudioFile(context),
              )
            : Text(
                audio.fileName,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                textDirection: TextDirection.ltr,
                style: AppTypography.musicPlayerNotPlayingAudioFile(context),
              ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: AppSpacing.space_4),
            Row(
              children: [
                Text(
                  durationText,
                  style: AppTypography.musicPlayerAudioItemDurationTime(
                    context,
                  ),
                ),
                SizedBox(width: AppSpacing.space_16),
                Expanded(
                  child: Text(
                    audio.folderName.substring(1),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    textDirection: TextDirection.ltr,
                    style: AppTypography.musicPlayerAudioItemAddress(context),
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
