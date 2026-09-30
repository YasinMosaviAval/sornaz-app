import 'package:sornaz/helpers/app_appearance.dart';
import 'package:flutter/material.dart';

/// Continuous saturation/value plane with a continuous hue control.
class BranchColorPicker extends StatefulWidget {
  const BranchColorPicker({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });
  final String label, value;
  final ValueChanged<String> onChanged;
  @override
  State<BranchColorPicker> createState() => _BranchColorPickerState();
}

class _BranchColorPickerState extends State<BranchColorPicker> {
  late HSVColor hsv = HSVColor.fromColor(
    Color(0xff000000 | int.parse(widget.value, radix: 16)),
  );
  void update(HSVColor next) {
    setState(() => hsv = next);
    widget.onChanged(
      next.toColor().toARGB32().toRadixString(16).padLeft(8, '0').substring(2),
    );
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(widget.label, style: const TextStyle(fontSize: 13)),
            ),
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: hsv.toColor(),
                borderRadius: appRadius(context),
                border: Border.all(color: const Color(0xffdddddd)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: appRadius(context),
          child: LayoutBuilder(
            builder: (context, constraints) {
              void move(Offset point) => update(
                hsv
                    .withSaturation(
                      (point.dx / constraints.maxWidth).clamp(0, 1),
                    )
                    .withValue((1 - point.dy / 140).clamp(0, 1)),
              );
              return Semantics(
                label: widget.label,
                child: GestureDetector(
                  key: ValueKey('palette-${widget.label}'),
                  behavior: HitTestBehavior.opaque,
                  onTapDown: (d) => move(d.localPosition),
                  onPanStart: (d) => move(d.localPosition),
                  onPanUpdate: (d) => move(d.localPosition),
                  child: CustomPaint(
                    size: Size(constraints.maxWidth, 140),
                    painter: _Palette(hsv),
                  ),
                ),
              );
            },
          ),
        ),
        Directionality(
          textDirection: TextDirection.ltr,
          child: Slider(
            value: hsv.hue,
            min: 0,
            max: 360,
            activeColor: HSVColor.fromAHSV(1, hsv.hue, 1, 1).toColor(),
            onChanged: (hue) => update(hsv.withHue(hue)),
          ),
        ),
      ],
    ),
  );
}

class _Palette extends CustomPainter {
  const _Palette(this.color);
  final HSVColor color;
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          colors: [
            Colors.white,
            HSVColor.fromAHSV(1, color.hue, 1, 1).toColor(),
          ],
        ).createShader(rect),
    );
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.black],
        ).createShader(rect),
    );
    final point = Offset(
      color.saturation * size.width,
      (1 - color.value) * size.height,
    );
    canvas.drawCircle(
      point,
      6,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    canvas.drawCircle(
      point,
      7,
      Paint()
        ..color = Colors.black45
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(_Palette old) => old.color != color;
}
