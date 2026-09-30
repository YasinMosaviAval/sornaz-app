import 'package:sornaz/helpers/app_appearance.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:video_player/video_player.dart';
import 'package:sornaz/screens/Social/social_widgets.dart';
import '../../services/music_audio_handler.dart';
import '../../services/music_playlists.dart';
import 'playlists.dart';
import 'video_crop_page.dart';
import 'package:sornaz/components/media_dialogs.dart';
import 'package:sornaz/components/expanding_search_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:volume_controller/volume_controller.dart';
import '../../services/player_settings.dart';
import 'equalizer.dart';
import '../components/search_bar.dart' show endLabel;
import '../components/playback_speed_dialog.dart';
import 'package:sornaz/components/ab_repeat.dart';

enum VideoRepeatMode { off, one, all }

class DeviceVideo {
  const DeviceVideo({
    required this.uri,
    required this.name,
    required this.folder,
    required this.folderId,
    required this.duration,
  });
  factory DeviceVideo.fromMap(Map<dynamic, dynamic> value) => DeviceVideo(
    uri: value['uri'] as String,
    name: value['name'] as String,
    folder: value['folder'] as String,
    folderId: value['folderId'] as String,
    duration: Duration(milliseconds: (value['duration'] as num).toInt()),
  );
  final String uri, name, folder, folderId;
  final Duration duration;
}

class VideoThumbnail extends StatefulWidget {
  const VideoThumbnail({super.key, required this.uri});
  final String uri;
  @override
  State<VideoThumbnail> createState() => _VideoThumbnailState();
}

class _VideoThumbnailState extends State<VideoThumbnail> {
  static final cache = <String, Future<Uint8List?>>{};
  late Future<Uint8List?> bytes;
  void load() {
    if (cache.length >= 128 && !cache.containsKey(widget.uri))
      cache.remove(cache.keys.first);
    bytes = cache.putIfAbsent(
      widget.uri,
      () => const MethodChannel('sornaz/story_media')
          .invokeMethod<Uint8List>('thumbnail', {
            'uri': widget.uri,
            'video': true,
            'size': 160,
            'timeMs': 0,
          })
          .catchError((Object _) => null),
    );
  }

  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void didUpdateWidget(VideoThumbnail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.uri != widget.uri) load();
  }

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: appRadius(context),
    child: SizedBox(
      width: 48,
      height: 36,
      child: FutureBuilder<Uint8List?>(
        future: bytes,
        builder: (context, value) => value.data == null
            ? ColoredBox(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
              )
            : Image.memory(
                value.data!,
                fit: BoxFit.cover,
                gaplessPlayback: true,
              ),
      ),
    ),
  );
}

class VideoLibraryPage extends StatefulWidget {
  const VideoLibraryPage({super.key});
  @override
  State<VideoLibraryPage> createState() => _VideoLibraryPageState();
}

class _VideoLibraryPageState extends State<VideoLibraryPage>
    with SingleTickerProviderStateMixin {
  static const channel = MethodChannel('sornaz/device_videos');
  final store = MusicPlaylists(storagePrefix: 'video');
  List<DeviceVideo> videos = [];
  final expanded = <String>{};
  final selected = <String>{};
  late final tabs = TabController(length: 3, vsync: this);
  int currentTab = 0;
  bool busy = false;
  String query = '';
  String? error;
  bool loading = true;
  bool gridView = false;
  int gridColumns = 3;
  String t(String fa, String en) => socialText(context, fa, en);
  @override
  void initState() {
    super.initState();
    tabs.addListener(tabChanged);
    store.addListener(changed);
    _loadViewSettings();
    load();
  }

  Future<void> _loadViewSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      gridView = prefs.getBool('video.grid') ?? false;
      gridColumns = prefs.getInt('video.grid.columns') == 4 ? 4 : 3;
    });
  }

  Future<void> _viewSettings() async {
    await showDialog<void>(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (c, setDialog) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: appRadius(context)),
          title: Text(
            t('تنظیمات نمایش ویدیو', 'Video display settings'),
            style: const TextStyle(fontSize: 14),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                title: Text(
                  t('نمایش گرید', 'Grid view'),
                  style: const TextStyle(fontSize: 13),
                ),
                value: gridView,
                onChanged: (v) => setDialog(() => setState(() => gridView = v)),
              ),
              RadioListTile<int>(
                title: Text(
                  t(
                    'سه ویدیو در هر ردیف (۱۶:۹ عمودی)',
                    'Three portrait videos per row (9:16)',
                  ),
                  style: const TextStyle(fontSize: 12),
                ),
                value: 3,
                groupValue: gridColumns,
                onChanged: (v) =>
                    setDialog(() => setState(() => gridColumns = v!)),
              ),
              RadioListTile<int>(
                title: Text(
                  t('چهار ویدیو در هر ردیف (۱:۱)', 'Four videos per row (1:1)'),
                  style: const TextStyle(fontSize: 12),
                ),
                value: 4,
                groupValue: gridColumns,
                onChanged: (v) =>
                    setDialog(() => setState(() => gridColumns = v!)),
              ),
              ListTile(
                title: Row(
                  children: [
                    Expanded(
                      child: Text(
                        t('پایان آخرین فایل لیست', 'At the end of the list'),
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      endLabel(c, PlayerSettings.instance.listEnd),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
                onTap: () async {
                  final value = await showDialog<ListEndAction>(
                    context: c,
                    builder: (d) => SimpleDialog(
                      title: Text(
                        t('پایان آخرین فایل لیست', 'At the end of the list'),
                        style: const TextStyle(fontSize: 14),
                      ),
                      children: [
                        for (final action in ListEndAction.values)
                          SimpleDialogOption(
                            onPressed: () => Navigator.pop(d, action),
                            child: Text(endLabel(d, action)),
                          ),
                      ],
                    ),
                  );
                  if (value != null) {
                    await PlayerSettings.instance.setListEnd(value);
                    setDialog(() {});
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c),
              child: Text(t('بستن', 'Close')),
            ),
          ],
        ),
      ),
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('video.grid', gridView);
    await prefs.setInt('video.grid.columns', gridColumns);
  }

  String _videoDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return hours > 0
        ? '$hours:$minutes:$seconds'
        : '${duration.inMinutes}:$seconds';
  }

  Widget _grid(List<DeviceVideo> items, {bool embedded = false}) =>
      GridView.builder(
        padding: const EdgeInsets.all(4),
        shrinkWrap: embedded,
        physics: embedded ? const NeverScrollableScrollPhysics() : null,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: gridColumns,
          childAspectRatio: gridColumns == 3 ? 9 / 16 : 1,
          crossAxisSpacing: 4,
          mainAxisSpacing: 4,
        ),
        itemCount: items.length,
        itemBuilder: (context, i) => InkWell(
          onLongPress: () => setState(() {
            if (!selected.remove(items[i].uri)) selected.add(items[i].uri);
          }),
          onTap: () => selected.isEmpty
              ? open(items[i], items)
              : setState(() {
                  if (!selected.remove(items[i].uri)) {
                    selected.add(items[i].uri);
                  }
                }),
          child: Stack(
            fit: StackFit.expand,
            children: [
              VideoThumbnail(uri: items[i].uri),
              if (selected.contains(items[i].uri))
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: .22),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.primary,
                      width: 2,
                    ),
                  ),
                ),
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: .68),
                    borderRadius: appRadius(context),
                  ),
                  child: Text(
                    _videoDuration(items[i].duration),
                    style: const TextStyle(color: Colors.white, fontSize: 9),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  width: double.infinity,
                  color: Colors.black54,
                  padding: const EdgeInsets.all(3),
                  child: Text(
                    items[i].name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                  ),
                ),
              ),
            ],
          ),
        ),
      );

  void changed() {
    if (mounted) setState(() {});
  }

  void tabChanged() {
    if (currentTab == tabs.index) return;
    setState(() {
      currentTab = tabs.index;
      selected.clear();
    });
  }

  Future<void> load() async {
    if (mounted)
      setState(() {
        loading = true;
        error = null;
      });
    try {
      await store.load();
      final sdk = await channel.invokeMethod<int>('sdk') ?? 33;
      final permission = sdk >= 33 ? Permission.videos : Permission.storage;
      final status = await permission.request();
      if (!status.isGranted && !status.isLimited)
        throw StateError('permission');
      final items = await channel.invokeListMethod<dynamic>('list') ?? [];
      if (mounted)
        setState(
          () =>
              videos = items.map((e) => DeviceVideo.fromMap(e as Map)).toList(),
        );
    } catch (_) {
      if (mounted)
        setState(
          () => error = t(
            'دسترسی به ویدیوها ممکن نیست. دسترسی فایل‌ها را بررسی کنید.',
            'Could not load videos. Check media permissions.',
          ),
        );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  void dispose() {
    tabs.dispose();
    store.removeListener(changed);
    store.dispose();
    super.dispose();
  }

  Future<void> open(DeviceVideo video, List<DeviceVideo> list) async {
    await musicAudioHandler?.pause();
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DeviceVideoPlayback(
          videos: list,
          initialIndex: list.indexOf(video),
        ),
      ),
    );
  }

  Widget row(
    DeviceVideo video,
    List<DeviceVideo> list, {
    String? collection,
  }) => Column(
    children: [
      ListTile(
        key: ValueKey('video-item-${video.uri}'),
        dense: true,
        minVerticalPadding: 10,
        contentPadding: const EdgeInsetsDirectional.only(start: 16, end: 0),
        tileColor: selected.contains(video.uri)
            ? Theme.of(context).colorScheme.primary.withValues(alpha: .12)
            : null,
        leading: VideoThumbnail(uri: video.uri),
        title: Text(
          video.name,
          style: const TextStyle(fontSize: 13),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '${video.duration.inMinutes}:${(video.duration.inSeconds % 60).toString().padLeft(2, '0')}',
          style: const TextStyle(fontSize: 11),
        ),
        onLongPress: () => setState(() {
          if (!selected.remove(video.uri)) selected.add(video.uri);
        }),
        onTap: () => selected.isEmpty
            ? open(video, list)
            : setState(() {
                if (!selected.remove(video.uri)) selected.add(video.uri);
              }),
        trailing: PopupMenuButton<String>(
          padding: EdgeInsets.zero,
          enabled: !busy,
          onSelected: (action) async {
            if (['rename', 'crop', 'share', 'delete'].contains(action)) {
              await fileAction(action, [video]);
              return;
            }
            if (action == 'add')
              await chooseAudioPlaylist(
                context,
                [video.uri],
                store,
                excludeKey: collection,
              );
            if (action == 'remove' && collection != null)
              await store.remove(collection, video.uri);
          },
          itemBuilder: (_) => [
            for (final action in [
              ('rename', t('تغییر نام', 'Rename')),
              ('crop', t('برش ویدیو', 'Trim video')),
              ('share', t('اشتراک‌گذاری', 'Share')),
              ('delete', t('حذف', 'Delete')),
            ])
              PopupMenuItem(value: action.$1, child: Text(action.$2)),
            PopupMenuItem(
              value: 'add',
              child: Text(t('افزودن به لیست پخش', 'Add to playlist')),
            ),
            if (collection != null)
              PopupMenuItem(
                value: 'remove',
                child: Text(t('حذف از لیست پخش', 'Remove from playlist')),
              ),
          ],
        ),
      ),
      Divider(
        height: .2,
        thickness: .2,
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .04),
      ),
    ],
  );
  Future<void> fileAction(String action, List<DeviceVideo> items) async {
    if (items.isEmpty || busy) return;
    setState(() => busy = true);
    try {
      if (action == 'add') {
        await chooseAudioPlaylist(context, items.map((v) => v.uri), store);
        return;
      }
      if (action == 'crop') {
        await musicAudioHandler?.pause();
        if (!mounted) return;
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                VideoCropPage(uri: items.single.uri, name: items.single.name),
          ),
        );
        await load();
        return;
      }
      String? name;
      if (action == 'rename') {
        final current = items.single.name;
        var draft = current;
        name = await showDialog<String>(
          context: context,
          builder: (c) => AlertDialog(
            title: Text(t('تغییر نام', 'Rename')),
            content: TextFormField(
              initialValue: current,
              onChanged: (v) => draft = v,
              maxLength: 180,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(c),
                child: Text(t('انصراف', 'Cancel')),
              ),
              TextButton(
                onPressed: () => Navigator.pop(c, draft.trim()),
                child: Text(t('ذخیره', 'Save')),
              ),
            ],
          ),
        );
        if (name == null || name.isEmpty) return;
        if (!name.contains('.') && current.contains('.'))
          name += current.substring(current.lastIndexOf('.'));
      }
      if (action == 'delete') {
        final yes = await confirmMediaDelete(
          context,
          t('ویدیوهای انتخاب‌شده حذف شوند؟', 'Delete selected videos?'),
        );
        if (yes != true) return;
      }
      await channel.invokeMethod(action, {
        'uris': items.map((v) => v.uri).toList(),
        if (name != null) 'name': name,
      });
      if (action == 'delete')
        for (final item in items) {
          await store.replacePath(item.uri, null);
        }
      if (!mounted) return;
      setState(selected.clear);
      if (action != 'share') await load();
    } catch (e) {
      if (mounted) socialError(context, e);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Widget groups(bool playlists) {
    final groups = <String, List<DeviceVideo>>{};
    if (playlists) {
      for (final e in store.lists.entries) {
        groups[e.key] = videos.where((v) => e.value.contains(v.uri)).toList();
      }
    } else {
      for (final video in videos) {
        groups.putIfAbsent(video.folderId, () => []).add(video);
      }
    }
    final visibleGroups = groups.entries.where((e) {
      final title = playlists
          ? e.key
          : (e.value.isEmpty ? '' : e.value.first.folder);
      return query.isEmpty ||
          title.toLowerCase().contains(query) ||
          e.value.any((v) => v.name.toLowerCase().contains(query));
    }).toList();
    return ListView(
      children: [
        for (final e in visibleGroups) ...[
          ListTile(
            dense: true,
            leading: Icon(
              playlists ? Icons.queue_music : Icons.folder_outlined,
              size: 24,
            ),
            title: Text(
              playlists
                  ? (e.key == MusicPlaylists.favorite
                        ? t('علاقه‌مندی', 'Favorites')
                        : e.key)
                  : e.value.first.folder,
              style: const TextStyle(fontSize: 13),
            ),
            subtitle: Text(
              '${e.value.length} ${t('ویدیو', 'videos')}',
              style: const TextStyle(fontSize: 11),
            ),
            onTap: () => setState(() {
              final key = '${playlists ? 'p' : 'f'}:${e.key}';
              if (!expanded.remove(key)) expanded.add(key);
            }),
            trailing: playlists && e.key != MusicPlaylists.favorite
                ? PopupMenuButton<String>(
                    padding: EdgeInsets.zero,
                    onSelected: (action) => editAudioCollection(
                      context,
                      store,
                      e.key,
                      delete: action == 'delete',
                    ),
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        value: 'rename',
                        child: Text(t('تغییر نام', 'Rename')),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Text(t('حذف', 'Delete')),
                      ),
                    ],
                  )
                : null,
          ),
          Divider(
            height: .2,
            thickness: .2,
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: .04),
          ),
          if (expanded.contains('${playlists ? 'p' : 'f'}:${e.key}'))
            if (gridView)
              _grid(
                e.value
                    .where(
                      (video) =>
                          query.isEmpty ||
                          video.name.toLowerCase().contains(query),
                    )
                    .toList(),
                embedded: true,
              )
            else
              for (final video in e.value.where(
                (v) => query.isEmpty || v.name.toLowerCase().contains(query),
              ))
                row(video, e.value, collection: playlists ? e.key : null),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final visible = videos
        .where((v) => v.name.toLowerCase().contains(query))
        .toList();
    final selectable = visible
        .where(
          (v) =>
              currentTab == 0 ||
              (currentTab == 1 && expanded.contains('f:${v.folderId}')) ||
              (currentTab == 2 &&
                  store.lists.entries.any(
                    (e) =>
                        expanded.contains('p:${e.key}') &&
                        e.value.contains(v.uri),
                  )),
        )
        .toList();
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: ExpandingSearchBar(
          title: Row(
            children: [
              const BackButton(),
              Expanded(
                child: Text(
                  t('پخش‌کننده ویدیو', 'Video player'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
          hint: t('جستجوی ویدیو', 'Search videos'),
          onChanged: (v) => setState(() => query = v.trim().toLowerCase()),
          actions: [
            IconButton(
              tooltip: t('لیست پخش جدید', 'New playlist'),
              icon: const Icon(Icons.playlist_add),
              onPressed: () => createMusicPlaylist(context, collection: store),
            ),
            IconButton(
              tooltip: t('تنظیمات نمایش', 'Display settings'),
              icon: const Icon(Icons.view_module_outlined),
              onPressed: _viewSettings,
            ),
          ],
        ),
        body: Column(
          children: [
            TabBar(
              controller: tabs,
              tabs: [
                Tab(text: t('ویدیوها', 'Videos')),
                Tab(text: t('پوشه‌ها', 'Folders')),
                Tab(text: t('لیست پخش‌ها', 'Playlists')),
              ],
            ),
            if (selected.isNotEmpty)
              Row(
                children: [
                  IconButton(
                    onPressed: () => setState(() {
                      if (selectable.every((v) => selected.contains(v.uri))) {
                        selected.clear();
                      } else {
                        selected.addAll(selectable.map((v) => v.uri));
                      }
                    }),
                    icon: Icon(
                      selectable.every((v) => selected.contains(v.uri))
                          ? Icons.check_box
                          : Icons.check_box_outline_blank,
                    ),
                  ),
                  Text('${selected.length}'),
                  const Spacer(),
                  PopupMenuButton<String>(
                    enabled: !busy,
                    onSelected: (action) => fileAction(
                      action,
                      videos.where((v) => selected.contains(v.uri)).toList(),
                    ),
                    itemBuilder: (_) => [
                      for (final entry in [
                        if (selected.length == 1) ...[
                          ('rename', t('تغییر نام', 'Rename')),
                          ('crop', t('برش ویدیو', 'Trim video')),
                        ],
                        ('add', t('افزودن به لیست پخش', 'Add to playlist')),
                        ('share', t('اشتراک‌گذاری', 'Share')),
                        ('delete', t('حذف', 'Delete')),
                      ])
                        PopupMenuItem(value: entry.$1, child: Text(entry.$2)),
                    ],
                  ),
                  IconButton(
                    onPressed: () => setState(selected.clear),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            Expanded(
              child: loading
                  ? const Center(child: CircularProgressIndicator())
                  : error != null
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(error!),
                          TextButton(
                            onPressed: load,
                            child: Text(t('تلاش دوباره', 'Retry')),
                          ),
                        ],
                      ),
                    )
                  : TabBarView(
                      controller: tabs,
                      children: [
                        visible.isEmpty
                            ? Center(
                                child: Text(
                                  t('ویدیویی پیدا نشد', 'No videos found'),
                                ),
                              )
                            : gridView
                            ? _grid(visible)
                            : ListView(
                                children: [
                                  for (final video in visible)
                                    row(video, visible),
                                ],
                              ),
                        groups(false),
                        groups(true),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class DeviceVideoPlayback extends StatefulWidget {
  const DeviceVideoPlayback({
    super.key,
    required this.videos,
    required this.initialIndex,
  });
  final List<DeviceVideo> videos;
  final int initialIndex;
  @override
  State<DeviceVideoPlayback> createState() => _DeviceVideoPlaybackState();
}

class _DeviceVideoPlaybackState extends State<DeviceVideoPlayback>
    with WidgetsBindingObserver {
  static const media = MethodChannel('sornaz/story_media');
  static const controls = MethodChannel('sornaz/video_controls');
  VideoPlayerController? player;
  late int index;
  int generation = 0;
  String? error;
  bool changing = false;
  bool controlsVisible = true, muted = false, shuffle = false;
  bool adjustingBrightness = false, adjustingVolume = false, landscape = false;
  VideoRepeatMode repeatMode = VideoRepeatMode.off;
  double volume = .5, brightness = .5, speed = 1;
  final abRepeat = AbRepeat();
  Timer? sleepTimer, chromeTimer, countdownTimer;
  DateTime? sleepDeadline;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    index = widget.initialIndex;
    VolumeController().showSystemUI = false;
    VolumeController().getVolume().then((v) {
      if (mounted) setState(() => volume = v);
    });
    controls.invokeMethod<double>('getBrightness').then((v) {
      if (mounted && v != null) setState(() => brightness = v);
    });
    load(index);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) player?.pause();
  }

  Future<void> load(int at) async {
    if (at < 0 || at >= widget.videos.length) return;
    final request = ++generation;
    final old = player;
    setState(() {
      changing = true;
      player = null;
      index = at;
      error = null;
    });
    old?.removeListener(update);
    await old?.dispose();
    final next = VideoPlayerController.contentUri(
      Uri.parse(widget.videos[at].uri),
    );
    try {
      await next.initialize();
      if (!mounted || request != generation) {
        await next.dispose();
        return;
      }
      setState(() {
        player = next;
        changing = false;
      });
      next.addListener(update);
      await next.play();
      await next.setPlaybackSpeed(speed);
      _hideChromeLater();
    } catch (_) {
      await next.dispose();
      if (mounted && request == generation)
        setState(() {
          changing = false;
          error = socialText(
            context,
            'پخش این ویدیو ممکن نیست',
            'Could not play this video',
          );
        });
    }
  }

  void update() {
    if (!mounted) return;
    setState(() {});
    if (abRepeat.shouldLoop(player!.value.position)) {
      player!.seekTo(abRepeat.start!);
    }
    if (!changing && player!.value.isCompleted) {
      if (repeatMode == VideoRepeatMode.one) {
        player!.seekTo(Duration.zero);
        player!.play();
        return;
      }
      if (shuffle && widget.videos.length > 1) {
        load(Random().nextInt(widget.videos.length));
        return;
      }
      if (index + 1 < widget.videos.length) {
        load(index + 1);
        return;
      }
      if (repeatMode == VideoRepeatMode.all ||
          PlayerSettings.instance.listEnd == ListEndAction.restart)
        load(0);
    }
  }

  void _hideChromeLater() {
    chromeTimer?.cancel();
    chromeTimer = Timer(const Duration(seconds: 4), () {
      if (mounted && player?.value.isPlaying == true)
        setState(() => controlsVisible = false);
    });
  }

  Future<void> seekBy(int seconds) async {
    final p = player;
    if (p == null) return;
    final value = p.value.position + Duration(seconds: seconds);
    await p.seekTo(
      value < Duration.zero
          ? Duration.zero
          : value > p.value.duration
          ? p.value.duration
          : value,
    );
  }

  Future<void> setVolume(double value) async {
    value = value.clamp(0, 1);
    setState(() {
      volume = value;
      muted = value == 0;
    });
    VolumeController().setVolume(value, showSystemUI: false);
  }

  Future<void> setBrightness(double value) async {
    value = value.clamp(.05, 1);
    setState(() => brightness = value);
    await controls.invokeMethod('setBrightness', {'value': value});
  }

  Future<void> screenshot() async {
    try {
      await SystemSound.play(SystemSoundType.click);
      final bytes = await media.invokeMethod<Uint8List>('thumbnail', {
        'uri': widget.videos[index].uri,
        'video': true,
        'size': 1440,
        'timeMs': player!.value.position.inMilliseconds,
      });
      if (bytes == null) return;
      final draft = await media.invokeMapMethod<String, dynamic>('writeImage', {
        'bytes': bytes,
      });
      if (draft == null) return;
      final allowed = await media.invokeMethod<bool>('savePermission') ?? false;
      if (!allowed) return;
      await media.invokeMethod('save', {'path': draft['path'], 'video': false});
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              socialText(context, 'تصویر ویدیو ذخیره شد', 'Video frame saved'),
            ),
          ),
        );
    } catch (e) {
      if (mounted) socialError(context, e);
    }
  }

  Future<void> chooseSpeed() => showPlaybackSpeedDialog(
    context,
    speed: speed,
    presets: const [.5, .75, 1, 1.25, 1.5, 2],
    onChanged: (value) {
      speed = value;
      player?.setPlaybackSpeed(value);
      if (mounted) setState(() {});
    },
  );

  Future<void> chooseSleep() async {
    final minutes = await showDialog<int>(
      context: context,
      builder: (c) => SimpleDialog(
        title: Text(
          socialText(c, 'تایمر خواب', 'Sleep timer'),
          style: const TextStyle(fontSize: 14),
        ),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(c, 0),
            child: Text(socialText(c, 'غیرفعال', 'Off')),
          ),
          for (var m = 5; m <= 60; m += 5)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(c, m),
              child: Text('$m ${socialText(c, 'دقیقه', 'minutes')}'),
            ),
        ],
      ),
    );
    if (minutes == null) return;
    sleepTimer?.cancel();
    countdownTimer?.cancel();
    sleepDeadline = minutes > 0
        ? DateTime.now().add(Duration(minutes: minutes))
        : null;
    if (minutes > 0) {
      sleepTimer = Timer(Duration(minutes: minutes), () {
        player?.pause();
        countdownTimer?.cancel();
        sleepDeadline = null;
        if (mounted) setState(() {});
      });
      countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
      });
    }
    if (mounted) setState(() {});
  }

  void cycleRepeat() => setState(() {
    repeatMode = VideoRepeatMode
        .values[(repeatMode.index + 1) % VideoRepeatMode.values.length];
  });

  Future<void> rotate() async {
    landscape = !landscape;
    await SystemChrome.setPreferredOrientations(
      landscape
          ? [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]
          : [DeviceOrientation.portraitUp],
    );
    if (mounted) setState(() {});
  }

  String get sleepRemaining {
    final remaining =
        sleepDeadline?.difference(DateTime.now()) ?? Duration.zero;
    if (remaining <= Duration.zero) return '';
    final minutes = remaining.inMinutes.toString().padLeft(2, '0');
    final seconds = (remaining.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  void dragUpdate(DragUpdateDetails d, double width) {
    final delta = -d.delta.dy / 220;
    if (d.localPosition.dx < width / 2)
      setBrightness(brightness + delta);
    else
      setVolume(volume + delta);
  }

  void dragStart(DragStartDetails d, double width) {
    chromeTimer?.cancel();
    setState(() {
      adjustingBrightness = d.localPosition.dx < width / 2;
      adjustingVolume = !adjustingBrightness;
    });
  }

  void dragEnd(DragEndDetails _) {
    setState(() {
      adjustingBrightness = false;
      adjustingVolume = false;
    });
    _hideChromeLater();
  }

  Future<void> horizontalSpeed(LongPressStartDetails d, double width) async {
    speed = d.localPosition.dx < width / 2 ? .5 : 2;
    await player?.setPlaybackSpeed(speed);
    if (mounted) setState(() {});
  }

  Future<void> resetSpeed(LongPressEndDetails _) async {
    speed = 1;
    await player?.setPlaybackSpeed(1);
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    generation++;
    WidgetsBinding.instance.removeObserver(this);
    player?.removeListener(update);
    player?.dispose();
    sleepTimer?.cancel();
    countdownTimer?.cancel();
    chromeTimer?.cancel();
    controls.invokeMethod('resetBrightness');
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }

  Widget sideLevel({required bool left}) => Positioned(
    top: 90,
    bottom: 90,
    left: left ? 16 : null,
    right: left ? null : 16,
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '${((left ? brightness : volume) * 100).round()}%',
          style: const TextStyle(color: Colors.white, fontSize: 12),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 180,
          child: RotatedBox(
            quarterTurns: 1,
            child: Slider(
              value: left ? brightness : volume,
              onChanged: left ? setBrightness : setVolume,
            ),
          ),
        ),
        if (!left)
          IconButton(
            onPressed: () => setVolume(muted ? .5 : 0),
            icon: Icon(
              muted ? Icons.volume_off : Icons.volume_up,
              color: Colors.white,
            ),
          ),
        if (left) const Icon(Icons.brightness_6_outlined, color: Colors.white),
      ],
    ),
  );
  Widget tool(
    IconData icon,
    String label,
    VoidCallback action, {
    bool active = false,
  }) => IconButton(
    tooltip: label,
    onPressed: action,
    icon: Icon(
      icon,
      color: active ? Theme.of(context).colorScheme.primary : Colors.white,
    ),
  );
  @override
  Widget build(BuildContext context) => PopScope(
    onPopInvokedWithResult: (_, __) {
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    },
    child: Scaffold(
      backgroundColor: Colors.black,
      body: error != null
          ? Center(
              child: TextButton(
                onPressed: () => load(index),
                child: Text(error!),
              ),
            )
          : player == null
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(
              builder: (context, box) => GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  setState(() => controlsVisible = !controlsVisible);
                  if (controlsVisible) _hideChromeLater();
                },
                onVerticalDragStart: (d) => dragStart(d, box.maxWidth),
                onVerticalDragUpdate: (d) => dragUpdate(d, box.maxWidth),
                onVerticalDragEnd: dragEnd,
                onLongPressStart: (d) => horizontalSpeed(d, box.maxWidth),
                onLongPressEnd: resetSpeed,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Center(
                      child: AspectRatio(
                        aspectRatio: player!.value.aspectRatio,
                        child: VideoPlayer(player!),
                      ),
                    ),
                    if (controlsVisible) ...[
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: SafeArea(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                height: 52,
                                child: ListView(
                                  scrollDirection: Axis.horizontal,
                                  children: [
                                    const BackButton(color: Colors.white),
                                    tool(
                                      Icons.screenshot_outlined,
                                      socialText(
                                        context,
                                        'اسکرین‌شات',
                                        'Screenshot',
                                      ),
                                      screenshot,
                                    ),
                                    tool(
                                      Icons.speed,
                                      socialText(context, 'سرعت پخش', 'Speed'),
                                      chooseSpeed,
                                      active: speed != 1,
                                    ),
                                    tool(
                                      Icons.screen_rotation,
                                      socialText(
                                        context,
                                        'چرخش صفحه',
                                        'Rotate',
                                      ),
                                      rotate,
                                      active: landscape,
                                    ),
                                    tool(
                                      Icons.graphic_eq,
                                      socialText(
                                        context,
                                        'اکولایزر',
                                        'Equalizer',
                                      ),
                                      () => showModalBottomSheet(
                                        context: context,
                                        isScrollControlled: true,
                                        builder: (_) => const SizedBox(
                                          height: 520,
                                          child: EqualizerTab(),
                                        ),
                                      ),
                                    ),
                                    tool(
                                      Icons.bedtime_outlined,
                                      socialText(
                                        context,
                                        'تایمر خواب',
                                        'Sleep timer',
                                      ),
                                      chooseSleep,
                                      active: sleepTimer?.isActive == true,
                                    ),
                                    tool(
                                      repeatMode == VideoRepeatMode.one
                                          ? Icons.repeat_one
                                          : Icons.repeat,
                                      repeatMode == VideoRepeatMode.one
                                          ? socialText(
                                              context,
                                              'تکرار ویدیو',
                                              'Repeat video',
                                            )
                                          : repeatMode == VideoRepeatMode.all
                                          ? socialText(
                                              context,
                                              'تکرار لیست',
                                              'Repeat list',
                                            )
                                          : socialText(
                                              context,
                                              'تکرار خاموش',
                                              'Repeat off',
                                            ),
                                      cycleRepeat,
                                      active: repeatMode != VideoRepeatMode.off,
                                    ),
                                    tool(
                                      Icons.loop,
                                      socialText(
                                        context,
                                        'حلقه بخش',
                                        'Section loop',
                                      ),
                                      () {
                                        setState(() {
                                          abRepeat.cycle(
                                            player!.value.position,
                                          );
                                        });
                                      },
                                      active: abRepeat.start != null,
                                    ),
                                    tool(
                                      Icons.shuffle,
                                      socialText(
                                        context,
                                        'پخش تصادفی',
                                        'Shuffle',
                                      ),
                                      () => setState(() => shuffle = !shuffle),
                                      active: shuffle,
                                    ),
                                  ],
                                ),
                              ),
                              if (sleepRemaining.isNotEmpty)
                                Text(
                                  sleepRemaining,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 9,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: SafeArea(
                          top: false,
                          child: Column(
                            children: [
                              Directionality(
                                textDirection: TextDirection.ltr,
                                child: AbTrack(
                                  repeat: abRepeat,
                                  duration: player!.value.duration,
                                  horizontalPadding: 0,
                                  child: VideoProgressIndicator(
                                    player!,
                                    allowScrubbing: true,
                                    colors: VideoProgressColors(
                                      playedColor: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                      bufferedColor: Theme.of(context)
                                          .colorScheme
                                          .primary
                                          .withValues(alpha: .28),
                                      backgroundColor: Colors.white24,
                                    ),
                                    padding: EdgeInsets.zero,
                                  ),
                                ),
                              ),
                              Text(
                                '${player!.value.position.toString().split('.').first} / ${player!.value.duration.toString().split('.').first}',
                                style: const TextStyle(color: Colors.white),
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  IconButton(
                                    color: Colors.white,
                                    onPressed: () => seekBy(10),
                                    icon: const Icon(Icons.forward_10),
                                  ),
                                  IconButton(
                                    color: Colors.white,
                                    onPressed: index + 1 < widget.videos.length
                                        ? () => load(index + 1)
                                        : null,
                                    icon: const Icon(Icons.skip_next),
                                  ),
                                  IconButton(
                                    color: Colors.white,
                                    onPressed: () => player!.value.isPlaying
                                        ? player!.pause()
                                        : player!.play(),
                                    icon: Icon(
                                      player!.value.isPlaying
                                          ? Icons.pause
                                          : Icons.play_arrow,
                                    ),
                                  ),
                                  IconButton(
                                    color: Colors.white,
                                    onPressed: index > 0
                                        ? () => load(index - 1)
                                        : null,
                                    icon: const Icon(Icons.skip_previous),
                                  ),
                                  IconButton(
                                    color: Colors.white,
                                    onPressed: () => seekBy(-10),
                                    icon: const Icon(Icons.replay_10),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    if (adjustingBrightness) sideLevel(left: true),
                    if (adjustingVolume) sideLevel(left: false),
                    if (speed != 1)
                      Center(
                        child: IgnorePointer(
                          child: Text(
                            '${speed}x',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
    ),
  );
}
