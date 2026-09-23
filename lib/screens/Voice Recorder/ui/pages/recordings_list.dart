import 'package:flutter/material.dart';
import 'dart:io';
import 'package:sornaz/components/audio_crop_page.dart';
import '../../services/recording_waveforms.dart';
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
  final scrollControllers = <String, ScrollController>{};
  final lastPlaying = <String, String?>{};
  @override
  void initState() {
    super.initState();
    tabs = TabController(length: 2, vsync: this)..addListener(changed);
    store.addListener(collectionChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted)
        run(() async {
          await store.load();
          collectionChanged();
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
    for (final controller in scrollControllers.values) {
      controller.dispose();
    }
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

  Future<void> act(
    String action,
    List<SavedRecording> files, {
    String? collection,
  }) async {
    if (files.isEmpty) return;
    final vm = context.read<VoiceRecorderProvider>();
    await run(() async {
      if (action == 'crop' && files.length == 1) {
        final file = files.single;
        await vm.playbackService.pause();
        if (!mounted) return;
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AudioCropPage(
              source: file.uri,
              name: file.name,
              onSave: (staged, replace, start, end) async {
                if (replace) {
                  if (vm.playbackService.currentPath == file.uri)
                    await vm.playbackService.stop();
                  await commitAudioCrop(staged, file.uri, true);
                  await RecordingWaveforms.move(file.uri, null);
                  await vm.fileService.bookmarks.crop(
                    file.uri,
                    start.inMilliseconds,
                    end.inMilliseconds,
                  );
                } else {
                  final path = vm.fileService.newPath();
                  await File(staged).copy(path);
                  await vm.fileService.publish(path);
                }
                await vm.refreshFiles();
              },
            ),
          ),
        );
      } else if (action == 'playlist') {
        await chooseAudioPlaylist(
          context,
          files.map((f) => f.uri),
          store,
          excludeKey: collection,
        );
      } else if (action == 'remove' && collection != null) {
        for (final file in files) {
          await store.remove(collection, file.uri);
        }
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

  Widget menu(List<SavedRecording> files, {String? collection}) => SizedBox(
    width: 32,
    height: 32,
    child: PopupMenuButton<String>(
      padding: EdgeInsets.zero,
      icon: const Icon(Icons.more_vert, size: 24),
      onSelected: (value) => act(value, files, collection: collection),
      itemBuilder: (_) => [
        if (files.length == 1)
          const PopupMenuItem(value: 'rename', child: Text('تغییر نام')),
        if (files.length == 1)
          const PopupMenuItem(value: 'crop', child: Text('برش صدا')),
        const PopupMenuItem(
          value: 'playlist',
          child: Text('افزودن به لیست پخش'),
        ),
        if (collection != null)
          const PopupMenuItem(value: 'remove', child: Text('حذف از لیست پخش')),
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
    final controller = scrollControllers.putIfAbsent(
      key ?? '__all__',
      ScrollController.new,
    );
    final current = vm.playbackService.currentPath;
    final active = (tabs.index == 0 ? null : keys[tabs.index - 1]) == key;
    if (active && lastPlaying[key ?? '__all__'] != current) {
      lastPlaying[key ?? '__all__'] = current;
      final index = files.indexWhere((f) => f.uri == current);
      if (index >= 0)
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || !controller.hasClients) return;
          controller.animateTo(
            (index * 64 - (controller.position.viewportDimension - 64) / 2)
                .clamp(0.0, controller.position.maxScrollExtent),
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeInOutCubic,
          );
        });
    }
    return RefreshIndicator(
      onRefresh: vm.refreshFiles,
      child: ListView.builder(
        controller: controller,
        itemExtent: 64,
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
                isPlaying: vm.playbackService.currentPath == file.uri,
                paused: !vm.isPlaying,
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
                trailing: menu([file], collection: key),
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
          if (tabs.index > 0 &&
              keys[tabs.index - 1] != MusicPlaylists.favorite) ...[
            IconButton(
              tooltip: 'تغییر نام دسته‌بندی',
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => run(() async {
                await editAudioCollection(context, store, keys[tabs.index - 1]);
              }),
            ),
            IconButton(
              tooltip: 'حذف دسته‌بندی',
              icon: const Icon(Icons.delete_outline),
              onPressed: () => run(() async {
                await editAudioCollection(
                  context,
                  store,
                  keys[tabs.index - 1],
                  delete: true,
                );
              }),
            ),
          ],
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
              isScrollable: false,
              tabAlignment: TabAlignment.fill,
              labelPadding: EdgeInsets.zero,
              labelStyle: const TextStyle(fontSize: 12),
              tabs: [
                const Tab(text: 'همه'),
                ...keys.map(
                  (k) => Tab(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(playlistLabel(context, k)),
                    ),
                  ),
                ),
              ],
            ),
            if (selected.isNotEmpty)
              Row(
                children: [
                  IconButton(
                    onPressed: () => setState(selected.clear),
                    icon: const Icon(Icons.close),
                  ),
                  Text('${selected.length}'),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.select_all),
                    onPressed: () => setState(() {
                      final members = tabs.index == 0
                          ? null
                          : store.lists[keys[tabs.index - 1]];
                      selected.addAll(
                        vm.files
                            .where(
                              (f) =>
                                  (members == null ||
                                      members.contains(f.uri)) &&
                                  f.name.toLowerCase().contains(query),
                            )
                            .map((f) => f.uri),
                      );
                    }),
                  ),
                  menu(
                    vm.files.where((f) => selected.contains(f.uri)).toList(),
                    collection: tabs.index == 0 ? null : keys[tabs.index - 1],
                  ),
                  const SizedBox(width: 12),
                ],
              ),
            Expanded(
              child: TabBarView(
                controller: tabs,
                children: [list(vm, null), ...keys.map((k) => list(vm, k))],
              ),
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
