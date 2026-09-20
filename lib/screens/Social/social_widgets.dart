import 'story_seen.dart';
import 'story_page.dart';
import 'package:sornaz/screens/Authentication/providers/auth_session.dart';
import 'package:sornaz/components/scroll_aware_scaffold.dart';
import 'package:sornaz/components/app_top_bar_direction.dart';
import 'package:sornaz/components/main_tab_scaffold.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sornaz/helpers/app_strings.dart';
import 'package:sornaz/helpers/app_translations.dart';
import 'package:sornaz/components/app_text.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'course_cache.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import 'package:sornaz/helpers/app_colors.dart';
import 'package:sornaz/helpers/app_data.dart';
import 'package:video_player/video_player.dart';
import 'social_api.dart';

String socialText(BuildContext context, String fa, String en) =>
    AppStrings.learningEn.containsKey(en)
    ? en.translate(context)
    : (Localizations.localeOf(context).languageCode == 'fa' ? fa : en);
void socialError(BuildContext context, Object error) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: AppText(
        error is SocialException
            ? error.message
            : socialText(
                context,
                'ارتباط برقرار نشد. دوباره تلاش کنید.',
                'Connection failed. Please try again.',
              ),
      ),
    ),
  );
}

Future<T?> socialPush<T>(BuildContext context, Widget page) =>
    Navigator.of(context).push<T>(MaterialPageRoute(builder: (_) => page));

class SocialScaffold extends StatelessWidget {
  const SocialScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.appBar,
    this.tabIndex,
    this.drawer,
    this.bottom,
    this.floatingActionButton,
  });
  final int? tabIndex;
  final PreferredSizeWidget? appBar;
  final Widget? drawer;
  final String title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? bottom, floatingActionButton;
  @override
  Widget build(BuildContext context) {
    final data = context.watch<AppData>();
    final theme = ThemeData(
      useMaterial3: true,
      brightness: data.isDark ? Brightness.dark : Brightness.light,
      colorScheme:
          ColorScheme.fromSeed(
            seedColor: AppColors.primary_light,
            brightness: data.isDark ? Brightness.dark : Brightness.light,
          ).copyWith(
            surface: data.isDark
                ? const Color(0xff141414)
                : const Color(0xfff6f6f6),
            onSurface: data.isDark ? Colors.white : Colors.black,
            primary: data.accent,
          ),
      fontFamily: data.fontFamily,
      scaffoldBackgroundColor: data.isDark ? Colors.black : Colors.white,
    );
    return Theme(
      data: theme,
      child: tabIndex != null
          ? MainTabScaffold(
              index: tabIndex!,
              appBar:
                  appBar ??
                  AppTopBarDirection(
                    child: AppBar(
                      titleSpacing: 0,
                      centerTitle: false,
                      title: AppText(title),
                      actions: actions,
                    ),
                  ),
              drawer: drawer,
              body: body,
              bottomNavigationBar: bottom,
              floatingActionButton: floatingActionButton,
            )
          : ScrollAwareScaffold(
              appBar:
                  appBar ??
                  AppTopBarDirection(
                    child: AppBar(title: AppText(title), actions: actions),
                  ),
              drawer: drawer,
              body: body,
              bottomNavigationBar: bottom,
              floatingActionButton: floatingActionButton,
            ),
    );
  }
}

class SocialImage extends StatelessWidget {
  const SocialImage({
    super.key,
    required this.api,
    this.path,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  });
  final SocialApi api;
  final String? path;
  final double? width, height;
  final BoxFit fit;
  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      width: width,
      height: height,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      alignment: Alignment.center,
      child: Icon(
        Icons.music_note_outlined,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
    if (path == null || path!.isEmpty) return fallback;
    return CachedNetworkImage(
      imageUrl: api.media(path!),
      cacheKey: '${CourseCache.account(api.token)}:${api.media(path!)}',
      httpHeaders: api.headers,
      width: width,
      height: height,
      fit: fit,
      errorWidget: (_, __, ___) => fallback,
    );
  }
}

String socialUserName(Json user) {
  final value = (user['username'] ?? user['name'] ?? '').toString();
  return value.contains('@') ? value.split('@').first : value;
}

class SocialAvatar extends StatelessWidget {
  const SocialAvatar({
    super.key,
    required this.api,
    required this.user,
    this.size = 48,
    this.story = false,
    this.seen = false,
    this.ringWidth,
    this.showEmptyRing = true,
  });
  final SocialApi api;
  final Json user;
  final double size;
  final bool story, seen, showEmptyRing;
  final double? ringWidth;
  @override
  Widget build(BuildContext context) {
    final account = context.watch<AuthSession?>()?.user?.id ?? 0;
    final viewed = StorySeen.forAccount(account);
    final stories = user['stories'] is List
        ? objects(user['stories'])
        : <Json>[];
    return AnimatedBuilder(
      animation: viewed,
      builder: (context, _) {
        final active = stories.isNotEmpty || story;
        final read = stories.isNotEmpty
            ? stories.every((s) => viewed.ids.contains(s['id'].toString()))
            : seen;
        return InkWell(
          customBorder: const CircleBorder(),
          onTap: stories.isEmpty
              ? null
              : () async {
                  await viewed.load();
                  if (!context.mounted) return;
                  final first = stories.indexWhere(
                    (s) => !viewed.ids.contains(s['id'].toString()),
                  );
                  await socialPush(
                    context,
                    StoryPage(
                      api: api,
                      stories: [
                        for (final s in stories) {...s, 'author': user},
                      ],
                      initialIndex: first < 0 ? 0 : first,
                      seen: viewed.ids,
                      onSeen: viewed.mark,
                    ),
                  );
                },
          child: Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: (!active && !showEmptyRing)
                  ? null
                  : Border.all(
                      color: active && !read
                          ? const Color(0xffcc338c)
                          : Colors.grey,
                      width: ringWidth ?? (active ? 2 : 1),
                    ),
            ),
            child: ClipOval(
              child: SocialImage(
                api: api,
                path: user['avatar'] as String?,
                width: size,
                height: size,
              ),
            ),
          ),
        );
      },
    );
  }
}

class SocialEmpty extends StatelessWidget {
  const SocialEmpty(
    this.text, {
    super.key,
    this.onRetry,
    this.icon = Icons.music_note_outlined,
  });
  final String text;
  final VoidCallback? onRetry;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 46, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 16),
          AppText(text, textAlign: TextAlign.center),
          if (onRetry != null)
            TextButton(
              onPressed: onRetry,
              child: AppText(socialText(context, 'تلاش دوباره', 'Retry')),
            ),
        ],
      ),
    ),
  );
}

class SocialVideo extends StatefulWidget {
  const SocialVideo({
    super.key,
    required this.api,
    required this.path,
    this.localFile,
    this.title = '',
    this.subtitle = '',
  });
  final File? localFile;
  final String title, subtitle;
  final SocialApi api;
  final String path;
  @override
  State<SocialVideo> createState() => _SocialVideoState();
}

class _SocialVideoState extends State<SocialVideo> with WidgetsBindingObserver {
  VideoPlayerController? controller;
  bool failed = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  Future<void> _load() async {
    final c = widget.localFile != null
        ? VideoPlayerController.file(widget.localFile!)
        : VideoPlayerController.networkUrl(
            Uri.parse(widget.api.media(widget.path)),
            httpHeaders: widget.api.headers,
          );
    controller = c;
    try {
      await c.initialize();
      if (mounted && controller == c) setState(() {});
    } catch (_) {
      if (mounted) setState(() => failed = true);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) controller?.pause();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    controller?.dispose();
    super.dispose();
  }

  Future<void> note() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    final me = widget.api.token.isEmpty
        ? <String, dynamic>{}
        : object(await widget.api.get('/me'));
    final key = 'video-note:${number(me['id'])}:' + widget.path;
    final input = TextEditingController(text: prefs.getString(key) ?? '');
    final saved = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: AppText(socialText(d, 'یادداشت درس', 'Lesson note')),
        content: TextField(controller: input, maxLines: 5, maxLength: 3000),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(d, true),
            child: AppText(socialText(d, 'ذخیره', 'Save')),
          ),
        ],
      ),
    );
    if (saved == true) await prefs.setString(key, input.text);
    await Future<void>.delayed(const Duration(milliseconds: 300));
    input.dispose();
  }

  String clock(Duration d) =>
      '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';
  Widget player(BuildContext context, {bool full = false}) {
    final c = controller!;
    return ValueListenableBuilder<VideoPlayerValue>(
      valueListenable: c,
      builder: (context, v, _) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              AspectRatio(aspectRatio: v.aspectRatio, child: VideoPlayer(c)),
              PositionedDirectional(
                top: 12,
                start: 16,
                end: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(
                      widget.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    AppText(
                      widget.subtitle,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
              if (!v.isPlaying)
                IconButton.filled(
                  onPressed: c.play,
                  iconSize: 42,
                  icon: const Icon(Icons.play_arrow),
                ),
            ],
          ),
          VideoProgressIndicator(
            c,
            allowScrubbing: true,
            colors: VideoProgressColors(
              playedColor: Theme.of(context).colorScheme.primary,
            ),
          ),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              IconButton(
                tooltip: socialText(
                  context,
                  v.isPlaying ? 'توقف' : 'پخش',
                  v.isPlaying ? 'Pause' : 'Play',
                ),
                onPressed: () => v.isPlaying ? c.pause() : c.play(),
                icon: Icon(v.isPlaying ? Icons.pause : Icons.play_arrow),
              ),
              AppText(
                '${clock(v.position)} / ${clock(v.duration)}',
                style: const TextStyle(fontSize: 11),
              ),
              IconButton(
                onPressed: () => c.setVolume(v.volume == 0 ? 1 : 0),
                icon: Icon(v.volume == 0 ? Icons.volume_off : Icons.volume_up),
              ),
              IconButton(
                tooltip: socialText(context, 'یادداشت درس', 'Lesson note'),
                onPressed: note,
                icon: const Icon(Icons.note_add_outlined),
              ),
              PopupMenuButton<double>(
                tooltip: socialText(context, 'سرعت پخش', 'Playback speed'),
                initialValue: v.playbackSpeed,
                onSelected: c.setPlaybackSpeed,
                itemBuilder: (_) => [
                  for (final speed in [.5, .75, 1.0, 1.25, 1.5, 2.0])
                    PopupMenuItem(value: speed, child: AppText('${speed}x')),
                ],
                icon: const Icon(Icons.settings_outlined),
              ),
              IconButton(
                onPressed: () => full
                    ? Navigator.pop(context)
                    : Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (ctx) => ScrollAwareScaffold(
                            appBar: AppTopBarDirection(child: AppBar()),
                            body: Center(child: player(ctx, full: true)),
                          ),
                        ),
                      ),
                icon: Icon(full ? Icons.fullscreen_exit : Icons.fullscreen),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (failed)
      return SocialEmpty(
        socialText(context, 'پخش ویدیو ممکن نشد.', 'Unable to play video.'),
        onRetry: () {
          setState(() => failed = false);
          controller?.dispose();
          _load();
        },
      );
    if (controller?.value.isInitialized != true)
      return const SizedBox(
        height: 180,
        child: Center(child: CircularProgressIndicator()),
      );
    return player(context);
  }
}
