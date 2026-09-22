import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sornaz/components/scroll_aware_scaffold.dart';
import 'package:sornaz/components/app_top_bar_direction.dart';
import 'package:sornaz/components/expanding_search_bar.dart';
import 'package:sornaz/helpers/app_colors.dart';
import 'package:sornaz/helpers/app_data.dart';
import 'package:sornaz/screens/Players/providers/audio_player_provider.dart';
import 'package:sornaz/screens/Players/services/music_playlists.dart';
import 'package:sornaz/screens/Players/ui/components/audio_item.dart';
import 'package:sornaz/screens/Players/ui/components/audio_controls.dart';
import 'package:sornaz/screens/Players/ui/components/audio_slider.dart';
import 'package:sornaz/screens/Players/ui/components/player_dialog.dart';
import 'package:sornaz/screens/Players/ui/components/player_slide_navigation.dart';
import 'package:sornaz/screens/Players/ui/pages/playlists.dart';
import '../../provider/voice_recorder_provider.dart';
import '../../services/file_service.dart';
import '../../services/playback_service.dart';
import 'recorder_settings.dart';
import 'recording_playback.dart';

class RecordedFilesPage extends StatefulWidget {
  const RecordedFilesPage({super.key});
  @override
  State<RecordedFilesPage> createState() => _RecordedFilesPageState();
}

class _RecordedFilesPageState extends State<RecordedFilesPage>
    with TickerProviderStateMixin {
  final store = MusicPlaylists.recordings;
  final selected = <String>{};
  String query = '';
  List<String> keys = [MusicPlaylists.favorite];
  late TabController tabs;
  @override
  void initState() {
    super.initState();
    tabs = TabController(length: 2, vsync: this)..addListener(changed);
    store.addListener(collectionChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted)
        run(() async {
          await store.load();
          if (mounted)
            await context.read<VoiceRecorderProvider>().refreshFiles();
        });
    });
  }

  void changed() {
    if (mounted) setState(() {});
  }

  void collectionChanged() {
    if (!mounted) return;
    final next = [
      MusicPlaylists.favorite,
      ...store.lists.keys.where((k) => k != MusicPlaylists.favorite),
    ];
    if (next.length != keys.length) {
      final index = tabs.index.clamp(0, next.length);
      tabs.removeListener(changed);
      tabs.dispose();
      tabs = TabController(
        length: next.length + 1,
        initialIndex: index,
        vsync: this,
      )..addListener(changed);
    }
    setState(() => keys = next);
  }

  @override
  void dispose() {
    store.removeListener(collectionChanged);
    tabs.removeListener(changed);
    tabs.dispose();
    super.dispose();
  }

  Future<void> run(Future<void> Function() action) async {
    try {
      await action();
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'عملیات انجام نشد؛ دسترسی فایل و فضای خالی را بررسی کنید.',
            ),
          ),
        );
    }
  }

  Future<void> act(String action, List<SavedRecording> files) async {
    if (files.isEmpty) return;
    final vm = context.read<VoiceRecorderProvider>();
    await run(() async {
      if (action == 'playlist') {
        await chooseAudioPlaylist(context, files.map((f) => f.uri), store);
      } else if (action == 'rename' && files.length == 1) {
        final file = files.single;
        final name = await recordingNameDialog(
          context,
          'تغییر نام',
          file.name.replaceFirst(RegExp(r'\.[^.]+$'), ''),
        );
        if (name == null || name.trim().isEmpty) return;
        if (vm.playbackService.currentPath == file.uri)
          await vm.playbackService.stop();
        await vm.fileService.rename(file, name.trim());
        await vm.refreshFiles();
      } else if (action == 'delete') {
        final yes = await confirmRecordingDelete(
          context,
          'حذف ${files.length} فایل؟',
        );
        if (!yes) return;
        if (files.any((f) => f.uri == vm.playbackService.currentPath))
          await vm.playbackService.stop();
        for (final file in files) {
          await vm.fileService.delete(file);
        }
        await vm.refreshFiles();
      } else if (action == 'share') {
        for (final file in files) {
          await vm.fileService.share(file);
        }
      }
      if (mounted) setState(selected.clear);
    });
  }

  Widget menu(List<SavedRecording> files) => SizedBox(
    width: 32,
    height: 32,
    child: PopupMenuButton<String>(
      padding: EdgeInsets.zero,
      icon: const Icon(Icons.more_vert, size: 24),
      onSelected: (value) => act(value, files),
      itemBuilder: (_) => [
        if (files.length == 1)
          const PopupMenuItem(value: 'rename', child: Text('تغییر نام')),
        const PopupMenuItem(
          value: 'playlist',
          child: Text('افزودن به پلی‌لیست'),
        ),
        const PopupMenuItem(value: 'share', child: Text('اشتراک‌گذاری')),
        const PopupMenuItem(value: 'delete', child: Text('حذف')),
      ],
    ),
  );
  Widget list(VoiceRecorderProvider vm, String? key) {
    final members = key == null ? null : (store.lists[key] ?? []).toSet();
    final files = vm.files
        .where(
          (f) =>
              (members == null || members.contains(f.uri)) &&
              f.name.toLowerCase().contains(query),
        )
        .toList();
    return RefreshIndicator(
      onRefresh: vm.refreshFiles,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: files.isEmpty ? 1 : files.length,
        itemBuilder: (c, i) {
          if (files.isEmpty)
            return const Padding(
              padding: EdgeInsets.all(32),
              child: Text(
                'فایل ضبط‌شده‌ای وجود ندارد.',
                textAlign: TextAlign.center,
              ),
            );
          final file = files[i];
          return FutureBuilder<Map<String, String>>(
            future: vm.details(file),
            builder: (c, snapshot) {
              final details = snapshot.data ?? {};
              return AudioRow(
                title: file.name,
                location: details['location'] ?? file.uri,
                duration: Duration(
                  milliseconds: int.tryParse(details['durationMs'] ?? '') ?? 0,
                ),
                isPlaying:
                    vm.playbackService.currentPath == file.uri && vm.isPlaying,
                selected: selected.contains(file.uri),
                onLongPress: () => setState(() => selected.add(file.uri)),
                onTap: () {
                  if (selected.isNotEmpty) {
                    setState(() {
                      if (!selected.remove(file.uri)) selected.add(file.uri);
                    });
                  } else {
                    run(() async {
                      await context.read<AudioPlayerProvider>().pause();
                      await vm.playSaved(file, queue: files);
                    });
                  }
                },
                trailing: menu([file]),
              );
            },
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<VoiceRecorderProvider>();
    return ScrollAwareScaffold(
      appBar: ExpandingSearchBar(
        title: Row(
          children: [
            const BackButton(),
            Expanded(
              child: Text(
                'صداهای ضبط‌شده',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: AppTopBarDirection.titleSize(context),
                ),
              ),
            ),
          ],
        ),
        onChanged: (value) => setState(() => query = value.toLowerCase()),
        onSettings: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const RecorderSettingsPage()),
        ),
        actions: [
          IconButton(
            tooltip: 'دسته‌بندی جدید',
            icon: const Icon(Icons.playlist_add),
            onPressed: () => run(() async {
              final key = await createMusicPlaylist(context, collection: store);
              if (mounted && key != null && keys.contains(key))
                tabs.animateTo(keys.indexOf(key) + 1);
            }),
          ),
        ],
      ),
      body: PlayerSlideNavigation(
        page: tabs.index,
        count: keys.length + 1,
        go: tabs.animateTo,
        child: Column(
          children: [
            TabBar(
              controller: tabs,
              isScrollable: keys.length > 1,
              tabAlignment: keys.length > 1
                  ? TabAlignment.start
                  : TabAlignment.fill,
              labelPadding: keys.length > 1
                  ? const EdgeInsets.symmetric(horizontal: 20)
                  : EdgeInsets.zero,
              labelStyle: const TextStyle(fontSize: 12),
              tabs: [
                const Tab(text: 'همه'),
                ...keys.map((k) => Tab(text: playlistLabel(context, k))),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: tabs,
                children: [list(vm, null), ...keys.map((k) => list(vm, k))],
              ),
            ),
            if (selected.isNotEmpty)
              Row(
                children: [
                  TextButton(
                    onPressed: () => setState(selected.clear),
                    child: const Text('انصراف'),
                  ),
                  Text('${selected.length}'),
                  const Spacer(),
                  menu(
                    vm.files.where((f) => selected.contains(f.uri)).toList(),
                  ),
                  const SizedBox(width: 12),
                ],
              ),
            const RecordingsPlayer(),
          ],
        ),
      ),
    );
  }
}

class RecordingsPlayer extends StatelessWidget {
  const RecordingsPlayer({super.key});
  @override
  Widget build(BuildContext context) {
    final vm = context.watch<VoiceRecorderProvider>(), p = vm.playbackService;
    final current = vm.files.where((f) => f.uri == p.currentPath).firstOrNull;
    if (current == null) return const SizedBox.shrink();
    Future<void> run(Future<void> Function() action) async {
      try {
        await action();
      } catch (_) {
        if (context.mounted)
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'پخش فایل انجام نشد؛ دسترسی به فایل را بررسی کنید.',
              ),
            ),
          );
      }
    }

    return Container(
      color: AppColors.music_player_bottom_player_background_color(
        isDark: context.watch<AppData>().isDark,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          PlaybackProgress(
            position: p.position,
            duration: p.duration,
            repeat: p.abRepeat,
            onStart: p.rememberPosition,
            onSeek: (at) => run(() => p.seek(at)),
            toggleTime: p.toggleTime,
            remaining: p.showRemaining,
          ),
          PlaybackControls(
            playing: p.isPlaying,
            undo: p.isUndoMode,
            shuffle: p.queue.isShuffle,
            repeatMode: p.queue.repeatMode,
            repeat: p.abRepeat,
            speed: p.speed,
            speedOptions: PlaybackService.speedOptions,
            onPlayPause: () => run(p.toggleCurrent),
            onNext: () => run(p.nextWithUndo),
            onPrevious: () => run(p.previousOrUndo),
            onForward: () => run(() => p.skip(const Duration(seconds: 10))),
            onBackward: () => run(() => p.skip(const Duration(seconds: -10))),
            onShuffle: p.toggleShuffle,
            onRepeat: p.toggleRepeat,
            onAbRepeat: p.cycleAbRepeat,
            onSpeed: (value) => run(() => p.setSpeed(value)),
            onInfo: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => RecordingInformationPage(file: current),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Future<String?> recordingNameDialog(
  BuildContext context,
  String title,
  String initial,
) async {
  var value = initial;
  return showDialog<String>(
    context: context,
    builder: (c) => PlayerDialog(
      title: Text(title),
      content: TextFormField(
        initialValue: initial,
        autofocus: true,
        maxLength: 100,
        style: const TextStyle(fontSize: 14),
        onChanged: (text) => value = text,
      ),
      actions: [
        PlayerDialogButton(
          primary: false,
          onPressed: () => Navigator.pop(c),
          child: const Text('انصراف'),
        ),
        PlayerDialogButton(
          onPressed: () => Navigator.pop(c, value.trim()),
          child: const Text('ذخیره'),
        ),
      ],
    ),
  );
}

Future<bool> confirmRecordingDelete(BuildContext context, String title) async =>
    await showDialog<bool>(
      context: context,
      builder: (c) => PlayerDialog(
        title: Text(title),
        actions: [
          PlayerDialogButton(
            primary: false,
            onPressed: () => Navigator.pop(c, false),
            child: const Text('انصراف'),
          ),
          PlayerDialogButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    ) ??
    false;
