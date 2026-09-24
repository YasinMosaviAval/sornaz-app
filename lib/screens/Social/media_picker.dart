import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'social_api.dart';
import 'social_widgets.dart';
import 'story_composer.dart';

Future<PlatformFile?> pickGalleryMedia(
  BuildContext context, {
  bool imagesOnly = false,
  bool crop = false,
}) async {
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    return Navigator.push<PlatformFile>(
      context,
      MaterialPageRoute(
        builder: (_) => DeviceMediaPicker(imagesOnly: imagesOnly, crop: crop),
      ),
    );
  }
  final picked = await FilePicker.platform.pickFiles(
    type: imagesOnly ? FileType.image : FileType.media,
    withData: true,
  );
  if (picked == null || !context.mounted) return null;
  final file = picked.files.single;
  if (!crop ||
      RegExp(r'\.(mp4|webm|mov)$', caseSensitive: false).hasMatch(file.name))
    return file;
  final bytes = file.bytes ?? await File(file.path!).readAsBytes();
  if (!context.mounted) return null;
  return Navigator.push<PlatformFile>(
    context,
    MaterialPageRoute(builder: (_) => ImageCropPage(bytes: bytes)),
  );
}

Future<void> releasePickedMedia(PlatformFile file) async {
  if (file.path == null || !Platform.isAndroid) return;
  try {
    await StoryMediaBridge().call('delete', {
      'paths': [file.path],
    });
  } catch (_) {}
}

class DeviceMediaPicker extends StatefulWidget {
  const DeviceMediaPicker({
    super.key,
    this.imagesOnly = false,
    this.crop = false,
  });
  final bool imagesOnly, crop;
  @override
  State<DeviceMediaPicker> createState() => _DeviceMediaPickerState();
}

class _DeviceMediaPickerState extends State<DeviceMediaPicker> {
  final bridge = StoryMediaBridge();
  final rows = <Json>[];
  bool loading = false, more = true, selecting = false;
  String? error;
  int offset = 0;
  @override
  void initState() {
    super.initState();
    load(permission: true);
  }

  Future<void> load({bool permission = false}) async {
    if (loading || !more) return;
    setState(() {
      loading = true;
      error = null;
    });
    try {
      if (permission) await bridge.call('permission');
      final batch = objects(await bridge.call('gallery', {'offset': offset}));
      offset += batch.length;
      if (mounted)
        setState(() {
          more = batch.length == 60;
          rows.addAll(
            batch.where((r) => !widget.imagesOnly || r['video'] != true),
          );
        });
    } catch (e) {
      if (mounted)
        setState(
          () => error = socialText(
            context,
            'دسترسی به گالری ممکن نشد',
            'Could not open gallery',
          ),
        );
    } finally {
      if (mounted) setState(() => loading = false);
    }
    if (mounted && rows.isEmpty && more && error == null) load();
  }

  Future<void> camera() async {
    if (selecting) return;
    setState(() => selecting = true);
    Json? captured;
    try {
      final raw = await bridge.call('camera');
      if (raw == null) return;
      captured = object(raw);
      if (!mounted) return;
      setState(() => selecting = false);
      await choose(captured);
    } catch (e) {
      if (mounted) socialError(context, e);
    } finally {
      if (captured != null)
        await bridge.call('delete', {
          'paths': [captured['path']],
        });
      if (mounted) setState(() => selecting = false);
    }
  }

  Future<void> choose(Json item) async {
    if (selecting) return;
    setState(() => selecting = true);
    try {
      PlatformFile? file;
      if (item['video'] == true) {
        final selected = object(
          await bridge.call('select', {'uri': item['uri'], 'video': true}),
        );
        final path = '${selected['path']}';
        file = PlatformFile(
          name: 'video.mp4',
          path: path,
          size: await File(path).length(),
        );
      } else {
        final bytes = await bridge.thumbnail(item, size: 2048);
        if (bytes == null) throw StateError('Image unavailable');
        if (!mounted) return;
        file = widget.crop
            ? await Navigator.push<PlatformFile>(
                context,
                MaterialPageRoute(builder: (_) => ImageCropPage(bytes: bytes)),
              )
            : PlatformFile(name: 'photo.png', size: bytes.length, bytes: bytes);
      }
      if (mounted && file != null)
        Navigator.pop(context, file);
      else if (!mounted && file != null)
        await releasePickedMedia(file);
    } catch (e) {
      if (mounted) socialError(context, e);
    } finally {
      if (mounted) setState(() => selecting = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(socialText(context, 'انتخاب رسانه', 'Choose media')),
    ),
    body: Column(
      children: [
        if (loading || selecting) const LinearProgressIndicator(),
        if (error != null)
          TextButton(
            onPressed: () => load(permission: true),
            child: Text(error!),
          ),
        Expanded(
          child: NotificationListener<ScrollNotification>(
            onNotification: (n) {
              if (n.metrics.extentAfter < 500) load();
              return false;
            },
            child: GridView.builder(
              padding: const EdgeInsets.all(4),
              itemCount: rows.length + 1,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 9 / 16,
                crossAxisSpacing: 4,
                mainAxisSpacing: 4,
              ),
              itemBuilder: (_, i) => i == 0
                  ? InkWell(
                      onTap: camera,
                      child: const Center(
                        child: Icon(Icons.camera_alt_outlined),
                      ),
                    )
                  : StoryGalleryTile(
                      item: rows[i - 1],
                      bridge: bridge,
                      onTap: () => choose(rows[i - 1]),
                    ),
            ),
          ),
        ),
      ],
    ),
  );
}

class ImageCropPage extends StatefulWidget {
  const ImageCropPage({super.key, required this.bytes});
  final Uint8List bytes;
  @override
  State<ImageCropPage> createState() => _ImageCropPageState();
}

class _ImageCropPageState extends State<ImageCropPage> {
  final boundary = GlobalKey();
  final transform = TransformationController();
  double ratio = 1;
  bool busy = false;
  @override
  void dispose() {
    transform.dispose();
    super.dispose();
  }

  Future<void> save() async {
    setState(() => busy = true);
    try {
      await precacheImage(MemoryImage(widget.bytes), context);
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) return;
      final box =
          boundary.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await box.toImage(pixelRatio: 1536 / box.size.longestSide);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      if (mounted && data != null) {
        final bytes = data.buffer.asUint8List();
        Navigator.pop(
          context,
          PlatformFile(name: 'cropped.png', size: bytes.length, bytes: bytes),
        );
      }
    } catch (e) {
      if (mounted) socialError(context, e);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(socialText(context, 'برش تصویر', 'Crop image')),
      actions: [
        IconButton(
          onPressed: busy ? null : save,
          icon: const Icon(Icons.check),
        ),
      ],
    ),
    body: Column(
      children: [
        Expanded(
          child: Center(
            child: AspectRatio(
              aspectRatio: ratio,
              child: RepaintBoundary(
                key: boundary,
                child: ClipRect(
                  child: InteractiveViewer(
                    transformationController: transform,
                    minScale: 1,
                    maxScale: 6,
                    child: SizedBox.expand(
                      child: Image.memory(widget.bytes, fit: BoxFit.cover),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        SafeArea(
          top: false,
          child: Wrap(
            spacing: 8,
            children: [
              for (final item in [
                (1.0, '1:1'),
                (16 / 9, '16:9'),
                (9 / 16, '9:16'),
                (4 / 3, '4:3'),
              ])
                ChoiceChip(
                  label: Text(item.$2),
                  selected: ratio == item.$1,
                  onSelected: busy
                      ? null
                      : (_) => setState(() {
                          ratio = item.$1;
                          transform.value = Matrix4.identity();
                        }),
                ),
              IconButton(
                tooltip: socialText(context, 'بازنشانی', 'Reset'),
                onPressed: busy
                    ? null
                    : () => transform.value = Matrix4.identity(),
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
        ),
        if (busy) const LinearProgressIndicator(),
      ],
    ),
  );
}
