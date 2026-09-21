import 'dart:convert';
import 'social_profile.dart';
import 'package:sornaz/components/app_top_bar_direction.dart';
import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import '../Authentication/providers/auth_session.dart';
import 'social_api.dart';
import 'social_widgets.dart';
import 'story_text_editor.dart';

class StoryMediaBridge {
  static const channel = MethodChannel('sornaz/story_media');
  Future<T?> call<T>(String method, [Map<String, dynamic>? args]) =>
      channel.invokeMethod<T>(method, args);
  Future<Uint8List?> thumbnail(Json item, {int size = 240, int time = 0}) =>
      call<Uint8List>('thumbnail', {
        'uri': item['uri'],
        'video': item['video'] == true,
        'size': size,
        'timeMs': time,
      });
}

String storyDuration(int milliseconds) {
  final seconds = milliseconds ~/ 1000;
  return seconds >= 3600
      ? '${seconds ~/ 3600}:${((seconds ~/ 60) % 60).toString().padLeft(2, '0')}:${(seconds % 60).toString().padLeft(2, '0')}'
      : '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
}

class StoryComposer extends StatefulWidget {
  const StoryComposer({super.key, required this.api});
  final SocialApi api;
  @override
  State<StoryComposer> createState() => _StoryComposerState();
}

class _StoryComposerState extends State<StoryComposer>
    with WidgetsBindingObserver {
  final bridge = StoryMediaBridge();
  final galleryScroll = ScrollController();
  final canvasKey = GlobalKey(), overlayKey = GlobalKey();
  final drafts = <String>{};
  final gallery = <Json>[];
  final stickers = <StorySticker>[];
  List<Json> mentions = [];
  bool exportingMetadata = false;
  Offset imageOffset = Offset.zero,
      gestureImageOffset = Offset.zero,
      gestureStart = Offset.zero;
  double imageScale = 1, gestureScale = 1;
  StorySticker? gestureSticker;
  final textPointers = <int, Offset>{};
  int? activeText;
  bool textWasPinched = false;
  StorySticker? pinchText;
  double pinchDistance = 0;
  Offset pinchCenter = Offset.zero;
  void textPointerDown(PointerDownEvent event) {
    if (textPointers.isEmpty) textWasPinched = false;
    textPointers[event.pointer] = event.position;
    if (activeText != null && textPointers.length == 2) {
      textWasPinched = true;
      final points = textPointers.values.toList();
      pinchText = stickers[activeText!];
      pinchDistance = (points[0] - points[1]).distance;
      pinchCenter = (points[0] + points[1]) / 2;
    }
  }

  void textPointerMove(PointerMoveEvent event) {
    textPointers[event.pointer] = event.position;
    if (busy ||
        activeText == null ||
        pinchText == null ||
        textPointers.length != 2 ||
        pinchDistance == 0)
      return;
    final points = textPointers.values.toList();
    final base = pinchText!;
    final center = (points[0] + points[1]) / 2;
    setState(
      () => stickers[activeText!] = base.transform(
        base.move(center - pinchCenter, frame).position,
        base.scale * (points[0] - points[1]).distance / pinchDistance,
      ),
    );
  }

  void textPointerUp(PointerEvent event) {
    textPointers.remove(event.pointer);
    if (textPointers.isEmpty) {
      activeText = null;
      pinchText = null;
    }
  }

  final photos = <StoryPhotoLayer>[];
  Json? selected;
  Uint8List? preview;
  VideoPlayerController? player;
  bool loading = true, more = true, busy = false, cover = true;
  String permission = '', caption = '', error = '';
  Size imageSize = Size.zero;
  Size frame = const Size(360, 640);
  String t(String fa, String en) => socialText(context, fa, en);
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    galleryScroll.addListener(loadNearEnd);
    requestGallery();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      player?.pause();
    } else if (!busy) {
      player?.play();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    galleryScroll.dispose();
    player?.dispose();
    unawaited(cleanup());
    super.dispose();
  }

  Future<void> cleanup() async {
    if (drafts.isNotEmpty) {
      try {
        await bridge.call('delete', {'paths': drafts.toList()});
      } catch (_) {}
    }
  }

  void loadNearEnd() {
    if (galleryScroll.hasClients &&
        galleryScroll.position.extentAfter < 800 &&
        more &&
        !loading)
      loadGallery();
  }

  Future<void> requestGallery() async {
    setState(() => loading = true);
    try {
      permission = await bridge.call<String>('permission') ?? 'denied';
      if (!mounted) return;
      gallery.clear();
      more = true;
      await loadGallery(initial: true);
    } catch (_) {
      if (mounted)
        setState(() {
          loading = false;
          error = t(
            'دسترسی به گالری ممکن نشد. دوباره تلاش کنید.',
            'Could not open the gallery. Please retry.',
          );
        });
    }
  }

  Future<void> loadGallery({bool initial = false}) async {
    if (!initial && (loading || !more)) return;
    setState(() => loading = true);
    try {
      final rows = objects(
        await bridge.call('gallery', {'offset': gallery.length}),
      );
      if (mounted)
        setState(() {
          gallery.addAll(rows);
          more = rows.length == 60;
          error = '';
        });
    } catch (_) {
      if (mounted)
        setState(
          () => error = t(
            'گالری در دسترس نیست. دسترسی به عکس‌ها و ویدیوها را بررسی کنید.',
            'Gallery unavailable. Check photo and video access.',
          ),
        );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> choose(Json? item) async {
    if (busy) return;
    setState(() => busy = true);
    Json? chosen;
    VideoPlayerController? next;
    try {
      final raw = await bridge.call(
        item == null ? 'camera' : 'select',
        item == null
            ? null
            : {'uri': item['uri'], 'video': item['video'] == true},
      );
      if (raw == null) return;
      chosen = object(raw);
      drafts.add('${chosen['path']}');
      if (!mounted) {
        await cleanup();
        return;
      }
      final image = await bridge.thumbnail(chosen, size: 1440);
      if (image == null) throw StateError('preview');
      final codec = await ui.instantiateImageCodec(image);
      final decoded = await codec.getNextFrame();
      imageSize = Size(
        decoded.image.width.toDouble(),
        decoded.image.height.toDouble(),
      );
      decoded.image.dispose();
      codec.dispose();
      if (chosen['video'] == true) {
        next = VideoPlayerController.contentUri(Uri.parse('${chosen['uri']}'));
        await next.initialize();
        await next.setLooping(true);
      }
      if (!mounted) {
        await next?.dispose();
        await cleanup();
        return;
      }
      await player?.dispose();
      player = next;
      setState(() {
        selected = chosen;
        preview = image;
        caption = '';
        mentions = [];
        stickers.clear();
        photos.clear();
        imageScale = 1;
        imageOffset = Offset.zero;
      });
      await player?.play();
    } catch (_) {
      if (next != null && next != player) await next.dispose();
      if (chosen != null) {
        try {
          await bridge.call('delete', {
            'paths': [chosen['path']],
          });
          drafts.remove(chosen['path']);
        } catch (_) {}
      }
      if (mounted) showError();
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  void showError() => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        t(
          'عملیات انجام نشد. دسترسی به فایل و فضای آزاد دستگاه را بررسی کنید و دوباره تلاش کنید.',
          'Could not complete the operation. Check media access and free space, then retry.',
        ),
      ),
    ),
  );
  Json get me {
    final user = context.read<AuthSession?>()?.user;
    return {
      'id': user?.id,
      'username': user?.username ?? '',
      'avatar': user?.avatar,
    };
  }

  Future<void> editCaption() async {
    final input = TextEditingController(text: caption);
    player?.pause();
    final value = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (c) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          MediaQuery.viewInsetsOf(c).bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: input,
              autofocus: true,
              maxLength: 500,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: t('یک عنوان اضافه کنید', 'Add a caption'),
              ),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(c, input.text.trim()),
              child: Text(t('تأیید', 'Done')),
            ),
          ],
        ),
      ),
    );
    if (mounted) {
      if (value != null) setState(() => caption = value);
      player?.play();
    }
    // The sheet's closing animation still uses its controller.
    Future.delayed(const Duration(milliseconds: 400), input.dispose);
  }

  Future<void> editText([int? index]) async {
    await player?.pause();
    try {
      final image = await bridge.thumbnail(
        selected!,
        size: 1440,
        time: player?.value.position.inMilliseconds ?? 0,
      );
      if (!mounted || image == null) return;
      final result = await Navigator.push<StorySticker>(
        context,
        MaterialPageRoute(
          builder: (_) => StoryTextEditor(
            image: image,
            cover: cover,
            initial: index == null ? null : stickers[index],
          ),
        ),
      );
      if (mounted && result != null)
        setState(() {
          if (index == null) {
            if (result.text.isNotEmpty) stickers.add(result);
          } else if (result.text.isEmpty) {
            stickers.removeAt(index);
          } else {
            stickers[index] = result;
          }
        });
    } catch (_) {
      if (mounted) showError();
    } finally {
      if (mounted) player?.play();
    }
  }

  Future<void> editMentions() async {
    player?.pause();
    final result = await showModalBottomSheet<List<Json>>(
      context: context,
      isScrollControlled: true,
      builder: (_) => StoryMentionPicker(api: widget.api, initial: mentions),
    );
    if (mounted) {
      if (result != null) setState(() => mentions = result);
      player?.play();
    }
  }

  Future<Uint8List> capture(GlobalKey key) async {
    await WidgetsBinding.instance.endOfFrame;
    final boundary =
        key.currentContext!.findRenderObject() as RenderRepaintBoundary;
    // Even output dimensions are required by H.264 encoders.
    final width = (720 / 2).round() * 2;
    final image = await boundary.toImage(
      pixelRatio: width / boundary.size.width,
    );
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    return data!.buffer.asUint8List();
  }

  Future<void> finish({required bool save}) async {
    if (busy || selected == null) return;
    setState(() => busy = true);
    await player?.pause();
    Json? output;
    try {
      if (save && await bridge.call<bool>('savePermission') != true) return;
      final video = selected!['video'] == true;
      setState(() => exportingMetadata = !save);
      final bytes = await capture(video ? overlayKey : canvasKey);
      output = object(
        await bridge.call(
          video ? 'exportVideo' : 'writeImage',
          video
              ? {'path': selected!['path'], 'overlay': bytes, 'cover': cover}
              : {'bytes': bytes},
        ),
      );
      drafts.add('${output['path']}');
      if (save) {
        await bridge.call('save', {'path': output['path'], 'video': video});
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                t('استوری در گالری ذخیره شد.', 'Story saved to your gallery.'),
              ),
            ),
          );
      } else {
        final media = await widget.api.upload(
          PlatformFile(
            name: '${output['name']}',
            path: '${output['path']}',
            size: number(output['size']),
          ),
        );
        await widget.api.post('/posts', {
          'kind': 'story',
          // Caption and mentions are rendered into the media, not repeated by viewers.
          'body': caption,
          'mention_ids': jsonEncode(
            mentions.map((u) => number(u['id'])).toList(),
          ),
          'media_id': '${media['id']}',
        });
        if (mounted) Navigator.pop(context, true);
      }
    } catch (_) {
      if (mounted) showError();
    } finally {
      if (output != null) {
        try {
          await bridge.call('delete', {
            'paths': [output['path']],
          });
          drafts.remove(output['path']);
        } catch (_) {}
      }
      if (mounted) {
        setState(() {
          busy = false;
          exportingMetadata = false;
        });
        player?.play();
      }
    }
  }

  Future<void> addPhoto() async {
    await player?.pause();
    final item = await showModalBottomSheet<Json>(
      context: context,
      isScrollControlled: true,
      builder: (c) => SizedBox(
        height: MediaQuery.sizeOf(c).height * .65,
        child: GridView.count(
          crossAxisCount: 3,
          children: [
            for (final photo in gallery.where((p) => p['video'] != true))
              StoryGalleryTile(
                bridge: bridge,
                item: photo,
                onTap: () => Navigator.pop(c, photo),
              ),
          ],
        ),
      ),
    );
    try {
      if (item != null) {
        final bytes = await bridge.thumbnail(item, size: 1440);
        if (bytes != null && mounted)
          setState(() => photos.add(StoryPhotoLayer(bytes)));
      }
    } catch (_) {
      if (mounted) showError();
    } finally {
      if (mounted) player?.play();
    }
  }

  Future<void> backToGallery() async {
    if (busy) return;
    setState(() => busy = true);
    await player?.dispose();
    player = null;
    setState(() {
      selected = null;
      preview = null;
    });
    await cleanup();
    drafts.clear();
    if (mounted) setState(() => busy = false);
  }

  Widget avatar(Json user) => IgnorePointer(
    child: SocialAvatar(
      api: widget.api,
      user: user,
      size: 28,
      showEmptyRing: false,
    ),
  );
  Widget overlay() => RepaintBoundary(
    key: overlayKey,
    child: SizedBox.expand(
      child: Stack(
        children: [
          for (final photo in photos)
            Positioned(
              left: photo.offset.dx * frame.width,
              top: photo.offset.dy * frame.height,
              width: frame.width * .5,
              child: GestureDetector(
                onScaleStart: (d) {
                  gestureStart = d.focalPoint;
                  photo.startOffset = photo.offset;
                  gestureScale = photo.scale;
                },
                onScaleUpdate: busy
                    ? null
                    : (d) => setState(() {
                        photo.offset =
                            photo.startOffset +
                            Offset(
                              (d.focalPoint.dx - gestureStart.dx) / frame.width,
                              (d.focalPoint.dy - gestureStart.dy) /
                                  frame.height,
                            );
                        photo.scale = (gestureScale * d.scale).clamp(.2, 4);
                      }),
                child: Transform.scale(
                  scale: photo.scale,
                  alignment: Alignment.topLeft,
                  child: Image.memory(photo.bytes),
                ),
              ),
            ),
          for (var i = 0; i < stickers.length; i++)
            Positioned(
              left: stickers[i].position.dx * frame.width,
              top: stickers[i].position.dy * frame.height,
              width: frame.width * .75,
              child: Listener(
                behavior: HitTestBehavior.translucent,
                onPointerDown: (_) {
                  if (textPointers.isEmpty) activeText = i;
                },
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: busy
                      ? null
                      : () {
                          if (!textWasPinched) editText(i);
                        },
                  onScaleStart: (d) {
                    gestureStart = d.focalPoint;
                    gestureSticker = stickers[i];
                  },
                  onScaleUpdate: busy
                      ? null
                      : (d) => setState(() {
                          if (pinchText != null || d.pointerCount > 1) return;
                          final base = gestureSticker!;
                          stickers[i] = base
                              .move(d.focalPoint - gestureStart, frame)
                              .transform(
                                base
                                    .move(d.focalPoint - gestureStart, frame)
                                    .position,
                                base.scale * d.scale,
                              );
                        }),
                  child: Transform.scale(
                    scale: stickers[i].scale,
                    alignment: Alignment.topLeft,
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: StoryTextLabel(sticker: stickers[i]),
                    ),
                  ),
                ),
              ),
            ),
          if (!exportingMetadata)
            Positioned(
              left: 16,
              bottom: 20,
              right: 76,
              child: Directionality(
                textDirection: TextDirection.ltr,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (mentions.isNotEmpty)
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          for (final user in mentions)
                            TextButton(
                              onPressed: () => socialPush(
                                context,
                                ProfilePage(
                                  api: widget.api,
                                  userId: number(user['id']),
                                ),
                              ),
                              child: Text(
                                '@${socialUserName(user)}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                        ],
                      ),
                    if (caption.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: GestureDetector(
                          onTap: busy ? null : editCaption,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              avatar(me),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  caption,
                                  textAlign: TextAlign.left,
                                  textDirection:
                                      Localizations.localeOf(
                                            context,
                                          ).languageCode ==
                                          'fa'
                                      ? TextDirection.rtl
                                      : TextDirection.ltr,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    shadows: [
                                      Shadow(
                                        blurRadius: 3,
                                        color: Colors.black,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    ),
  );
  Widget editor() => LayoutBuilder(
    builder: (c, box) {
      frame = Size(box.maxWidth, box.maxHeight);
      final size = player?.value.size ?? imageSize;
      cover = (size.width >= frame.width && size.height >= frame.height);
      return Listener(
        onPointerDown: textPointerDown,
        onPointerMove: textPointerMove,
        onPointerUp: textPointerUp,
        onPointerCancel: textPointerUp,
        child: Stack(
          fit: StackFit.expand,
          children: [
            RepaintBoundary(
              key: canvasKey,
              child: ColoredBox(
                color: Colors.black,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (player != null)
                      Center(
                        child: ClipRect(
                          child: SizedBox.expand(
                            child: FittedBox(
                              fit: cover ? BoxFit.cover : BoxFit.contain,
                              child: SizedBox(
                                width: size.width,
                                height: size.height,
                                child: VideoPlayer(player!),
                              ),
                            ),
                          ),
                        ),
                      )
                    else
                      GestureDetector(
                        onScaleStart: (d) {
                          gestureStart = d.localFocalPoint;
                          gestureImageOffset = imageOffset;
                          gestureScale = imageScale;
                        },
                        onScaleUpdate: busy
                            ? null
                            : (d) => setState(() {
                                if (activeText != null) return;
                                imageScale = (gestureScale * d.scale).clamp(
                                  .2,
                                  5,
                                );
                                final center = Offset(
                                  frame.width / 2,
                                  frame.height / 2,
                                );
                                imageOffset =
                                    d.localFocalPoint -
                                    center -
                                    (gestureStart -
                                            center -
                                            gestureImageOffset) *
                                        (imageScale / gestureScale);
                              }),
                        child: Transform.translate(
                          offset: imageOffset,
                          child: Transform.scale(
                            scale: imageScale,
                            child: Image.memory(
                              preview!,
                              fit: cover ? BoxFit.cover : BoxFit.contain,
                              alignment: Alignment.center,
                            ),
                          ),
                        ),
                      ),
                    overlay(),
                  ],
                ),
              ),
            ),
            PositionedDirectional(
              top: 8,
              start: 8,
              child: IconButton(
                onPressed: busy ? null : backToGallery,
                icon: const Icon(Icons.arrow_back, color: Colors.white),
              ),
            ),
            Positioned(
              top: 55,
              right: 8,
              child: Column(
                children: [
                  action(
                    Icons.add_photo_alternate_outlined,
                    t('عکس جدید', 'Add photo'),
                    addPhoto,
                  ),
                  action(Icons.text_fields, t('متن', 'Text'), editText),
                  action(
                    Icons.alternate_email,
                    t('منشن', 'Mention'),
                    editMentions,
                  ),
                  action(
                    Icons.save_alt,
                    t('ذخیره', 'Save'),
                    () => finish(save: true),
                  ),
                ],
              ),
            ),
            if (caption.isEmpty)
              Positioned(
                left: 16,
                bottom: 20,
                child: TextButton(
                  onPressed: busy ? null : editCaption,
                  child: Text(
                    t('یک عنوان اضافه کنید', 'Add a caption'),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
            if (busy)
              const Positioned.fill(
                child: ColoredBox(
                  color: Colors.black54,
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
          ],
        ),
      );
    },
  );
  Widget action(IconData icon, String text, VoidCallback tap) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Column(
      children: [
        IconButton(
          onPressed: busy ? null : tap,
          icon: Icon(icon, color: Colors.white),
        ),
        Text(text, style: const TextStyle(color: Colors.white, fontSize: 11)),
      ],
    ),
  );
  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !busy && selected == null,
    onPopInvokedWithResult: (didPop, result) {
      if (!didPop && !busy && selected != null) backToGallery();
    },
    child: Scaffold(
      backgroundColor: Colors.black,
      appBar: selected == null
          ? AppTopBarDirection(
              child: AppBar(title: Text(t('استوری جدید', 'New story'))),
            )
          : null,
      body: SafeArea(
        child: selected != null
            ? editor()
            : Column(
                children: [
                  if (permission == 'limited' || permission == 'denied')
                    TextButton(
                      onPressed: busy ? null : requestGallery,
                      child: Text(
                        t(
                          'مدیریت دسترسی به عکس‌ها و ویدیوها',
                          'Manage photo and video access',
                        ),
                      ),
                    ),
                  if (error.isNotEmpty)
                    TextButton(onPressed: requestGallery, child: Text(error)),
                  Expanded(
                    child: GridView.builder(
                      controller: galleryScroll,
                      padding: const EdgeInsets.all(3),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            childAspectRatio: 9 / 16,
                            crossAxisSpacing: 3,
                            mainAxisSpacing: 3,
                          ),
                      itemCount: gallery.length + 1,
                      itemBuilder: (c, i) => i == 0
                          ? Material(
                              color: Colors.white12,
                              child: InkWell(
                                onTap: busy ? null : () => choose(null),
                                child: const Center(
                                  child: Icon(
                                    Icons.camera_alt_outlined,
                                    color: Colors.white,
                                    size: 36,
                                  ),
                                ),
                              ),
                            )
                          : StoryGalleryTile(
                              key: ValueKey(gallery[i - 1]['uri']),
                              bridge: bridge,
                              item: gallery[i - 1],
                              onTap: busy ? null : () => choose(gallery[i - 1]),
                            ),
                    ),
                  ),
                  if (loading || busy) const LinearProgressIndicator(),
                  if (!loading && gallery.isEmpty && error.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        t(
                          'عکس یا ویدیویی در دسترس نیست.',
                          'No photos or videos are available.',
                        ),
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ),
                ],
              ),
      ),
      bottomNavigationBar: selected == null
          ? null
          : SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  onPressed: busy ? null : () => finish(save: false),
                  child: Text(t('انتشار', 'Publish')),
                ),
              ),
            ),
    ),
  );
}

class StoryGalleryTile extends StatefulWidget {
  const StoryGalleryTile({
    super.key,
    required this.bridge,
    required this.item,
    this.onTap,
  });
  final StoryMediaBridge bridge;
  final Json item;
  final VoidCallback? onTap;
  @override
  State<StoryGalleryTile> createState() => _StoryGalleryTileState();
}

class _StoryGalleryTileState extends State<StoryGalleryTile> {
  late final image = widget.bridge.thumbnail(widget.item);
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: widget.onTap,
    child: Stack(
      fit: StackFit.expand,
      children: [
        FutureBuilder<Uint8List?>(
          future: image,
          builder: (c, s) => s.hasData
              ? Image.memory(s.data!, fit: BoxFit.cover)
              : const ColoredBox(
                  color: Colors.white12,
                  child: Icon(Icons.image_outlined, color: Colors.grey),
                ),
        ),
        if (widget.item['video'] == true)
          Positioned(
            right: 5,
            bottom: 5,
            child: Container(
              color: Colors.black54,
              padding: const EdgeInsets.all(3),
              child: Text(
                storyDuration(number(widget.item['duration'])),
                textDirection: TextDirection.ltr,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ),
          ),
      ],
    ),
  );
}

class StoryMentionPicker extends StatefulWidget {
  const StoryMentionPicker({
    super.key,
    required this.api,
    required this.initial,
  });
  final SocialApi api;
  final List<Json> initial;
  @override
  State<StoryMentionPicker> createState() => _StoryMentionPickerState();
}

class _StoryMentionPickerState extends State<StoryMentionPicker> {
  late final selected = {for (final u in widget.initial) number(u['id']): u};
  List<Json> rows = [];
  String query = '', error = '';
  bool loading = true;
  Timer? timer;
  int generation = 0;
  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  Future<void> load() async {
    final version = ++generation;
    setState(() => loading = true);
    try {
      final users = objects(
        await widget.api.get(
          '/people?q=${Uri.encodeQueryComponent(query.trim())}',
        ),
      );
      if (mounted && version == generation)
        setState(() {
          rows = users;
          error = '';
        });
    } catch (_) {
      if (mounted && version == generation)
        setState(
          () => error = socialText(
            context,
            'دریافت کاربران ممکن نشد.',
            'Could not load people.',
          ),
        );
    } finally {
      if (mounted && version == generation) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * .65,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                onChanged: (v) {
                  query = v;
                  generation++;
                  timer?.cancel();
                  timer = Timer(const Duration(milliseconds: 350), load);
                },
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: socialText(
                    context,
                    'جستجوی نام کاربری',
                    'Search username',
                  ),
                ),
              ),
            ),
            if (loading) const LinearProgressIndicator(),
            if (error.isNotEmpty)
              TextButton(onPressed: load, child: Text(error)),
            Expanded(
              child: ListView.builder(
                itemCount: rows.length,
                itemBuilder: (c, i) {
                  final u = rows[i], id = number(rows[i]['id']);
                  return ListTile(
                    selected: selected.containsKey(id),
                    selectedTileColor: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: .15),
                    leading: SocialAvatar(
                      api: widget.api,
                      user: u,
                      size: 40,
                      showEmptyRing: false,
                    ),
                    title: Text(socialUserName(u)),
                    onTap: () => setState(() {
                      if (selected.containsKey(id)) {
                        selected.remove(id);
                      } else {
                        selected[id] = u;
                      }
                    }),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  onPressed: selected.isEmpty
                      ? null
                      : () => Navigator.pop(context, selected.values.toList()),
                  child: Text(socialText(context, 'افزودن', 'Add')),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class StoryPhotoLayer {
  StoryPhotoLayer(this.bytes);
  final Uint8List bytes;
  Offset offset = const Offset(.2, .2), startOffset = Offset.zero;
  double scale = 1;
}
