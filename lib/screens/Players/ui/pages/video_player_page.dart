import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:video_player/video_player.dart';
import 'package:sornaz/components/app_top_bar_direction.dart';
import 'package:sornaz/screens/Social/social_widgets.dart';
import '../../services/music_audio_handler.dart';
import '../../services/music_playlists.dart';
import 'playlists.dart';

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
    borderRadius: BorderRadius.circular(4),
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

class _VideoLibraryPageState extends State<VideoLibraryPage> {
  static const channel = MethodChannel('sornaz/device_videos');
  final store = MusicPlaylists(storagePrefix: 'video');
  List<DeviceVideo> videos = [];
  final expanded = <String>{};
  String query = '';
  String? error;
  bool loading = true;
  String t(String fa, String en) => socialText(context, fa, en);
  @override
  void initState() {
    super.initState();
    store.addListener(changed);
    load();
  }

  void changed() {
    if (mounted) setState(() {});
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
        dense: true,
        minVerticalPadding: 10,
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
        onTap: () => open(video, list),
        trailing: PopupMenuButton<String>(
          onSelected: (action) async {
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
    return ListView(
      children: [
        for (final e in groups.entries)
          if (query.isEmpty ||
              (playlists ? e.key : e.value.first.folder).toLowerCase().contains(
                query,
              ) ||
              e.value.any((v) => v.name.toLowerCase().contains(query))) ...[
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
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppTopBarDirection(
          child: AppBar(
            title: Text(t('پخش‌کننده ویدیو', 'Video player')),
            actions: [
              IconButton(
                tooltip: t('لیست پخش جدید', 'New playlist'),
                icon: const Icon(Icons.playlist_add),
                onPressed: () =>
                    createMusicPlaylist(context, collection: store),
              ),
              IconButton(
                tooltip: t('بازخوانی', 'Refresh'),
                onPressed: loading ? null : load,
                icon: const Icon(Icons.refresh),
              ),
            ],
            bottom: TabBar(
              tabs: [
                Tab(text: t('ویدیوها', 'Videos')),
                Tab(text: t('پوشه‌ها', 'Folders')),
                Tab(text: t('لیست پخش‌ها', 'Playlists')),
              ],
            ),
          ),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextField(
                onChanged: (v) =>
                    setState(() => query = v.trim().toLowerCase()),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: t('جستجوی ویدیو', 'Search videos'),
                ),
              ),
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
                      children: [
                        visible.isEmpty
                            ? Center(
                                child: Text(
                                  t('ویدیویی پیدا نشد', 'No videos found'),
                                ),
                              )
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
  VideoPlayerController? player;
  late int index;
  int generation = 0;
  String? error;
  bool changing = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    index = widget.initialIndex;
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
    if (!changing &&
        player!.value.isCompleted &&
        index + 1 < widget.videos.length)
      load(index + 1);
  }

  @override
  void dispose() {
    generation++;
    WidgetsBinding.instance.removeObserver(this);
    player?.removeListener(update);
    player?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.black,
    appBar: AppTopBarDirection(
      child: AppBar(title: Text(widget.videos[index].name)),
    ),
    body: error != null
        ? Center(
            child: TextButton(
              onPressed: () => load(index),
              child: Text(error!),
            ),
          )
        : player == null
        ? const Center(child: CircularProgressIndicator())
        : Column(
            children: [
              Expanded(
                child: Center(
                  child: AspectRatio(
                    aspectRatio: player!.value.aspectRatio,
                    child: VideoPlayer(player!),
                  ),
                ),
              ),
              Directionality(
                textDirection: TextDirection.ltr,
                child: VideoProgressIndicator(
                  player!,
                  allowScrubbing: true,
                  padding: const EdgeInsets.all(16),
                ),
              ),
              Text(
                '${player!.value.position.toString().split('.').first} / ${player!.value.duration.toString().split('.').first}',
                style: const TextStyle(color: Colors.white),
              ),
              SafeArea(
                top: false,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      color: Colors.white,
                      onPressed: index > 0 ? () => load(index - 1) : null,
                      icon: const Icon(Icons.skip_previous),
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
                      onPressed: index + 1 < widget.videos.length
                          ? () => load(index + 1)
                          : null,
                      icon: const Icon(Icons.skip_next),
                    ),
                  ],
                ),
              ),
            ],
          ),
  );
}
