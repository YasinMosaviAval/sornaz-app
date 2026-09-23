import '../../services/recording_waveforms.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:sornaz/components/app_top_bar_direction.dart';
import 'package:sornaz/components/ab_repeat.dart';
import 'package:sornaz/helpers/app_colors.dart';
import 'package:sornaz/helpers/app_data.dart';
import 'package:sornaz/helpers/app_functions.dart';

import 'package:sornaz/screens/Players/metadata/audio_metadata.dart';
import 'package:sornaz/screens/Players/ui/pages/song_information.dart';
import 'package:sornaz/screens/Players/ui/pages/lyrics.dart';
import 'package:sornaz/screens/Players/ui/components/audio_controls.dart';
import '../../provider/voice_recorder_provider.dart';
import '../../services/file_service.dart';
import '../../services/playback_service.dart';
import '../components/seekable_waveform.dart';
import '../components/recording_timer.dart';
import 'recordings_list.dart';

class RecordingInformationPage extends StatelessWidget {
  const RecordingInformationPage({super.key, required this.file});
  final SavedRecording file;
  @override
  Widget build(BuildContext context) {
    final vm = context.watch<VoiceRecorderProvider>();
    final current =
        vm.files
            .where((f) => f.uri == vm.playbackService.currentPath)
            .firstOrNull ??
        file;
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppTopBarDirection(
          child: AppBar(
            title: const Text('اطلاعات'),
            bottom: const TabBar(
              labelStyle: TextStyle(fontSize: 12),
              tabs: [
                Tab(text: 'موج صدا'),
                Tab(text: 'یادداشت ها'),
                Tab(text: 'متن'),
                Tab(text: 'اطلاعات'),
              ],
            ),
          ),
        ),
        body: TabBarView(
          children: [
            RecordingPlaybackPage(
              key: ValueKey('wave:${current.uri}'),
              file: current,
              embedded: true,
            ),
            AudioLyricsEditor(
              key: ValueKey('notes:${current.uri}'),
              path: current.uri,
              initialTitle: withoutAudioExtension(current.name),
              notes: true,
            ),
            AudioLyricsEditor(
              key: ValueKey('lyrics:${current.uri}'),
              path: current.uri,
              initialTitle: withoutAudioExtension(current.name),
            ),
            FutureBuilder<Map<String, String>>(
              future: vm.details(current),
              builder: (c, snapshot) {
                final data = snapshot.data ?? {};
                return NowPlayingInfoTab(
                  fileName: current.name,
                  filePath: current.uri,
                  metadata: AudioMetadata(
                    title: data['title'] ?? current.name,
                    artist: data['artist'],
                    album: data['album'],
                    bitrate: int.tryParse(data['bitrate'] ?? '') == null
                        ? null
                        : (int.parse(data['bitrate']!) / 1000).round(),
                    details: data,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class RecordingPlaybackPage extends StatefulWidget {
  const RecordingPlaybackPage({
    super.key,
    required this.file,
    this.embedded = false,
  });
  final SavedRecording file;
  final bool embedded;
  @override
  State<RecordingPlaybackPage> createState() => _RecordingPlaybackPageState();
}

class _RecordingPlaybackPageState extends State<RecordingPlaybackPage> {
  bool showBookmarks = false, loading = true;
  List<double> samples = [];
  List<int> markers = [];
  Map<int, String> names = {};
  String? error;
  int revision = -1;
  @override
  void initState() {
    super.initState();
    samples = RecordingWaveforms.memory[widget.file.uri] ?? [];
    loading = samples.isEmpty;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) load();
    });
  }

  Future<void> loadMarkers(VoiceRecorderProvider vm) async {
    final items = await vm.fileService.bookmarks.load(widget.file.uri);
    final labels = <int, String>{};
    for (final at in items) {
      labels[at] = await vm.fileService.bookmarks.name(widget.file.uri, at);
    }
    if (mounted)
      setState(() {
        markers = items;
        names = labels;
      });
  }

  Future<void> load() async {
    final vm = context.read<VoiceRecorderProvider>();

    setState(() {
      loading = samples.isEmpty;
      error = null;
    });
    try {
      final cached = await RecordingWaveforms.cached(widget.file.uri);
      if (mounted && cached != null) {
        setState(() {
          samples = cached;
          loading = false;
        });
      }
      if (vm.playbackService.currentPath != widget.file.uri) {
        vm.playbackService.setQueue(
          vm.files.map((f) => f.uri),
          widget.file.uri,
        );
        await vm.playbackService.play(widget.file.uri, autoplay: false);
      }
      vm.playbackBookmarks = await vm.fileService.bookmarks.load(
        widget.file.uri,
      );
      await loadMarkers(vm);
      final loaded = await RecordingWaveforms.load(widget.file, vm.fileService);
      if (mounted) setState(() => samples = loaded);
    } catch (_) {
      if (mounted) setState(() => error = 'نمایش موج صدا ممکن نشد.');
    } finally {
      if (mounted) setState(() => loading = false);
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

  Future<void> rename(int at) async {
    final name = await recordingNameDialog(
      context,
      'نام نشانه',
      names[at] ?? '',
    );
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

  Future<void> remove(int at) async {
    if (!await confirmRecordingDelete(context, 'حذف نشانه؟') || !mounted)
      return;
    await action(() async {
      final vm = context.read<VoiceRecorderProvider>();
      await vm.removeBookmark(widget.file.uri, at);
      await loadMarkers(vm);
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<VoiceRecorderProvider>(),
        player = vm.playbackService;
    if (revision != vm.bookmarkRevision) {
      revision = vm.bookmarkRevision;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) loadMarkers(vm);
      });
    }
    final dark = context.watch<AppData>().isDark;
    final previous = markers
        .where((t) => t <= player.position.inMilliseconds)
        .lastOrNull;
    final body = LayoutBuilder(
      builder: (c, box) => SingleChildScrollView(
        child: SizedBox(
          height: box.maxHeight < 550 ? 550 : box.maxHeight,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  children: [
                    SizedBox(
                      height: 110,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SmoothRecordingTimer(
                            running: player.isPlaying,
                            position: () =>
                                player.displayPosition.inMilliseconds,
                          ),
                          Text(
                            formatSeconds(player.duration.inSeconds),
                            textDirection: TextDirection.ltr,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 250,
                      child: ColoredBox(
                        color:
                            AppColors.voice_recorder_basic_waveform_decoration_color(
                              isDark: dark,
                            ),
                        child: showBookmarks
                            ? ListView.builder(
                                padding: EdgeInsets.zero,
                                itemExtent: 36,
                                itemCount: markers.isEmpty ? 1 : markers.length,
                                itemBuilder: (c, i) {
                                  if (markers.isEmpty)
                                    return const Center(
                                      child: Text(
                                        'هنوز نشانه‌ای اضافه نشده است.',
                                        style: TextStyle(fontSize: 10),
                                      ),
                                    );
                                  final at = markers[i];
                                  return Material(
                                    color: previous == at
                                        ? Theme.of(context).colorScheme.primary
                                              .withValues(alpha: .12)
                                        : Colors.transparent,
                                    child: InkWell(
                                      onTap: () => action(
                                        () => vm.seekBookmark(widget.file, at),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                        ),
                                        child: Row(
                                          children: [
                                            Text(
                                              recordingTime(at),
                                              textDirection: TextDirection.ltr,
                                              style: const TextStyle(
                                                fontSize: 10,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                names[at]?.isNotEmpty == true
                                                    ? names[at]!
                                                    : 'نشانه',
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontSize: 10,
                                                ),
                                              ),
                                            ),
                                            IconButton(
                                              iconSize: 16,
                                              padding: EdgeInsets.zero,
                                              constraints:
                                                  const BoxConstraints.tightFor(
                                                    width: 36,
                                                    height: 36,
                                                  ),
                                              tooltip: 'ویرایش نشانه',
                                              onPressed: () => rename(at),
                                              icon: const Icon(
                                                Icons.edit_outlined,
                                              ),
                                            ),
                                            IconButton(
                                              iconSize: 16,
                                              padding: EdgeInsets.zero,
                                              constraints:
                                                  const BoxConstraints.tightFor(
                                                    width: 36,
                                                    height: 36,
                                                  ),
                                              tooltip: 'حذف نشانه',
                                              onPressed: () => remove(at),
                                              icon: const Icon(
                                                Icons.delete_outline,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              )
                            : loading
                            ? const Center(child: CircularProgressIndicator())
                            : error != null
                            ? Center(
                                child: TextButton(
                                  onPressed: load,
                                  child: Text('$error تلاش مجدد'),
                                ),
                              )
                            : SeekableWaveform(
                                samples: samples,
                                duration: player.duration > Duration.zero
                                    ? player.duration.inMilliseconds
                                    : samples.length * 100,
                                position: player.position.inMilliseconds,
                                markers: markers,
                                repeat: player.abRepeat,
                                onSeekStart: player.rememberPosition,
                                onSeek: (at) => action(
                                  () => player.seek(Duration(milliseconds: at)),
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton.icon(
                          onPressed: vm.canBookmarkPlayback
                              ? () => action(() async {
                                  await vm.addPlaybackBookmark(widget.file);
                                  await loadMarkers(vm);
                                })
                              : null,
                          icon: const Icon(Icons.bookmark_add_outlined),
                          label: const Text('نشانه‌گذاری'),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: IconButton(
                            onPressed: () =>
                                setState(() => showBookmarks = !showBookmarks),
                            tooltip: showBookmarks
                                ? 'موج صدا'
                                : 'لیست نشانه‌ها',
                            icon: showBookmarks
                                ? const Icon(Icons.graphic_eq)
                                : Badge(
                                    isLabelVisible: markers.isNotEmpty,
                                    label: Text('${markers.length}'),
                                    child: const Icon(Icons.bookmark_border),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    PlaybackSpeedButton(
                      speed: player.speed,
                      presets: PlaybackService.speedOptions,
                      onChanged: (value) =>
                          action(() => player.setSpeed(value)),
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          width: 2,
                          color:
                              AppColors.voice_recorder_record_button_border_color(
                                isDark: dark,
                              ),
                        ),
                      ),
                      child: SizedBox(
                        width: 48,
                        height: 48,
                        child: FloatingActionButton(
                          heroTag: 'recording-wave-play',
                          elevation: 0,
                          shape: const CircleBorder(),
                          backgroundColor:
                              AppColors.voice_recorder_play_icon_background_color(
                                isDark: dark,
                              ),
                          onPressed: () =>
                              action(() => vm.playSaved(widget.file)),
                          child: Icon(
                            player.isPlaying
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            size: 36,
                            color:
                                AppColors.voice_recorder_play_icon_active_color(
                                  isDark: dark,
                                ),
                          ),
                        ),
                      ),
                    ),
                    AbRepeatButton(
                      repeat: player.abRepeat,
                      onPressed: player.duration > Duration.zero
                          ? player.cycleAbRepeat
                          : null,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (widget.embedded) return body;
    return Scaffold(
      appBar: AppTopBarDirection(
        child: AppBar(
          title: Text(widget.file.name, style: const TextStyle(fontSize: 14)),
        ),
      ),
      body: body,
    );
  }
}
