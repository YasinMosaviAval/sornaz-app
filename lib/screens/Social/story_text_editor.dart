import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'social_widgets.dart';

class StorySticker {
  const StorySticker({
    required this.text,
    this.color = Colors.white,
    this.mode = 0,
    this.position = const Offset(.12, .3),
  });
  final String text;
  final Color color;
  final int mode;
  final Offset position;
  Color get foreground => mode == 1 ? Colors.white : color;
  Color get background => mode == 1
      ? color
      : mode == 2
      ? Colors.white
      : Colors.transparent;
  StorySticker move(Offset delta, Size bounds) => StorySticker(
    text: text,
    color: color,
    mode: mode,
    position: Offset(
      (position.dx + delta.dx / bounds.width).clamp(0, .25),
      (position.dy + delta.dy / bounds.height).clamp(0, .8),
    ),
  );
}

class StoryTextLabel extends StatelessWidget {
  const StoryTextLabel({super.key, required this.sticker});
  final StorySticker sticker;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: sticker.background,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      sticker.text,
      textAlign: TextAlign.center,
      style: TextStyle(
        color: sticker.foreground,
        fontSize: 28,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

/// Maps a draggable on-screen point through the same centered fit as the media.
Color? sampleStoryColor(
  Uint8List rgba,
  Size image,
  Size viewport,
  Offset point,
  BoxFit fit,
) {
  final sizes = applyBoxFit(fit, image, viewport);
  final source = Alignment.center.inscribe(sizes.source, Offset.zero & image);
  final target = Alignment.center.inscribe(
    sizes.destination,
    Offset.zero & viewport,
  );
  if (!target.contains(point)) return null;
  final x =
      (source.left + (point.dx - target.left) / target.width * source.width)
          .floor()
          .clamp(0, image.width.toInt() - 1);
  final y =
      (source.top + (point.dy - target.top) / target.height * source.height)
          .floor()
          .clamp(0, image.height.toInt() - 1);
  final index = (y * image.width.toInt() + x) * 4;
  return Color.fromARGB(255, rgba[index], rgba[index + 1], rgba[index + 2]);
}

class StoryTextEditor extends StatefulWidget {
  const StoryTextEditor({
    super.key,
    required this.image,
    required this.cover,
    this.initial,
  });
  final Uint8List image;
  final bool cover;
  final StorySticker? initial;
  @override
  State<StoryTextEditor> createState() => _StoryTextEditorState();
}

class _StoryTextEditorState extends State<StoryTextEditor> {
  late final input = TextEditingController(text: widget.initial?.text ?? '');
  late Color color = widget.initial?.color ?? Colors.white;
  late int mode = widget.initial?.mode ?? 0;
  bool picking = false;
  Offset point = const Offset(150, 250);
  Uint8List? rgba;
  Size imageSize = Size.zero;
  @override
  void initState() {
    super.initState();
    decode();
  }

  Future<void> decode() async {
    final codec = await ui.instantiateImageCodec(widget.image);
    final frame = await codec.getNextFrame();
    final data = await frame.image.toByteData(
      format: ui.ImageByteFormat.rawRgba,
    );
    if (mounted)
      setState(() {
        rgba = data!.buffer.asUint8List();
        imageSize = Size(
          frame.image.width.toDouble(),
          frame.image.height.toDouble(),
        );
      });
    frame.image.dispose();
    codec.dispose();
  }

  @override
  void dispose() {
    input.dispose();
    super.dispose();
  }

  void sample(Offset value, Size size) {
    setState(() {
      point = Offset(
        value.dx.clamp(0, size.width - 1),
        value.dy.clamp(0, size.height - 1),
      );
      if (rgba != null)
        color =
            sampleStoryColor(
              rgba!,
              imageSize,
              size,
              point,
              widget.cover ? BoxFit.cover : BoxFit.contain,
            ) ??
            Colors.black;
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.black,
    resizeToAvoidBottomInset: false,
    body: SafeArea(
      child: LayoutBuilder(
        builder: (c, box) => Stack(
          fit: StackFit.expand,
          children: [
            Image.memory(
              widget.image,
              fit: widget.cover ? BoxFit.cover : BoxFit.contain,
            ),
            if (!picking) const ColoredBox(color: Colors.black38),
            if (!picking)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: TextField(
                    controller: input,
                    autofocus: true,
                    maxLength: 300,
                    maxLines: 5,
                    minLines: 1,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: mode == 1 ? Colors.white : color,
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: InputDecoration(
                      counterText: '',
                      filled: mode != 0,
                      fillColor: mode == 1 ? color : Colors.white,
                      border: InputBorder.none,
                      hintText: socialText(context, 'متن شما', 'Your text'),
                      hintStyle: const TextStyle(color: Colors.grey),
                    ),
                  ),
                ),
              ),
            if (picking)
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onPanStart: (d) => sample(d.localPosition, box.biggest),
                  onPanUpdate: (d) => sample(d.localPosition, box.biggest),
                  onTapDown: (d) => sample(d.localPosition, box.biggest),
                  child: Stack(
                    children: [
                      Positioned(
                        left: point.dx - 23,
                        top: point.dy - 23,
                        child: Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: color,
                            border: Border.all(color: Colors.white, width: 4),
                            boxShadow: const [
                              BoxShadow(blurRadius: 5, color: Colors.black54),
                            ],
                          ),
                          child: const Icon(
                            Icons.add,
                            color: Colors.black,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            Positioned(
              top: 4,
              left: 8,
              right: 8,
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: socialText(
                      context,
                      'حالت رنگ متن و پس‌زمینه',
                      'Text and background color mode',
                    ),
                    onPressed: () => setState(() => mode = (mode + 1) % 3),
                    icon: Container(
                      width: 28,
                      height: 28,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: const Text(
                        'A',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 21,
                        ),
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      if (picking) {
                        setState(() => picking = false);
                        return;
                      }
                      Navigator.pop(
                        context,
                        StorySticker(
                          text: input.text.trim(),
                          color: color,
                          mode: mode,
                          position:
                              widget.initial?.position ?? const Offset(.12, .3),
                        ),
                      );
                    },
                    child: Text(
                      socialText(context, 'تأیید', 'Done'),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 12,
              right: 12,
              bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
              child: Row(
                children: [
                  IconButton(
                    tooltip: socialText(
                      context,
                      'انتخاب رنگ از تصویر',
                      'Pick a color from media',
                    ),
                    onPressed: rgba == null
                        ? null
                        : () {
                            FocusScope.of(context).unfocus();
                            setState(() => picking = !picking);
                          },
                    icon: const Icon(Icons.colorize, color: Colors.white),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          for (final choice in [
                            Colors.white,
                            Colors.black,
                            Colors.red,
                            Colors.orange,
                            Colors.yellow,
                            Colors.green,
                            Colors.cyan,
                            Colors.blue,
                            Colors.purple,
                            Colors.pink,
                          ])
                            GestureDetector(
                              onTap: () => setState(() => color = choice),
                              child: Container(
                                margin: const EdgeInsets.all(5),
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: choice,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: color == choice
                                        ? Colors.white
                                        : Colors.grey,
                                    width: color == choice ? 3 : 1,
                                  ),
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
          ],
        ),
      ),
    ),
  );
}
