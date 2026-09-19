import 'package:sornaz/components/app_top_bar_direction.dart';
import '../components/seekable_waveform.dart';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:just_waveform/just_waveform.dart';
import 'package:sornaz/components/ab_repeat.dart';
import 'package:sornaz/helpers/app_functions.dart';
import 'package:sornaz/helpers/app_platform.dart';
import '../../provider/voice_recorder_provider.dart';
import '../../services/file_service.dart';
import '../components/basic_waveform.dart';

class RecordingPlaybackPage extends StatefulWidget {
  const RecordingPlaybackPage({super.key, required this.file});
  final SavedRecording file;
  @override
  State<RecordingPlaybackPage> createState() => _RecordingPlaybackPageState();
}

class _RecordingPlaybackPageState extends State<RecordingPlaybackPage> {
  bool showBookmarks = false;
  List<int> samples = [];
  Map<int, String> names = {};
  String? error;
  File? temporary, wave;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => load());
  }

  Future<void> load() async {
    final vm = context.read<VoiceRecorderProvider>();
    try {
      if (vm.playbackService.currentPath != widget.file.uri ||
          !vm.playbackService.isPlaying)
        await vm.playSaved(widget.file);
      if (temporary != null && await temporary!.exists())
        await temporary!.delete();
      if (wave != null && await wave!.exists()) await wave!.delete();
      names.clear();
      for (final t in vm.playbackBookmarks) {
        names[t] = await vm.fileService.bookmarks.name(widget.file.uri, t);
      }
      final path = await vm.fileService.materialize(widget.file);
      temporary = widget.file.isPublic ? File(path) : null;
      wave = File('$path.waveform');
      final result = await JustWaveform.extract(
        audioInFile: File(path),
        waveOutFile: wave!,
      ).last;
      if (mounted)
        setState(() {
          samples = result.waveform?.data ?? [];
          error = null;
        });
    } catch (_) {
      if (mounted) setState(() => error = 'نمایش موج صدا ممکن نشد.');
    }
  }

  Future<void> action(Future<void> Function() callback) async {
    try {
      await callback();
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('عملیات صوت انجام نشد.')));
    }
  }

  @override
  void dispose() {
    temporary?.delete().catchError((_) => temporary!);
    wave?.delete().catchError((_) => wave!);
    super.dispose();
  }

  Future<void> rename(int at) async {
    final input = TextEditingController(text: names[at] ?? '');
    final name = await showDialog<String>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('نام نشانه'),
        content: TextField(controller: input, maxLength: 100),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, input.text),
            child: const Text('ذخیره'),
          ),
        ],
      ),
    );
    input.dispose();
    if (name != null && mounted)
      await action(() async {
        await context
            .read<VoiceRecorderProvider>()
            .fileService
            .bookmarks
            .rename(widget.file.uri, at, name);
        if (mounted) setState(() => names[at] = name);
      });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<VoiceRecorderProvider>(),
        player = vm.playbackService;
    final markers = vm.playbackBookmarks;
    final previous = markers
        .where((t) => t <= player.position.inMilliseconds)
        .lastOrNull;
    final recording =
        vm.overwriteTarget != null && (vm.isRecording || vm.isPaused);
    return PopScope(
      canPop: !recording,
      child: Scaffold(
        appBar: AppTopBarDirection(
          child: AppBar(
            title: Text(widget.file.name, style: const TextStyle(fontSize: 14)),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SizedBox(
              height: 250,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: recording
                    ? BasicWaveformWidget(
                        amplitudes: vm.amplitudes,
                        totalSamples: vm.totalSamples,
                        isRecording: vm.isRecording,
                        isPaused: vm.isPaused,
                        bookmarks: vm.recordingBookmarks,
                        elapsedMilliseconds: vm.recordingMilliseconds,
                      )
                    : showBookmarks
                    ? ListView(
                        key: const ValueKey('bookmarks'),
                        children: [
                          if (markers.isEmpty)
                            const Center(
                              child: Text('هنوز نشانه‌ای اضافه نشده است.'),
                            ),
                          for (final at in markers)
                            ListTile(
                              selected: previous == at,
                              selectedTileColor: Theme.of(
                                context,
                              ).colorScheme.primary.withValues(alpha: .12),
                              leading: Text(formatSeconds(at ~/ 1000)),
                              title: Text(
                                names[at]?.isNotEmpty == true
                                    ? names[at]!
                                    : 'نشانه',
                              ),
                              onTap: () => action(
                                () => vm.seekBookmark(widget.file, at),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined),
                                    onPressed: () => rename(at),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline),
                                    onPressed: () => action(
                                      () => vm.removeBookmark(
                                        widget.file.uri,
                                        at,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      )
                    : SeekableWaveform(
                        key: const ValueKey('wave'),
                        samples: samples.map((v) => v / 32768).toList(),
                        duration: player.duration.inMilliseconds,
                        position: player.position.inMilliseconds,
                        markers: markers,
                        onSeek: (at) => player.seek(Duration(milliseconds: at)),
                      ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  onPressed: recording
                      ? (vm.canBookmarkRecording
                            ? () => action(vm.addRecordingBookmark)
                            : null)
                      : (vm.canBookmarkPlayback
                            ? () => action(
                                () => vm.addPlaybackBookmark(widget.file),
                              )
                            : null),
                  icon: const Icon(Icons.bookmark_add_outlined),
                  label: const Text('نشانه‌گذاری'),
                ),
                IconButton(
                  onPressed: recording
                      ? null
                      : () => setState(() => showBookmarks = !showBookmarks),
                  icon: showBookmarks
                      ? const Icon(Icons.graphic_eq)
                      : Badge(
                          isLabelVisible: markers.isNotEmpty,
                          label: Text('${markers.length}'),
                          child: const Icon(Icons.bookmark_border),
                        ),
                ),
              ],
            ),
            if (!recording) ...[
              Text(
                '${formatSeconds(player.position.inSeconds)} / ${formatSeconds(player.duration.inSeconds)}',
                textAlign: TextAlign.center,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: const Icon(Icons.replay_10),
                    onPressed: () => player.seek(
                      Duration(
                        milliseconds: math.max(
                          0,
                          player.position.inMilliseconds - 10000,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      player.isPlaying ? Icons.pause_circle : Icons.play_circle,
                    ),
                    iconSize: 48,
                    onPressed: () => action(() => vm.playSaved(widget.file)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.forward_10),
                    onPressed: () => player.seek(
                      Duration(
                        milliseconds: math.min(
                          player.duration.inMilliseconds,
                          player.position.inMilliseconds + 10000,
                        ),
                      ),
                    ),
                  ),
                  AbRepeatButton(
                    repeat: player.abRepeat,
                    onPressed: player.cycleAbRepeat,
                  ),
                ],
              ),
              if (AppPlatform.isAndroid && widget.file.isPublic)
                OutlinedButton.icon(
                  icon: const Icon(Icons.mic),
                  label: const Text('ضبط جایگزین از این نقطه'),
                  onPressed: () async {
                    final yes = await showDialog<bool>(
                      context: context,
                      builder: (c) => AlertDialog(
                        title: const Text('جایگزینی صدا از محل فعلی؟'),
                        content: const Text(
                          'صدای جدید روی این قسمت از فایل نوشته می‌شود.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(c, false),
                            child: const Text('انصراف'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(c, true),
                            child: const Text('شروع'),
                          ),
                        ],
                      ),
                    );
                    if (yes == true)
                      await action(() => vm.startOverwrite(widget.file));
                  },
                ),
            ] else
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(vm.timer),
                  IconButton(
                    icon: Icon(vm.isPaused ? Icons.mic : Icons.pause),
                    onPressed: () => action(
                      vm.isPaused ? vm.resumeRecording : vm.pauseRecording,
                    ),
                  ),
                  FilledButton(
                    onPressed: vm.isBusy
                        ? null
                        : () => action(() async {
                            await vm.stopRecording();
                            await load();
                          }),
                    child: const Text('پایان و ذخیره'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
