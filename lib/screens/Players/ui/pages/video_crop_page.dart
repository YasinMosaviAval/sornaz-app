import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:sornaz/components/app_top_bar_direction.dart';
import 'package:sornaz/components/audio_crop_page.dart';
import 'package:sornaz/screens/Social/social_widgets.dart';

class VideoCropPage extends StatefulWidget {
  const VideoCropPage({
    super.key,
    required this.uri,
    required this.name,
    this.controllerFactory,
  });
  final String uri, name;
  final VideoPlayerController Function()? controllerFactory;
  @override
  State<VideoCropPage> createState() => _VideoCropPageState();
}

class _VideoCropPageState extends State<VideoCropPage> {
  late final player =
      widget.controllerFactory?.call() ??
      VideoPlayerController.contentUri(Uri.parse(widget.uri));
  RangeValues range = const RangeValues(0, 1);
  bool ready = false, busy = false;
  String? error;
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      await player.initialize();
      if (!mounted) return;
      setState(() {
        range = RangeValues(0, player.value.duration.inMilliseconds.toDouble());
        ready = range.end > 0;
      });
      player.addListener(position);
    } catch (_) {
      if (mounted)
        setState(
          () => error = socialText(
            context,
            'ویدیو باز نشد',
            'Could not open video',
          ),
        );
    }
  }

  void position() {
    if (player.value.isPlaying &&
        player.value.position.inMilliseconds >= range.end)
      player.pause();
  }

  @override
  void dispose() {
    player.removeListener(position);
    player.dispose();
    super.dispose();
  }

  Future<void> save() async {
    setState(() {
      busy = true;
      error = null;
    });
    String? staged;
    try {
      await player.pause();
      staged = await audioCropChannel.invokeMethod<String>('render', {
        'source': widget.uri,
        'start': range.start.round(),
        'end': range.end.round(),
        'video': true,
      });
      if (staged == null) throw StateError('Missing output');
      await const MethodChannel(
        'sornaz/device_videos',
      ).invokeMethod('saveCrop', {'staged': staged});
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted)
        setState(
          () => error = socialText(
            context,
            'برش ویدیو ذخیره نشد',
            'Could not save cropped video',
          ),
        );
    } finally {
      if (staged != null) {
        try {
          final file = File(staged);
          if (await file.exists()) await file.delete();
        } catch (_) {}
      }
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !busy,
    child: Scaffold(
      appBar: AppTopBarDirection(
        child: AppBar(
          title: Text(socialText(context, 'برش ویدیو', 'Trim video')),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ready
                ? Center(
                    child: AspectRatio(
                      aspectRatio: player.value.aspectRatio,
                      child: VideoPlayer(player),
                    ),
                  )
                : Center(
                    child: error == null
                        ? const CircularProgressIndicator()
                        : Text(error!),
                  ),
          ),
          if (ready) ...[
            Directionality(
              textDirection: TextDirection.ltr,
              child: RangeSlider(
                values: range,
                max: player.value.duration.inMilliseconds.toDouble(),
                onChanged: busy
                    ? null
                    : (value) {
                        if (value.end - value.start >= 100)
                          setState(() => range = value);
                      },
              ),
            ),
            Text(
              '${(range.start / 1000).toStringAsFixed(2)} — ${(range.end / 1000).toStringAsFixed(2)}',
              textDirection: TextDirection.ltr,
            ),
            TextButton.icon(
              onPressed: busy
                  ? null
                  : () async {
                      await player.seekTo(
                        Duration(milliseconds: range.start.round()),
                      );
                      await player.play();
                    },
              icon: const Icon(Icons.play_arrow),
              label: Text(socialText(context, 'پیش‌نمایش', 'Preview')),
            ),
            SafeArea(
              top: false,
              child: FilledButton(
                onPressed: busy ? null : save,
                child: Text(
                  socialText(
                    context,
                    'ذخیره به عنوان ویدیوی جدید',
                    'Save as new video',
                  ),
                ),
              ),
            ),
          ],
          if (busy) const LinearProgressIndicator(),
          if (error != null) Text(error!),
        ],
      ),
    ),
  );
}
