import 'package:sornaz/components/scroll_aware_scaffold.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'social_api.dart';
import 'social_widgets.dart';

List<List<Json>> groupStoriesByAuthor(
  List<Json> stories, {
  Set<String> seen = const {},
}) {
  final groups = <String, List<Json>>{};
  for (final story in stories) {
    final author = story['author'] is Map ? story['author'] as Map : const {};
    final owner =
        '${story['owner_id'] ?? author['id'] ?? author['username'] ?? story['id']}';
    groups.putIfAbsent(owner, () => []).add(story);
  }
  bool allSeen(List<Json> group) =>
      group.every((s) => seen.contains(s['id'].toString()));
  return [
    ...groups.values.where((g) => !allSeen(g)),
    ...groups.values.where(allSeen),
  ];
}

List<(Duration, Duration)> storySegments(Duration duration) {
  final total = duration.inMilliseconds;
  return [
    for (var start = 0; start < total; start += 60000)
      (
        Duration(milliseconds: start),
        Duration(milliseconds: math.min(start + 60000, total)),
      ),
  ];
}

class StoryPage extends StatefulWidget {
  const StoryPage({
    super.key,
    required this.api,
    required this.stories,
    this.initialIndex = 0,
    this.onSeen,
    this.controllerFactory,
  });
  final SocialApi api;
  final List<Json> stories;
  final int initialIndex;
  final ValueChanged<int>? onSeen;
  final VideoPlayerController Function(String)? controllerFactory;
  @override
  State<StoryPage> createState() => _StoryPageState();
}

class _StoryPageState extends State<StoryPage>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late int index = widget.initialIndex.clamp(
    0,
    math.max(0, widget.stories.length - 1),
  );
  int part = 0, generation = 0;
  final durations = <int, Duration>{};
  late final progress = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 7),
  );
  final reply = TextEditingController();
  final focus = FocusNode();
  VideoPlayerController? player;
  bool sending = false,
      holding = false,
      foreground = true,
      loading = false,
      failed = false,
      switching = false,
      closing = false;
  Json get story => widget.stories[index];
  bool get video => '${story['mime']}'.startsWith('video/');
  bool get running =>
      foreground &&
      !holding &&
      !focus.hasFocus &&
      !sending &&
      !loading &&
      !failed;
  List<(Duration, Duration)> get parts =>
      storySegments(durations[index] ?? Duration.zero);
  int count(int i) =>
      math.max(1, storySegments(durations[i] ?? Duration.zero).length);
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    progress.addStatusListener((status) {
      if (status == AnimationStatus.completed && !video) next();
    });
    focus.addListener(sync);
    if (widget.stories.isNotEmpty) load();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    foreground = state == AppLifecycleState.resumed;
    sync();
  }

  void sync() {
    if (!mounted || closing || widget.stories.isEmpty) return;
    if (video) {
      final c = player;
      if (c == null || !c.value.isInitialized) return;
      if (running) {
        unawaited(
          c.play().catchError((Object _) {
            if (mounted) setState(() => failed = true);
          }),
        );
      } else {
        unawaited(c.pause());
      }
    } else {
      running ? progress.forward() : progress.stop();
    }
  }

  Future<void> load({bool lastPart = false}) async {
    final request = ++generation;
    progress.stop();
    progress.value = 0;
    final old = player;
    player = null;
    old?.removeListener(tick);
    if (old != null) unawaited(old.dispose());
    loading = video;
    failed = false;
    part = 0;
    if (!video) {
      widget.onSeen?.call(number(story['id']));
      sync();
      return;
    }
    final c =
        widget.controllerFactory?.call('${story['media']}') ??
        VideoPlayerController.networkUrl(
          Uri.parse(widget.api.media('${story['media']}')),
          httpHeaders: widget.api.headers,
        );
    player = c;
    try {
      await c.initialize();
      if (!mounted || request != generation) return;
      durations[index] = c.value.duration;
      if (parts.isEmpty) throw const FormatException('Empty story video');
      if (lastPart) part = parts.length - 1;
      await c.setLooping(false);
      await c.seekTo(parts[part].$1);
      if (!mounted || request != generation) return;
      c.addListener(tick);
      setState(() => loading = false);
      widget.onSeen?.call(number(story['id']));
      sync();
    } catch (_) {
      if (mounted && request == generation)
        setState(() {
          loading = false;
          failed = true;
        });
    }
  }

  void tick() {
    final c = player;
    if (!mounted ||
        c == null ||
        loading ||
        switching ||
        parts.isEmpty ||
        closing)
      return;
    if (c.value.hasError) {
      if (!failed) setState(() => failed = true);
      return;
    }
    final range = parts[part], length = (range.$2 - range.$1).inMilliseconds;
    progress.value = ((c.value.position - range.$1).inMilliseconds / length)
        .clamp(0, 1);
    if (running && (c.value.position >= range.$2 || c.value.isCompleted)) {
      switching = true;
      scheduleMicrotask(() {
        if (mounted && !closing) {
          switching = false;
          next(1, true);
        }
      });
    }
  }

  Future<void> next([int direction = 1, bool automatic = false]) async {
    if (closing || switching || widget.stories.isEmpty) return;
    final c = player;
    if (video &&
        parts.isNotEmpty &&
        part + direction >= 0 &&
        part + direction < parts.length) {
      switching = true;
      setState(() => part += direction);
      progress.value = 0;
      try {
        if (!automatic) await c?.seekTo(parts[part].$1);
      } finally {
        switching = false;
      }
      if (automatic) tick();
      sync();
      return;
    }
    final target = index + direction;
    if (target < 0) {
      if (video) await c?.seekTo(Duration.zero);
      progress.value = 0;
      sync();
      return;
    }
    if (target >= widget.stories.length) {
      closing = true;
      await player?.pause();
      if (mounted) Navigator.pop(context);
      return;
    }
    setState(() => index = target);
    await load(lastPart: direction < 0);
  }

  Future<void> sendReply() async {
    if (reply.text.trim().isEmpty || sending) return;
    final body = reply.text.trim(),
        owner = story['owner_id'] ?? story['author']['id'];
    setState(() => sending = true);
    sync();
    try {
      final c = object(
        await widget.api.post('/conversations', {'user_id': '$owner'}),
      );
      await widget.api.post('/conversations/${c['id']}/messages', {
        'body': 'پاسخ به استوری: $body',
      });
      if (mounted) {
        reply.clear();
        focus.unfocus();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(socialText(context, 'پاسخ ارسال شد.', 'Reply sent.')),
          ),
        );
      }
    } catch (e) {
      if (mounted) socialError(context, e);
    } finally {
      if (mounted) {
        setState(() => sending = false);
        sync();
      }
    }
  }

  @override
  void dispose() {
    closing = true;
    generation++;
    WidgetsBinding.instance.removeObserver(this);
    player?.removeListener(tick);
    player?.dispose();
    focus.removeListener(sync);
    focus.dispose();
    reply.dispose();
    progress.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.stories.isEmpty)
      return const ScrollAwareScaffold(backgroundColor: Colors.black);
    final c = player;
    return ScrollAwareScaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: false,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (video && c != null && c.value.isInitialized)
            ClipRect(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: c.value.size.width,
                  height: c.value.size.height,
                  child: VideoPlayer(c),
                ),
              ),
            )
          else if (!video)
            SocialImage(
              api: widget.api,
              path: story['media'],
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
            ),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: (d) => next(
              d.localPosition.dx < MediaQuery.sizeOf(context).width / 3
                  ? -1
                  : 1,
            ),
            onLongPressStart: (_) {
              holding = true;
              sync();
            },
            onLongPressEnd: (_) {
              holding = false;
              sync();
            },
          ),
          if (loading)
            const IgnorePointer(
              child: Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
          if (failed)
            Center(
              child: TextButton(
                onPressed: () => load(),
                child: Text(
                  socialText(context, 'تلاش دوباره', 'Retry'),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black54, Colors.transparent],
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    AnimatedBuilder(
                      animation: progress,
                      builder: (context, _) => Padding(
                        padding: const EdgeInsets.all(8),
                        child: Directionality(
                          textDirection: TextDirection.ltr,
                          child: Row(
                            children: [
                              for (var i = 0; i < widget.stories.length; i++)
                                for (var j = 0; j < count(i); j++)
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 2,
                                      ),
                                      child: LinearProgressIndicator(
                                        value:
                                            i < index ||
                                                (i == index && j < part)
                                            ? 1
                                            : i == index && j == part
                                            ? progress.value
                                            : 0,
                                        minHeight: 2,
                                        color: Colors.white,
                                        backgroundColor: Colors.white24,
                                      ),
                                    ),
                                  ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        const SizedBox(width: 12),
                        SocialAvatar(
                          api: widget.api,
                          user: object(story['author']),
                          size: 30,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${story['author']['name']}',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close, color: Colors.white),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: MediaQuery.viewInsetsOf(context).bottom,
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black54],
                ),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if ('${story['body'] ?? ''}'.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(
                            '${story['body']}',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      if (story['author']['isMe'] != true)
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: reply,
                                focusNode: focus,
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  hintText: socialText(
                                    context,
                                    'پاسخ به استوری…',
                                    'Reply to story…',
                                  ),
                                  hintStyle: const TextStyle(
                                    color: Colors.white60,
                                  ),
                                  enabledBorder: const OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: Colors.white54,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: sending ? null : sendReply,
                              icon: const Icon(
                                Icons.send_outlined,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
