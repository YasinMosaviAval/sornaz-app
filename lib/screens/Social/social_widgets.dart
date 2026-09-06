import 'package:flutter/material.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import 'package:sornaz/helpers/app_colors.dart';
import 'package:sornaz/helpers/app_data.dart';
import 'package:video_player/video_player.dart';
import 'social_api.dart';

String socialText(BuildContext context, String fa, String en) =>
    Localizations.localeOf(context).languageCode == 'fa' ? fa : en;
void socialError(BuildContext context, Object error) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
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
    this.bottom,
    this.floatingActionButton,
  });
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
            primary: data.isDark
                ? const Color(0xffd3ae32)
                : const Color(0xff0064fb),
          ),
      fontFamily: data.fontFamily,
      scaffoldBackgroundColor: data.isDark ? Colors.black : Colors.white,
    );
    return Theme(
      data: theme,
      child: Scaffold(
        appBar: AppBar(title: Text(title), actions: actions),
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
    return Image.network(
      api.media(path!),
      headers: api.headers,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (_, __, ___) => fallback,
    );
  }
}

class SocialAvatar extends StatelessWidget {
  const SocialAvatar({
    super.key,
    required this.api,
    required this.user,
    this.size = 48,
    this.story = false,
  });
  final SocialApi api;
  final Json user;
  final double size;
  final bool story;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(3),
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      border: Border.all(
        color: story ? const Color(0xffcc338c) : Theme.of(context).dividerColor,
        width: story ? 2 : 1,
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
  );
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
          Text(text, textAlign: TextAlign.center),
          if (onRetry != null)
            TextButton(
              onPressed: onRetry,
              child: Text(socialText(context, 'تلاش دوباره', 'Retry')),
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
  });
  final File? localFile;
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

  @override
  Widget build(BuildContext context) {
    if (failed) return const SocialEmpty('پخش ویدیو ممکن نشد.');
    final c = controller;
    if (c == null || !c.value.isInitialized)
      return const SizedBox(
        height: 180,
        child: Center(child: CircularProgressIndicator()),
      );
    return ValueListenableBuilder<VideoPlayerValue>(
      valueListenable: c,
      builder: (_, value, __) => Column(
        children: [
          AspectRatio(aspectRatio: value.aspectRatio, child: VideoPlayer(c)),
          Row(
            children: [
              IconButton(
                tooltip: value.isPlaying ? 'توقف' : 'پخش',
                onPressed: () => value.isPlaying ? c.pause() : c.play(),
                icon: Icon(value.isPlaying ? Icons.pause : Icons.play_arrow),
              ),
              Expanded(child: VideoProgressIndicator(c, allowScrubbing: true)),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  '${value.position.inMinutes}:${(value.position.inSeconds % 60).toString().padLeft(2, '0')}',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
