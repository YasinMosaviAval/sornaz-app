import 'dart:math' as math;
import 'package:flutter/material.dart';

class SeekableWaveform extends StatelessWidget {
  const SeekableWaveform({
    super.key,
    required this.samples,
    required this.duration,
    required this.position,
    required this.markers,
    required this.onSeek,
  });
  final List<double> samples;
  final int duration, position;
  final List<int> markers;
  final ValueChanged<int> onSeek;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      void seek(double x) => onSeek(
        (position + (x - box.maxWidth / 2) / 60 * 1000).round().clamp(
          0,
          duration,
        ),
      );
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (d) => seek(d.localPosition.dx),
        onHorizontalDragUpdate: (d) => onSeek(
          (position - d.delta.dx / 60 * 1000).round().clamp(0, duration),
        ),
        child: CustomPaint(
          size: Size.infinite,
          painter: _Wave(
            samples,
            duration,
            position,
            markers,
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.onSurface,
          ),
        ),
      );
    },
  );
}

class _Wave extends CustomPainter {
  _Wave(
    this.samples,
    this.duration,
    this.position,
    this.markers,
    this.accent,
    this.ink,
  );
  final List<double> samples;
  final List<int> markers;
  final int duration, position;
  final Color accent, ink;
  @override
  void paint(Canvas c, Size s) {
    final pen = Paint()
      ..color = ink.withValues(alpha: .6)
      ..strokeWidth = 1.2;
    for (double x = 0; x < s.width; x += 6) {
      final time = position + (x - s.width / 2) / 60 * 1000;
      if (time < 0 || time > duration || samples.isEmpty || duration <= 0)
        continue;
      final index = (time / duration * (samples.length - 1)).round().clamp(
        0,
        samples.length - 1,
      );
      final h = math.max(1, samples[index].abs().clamp(0, 1) * (s.height - 40));
      c.drawLine(
        Offset(x, (s.height - h) / 2),
        Offset(x, (s.height + h) / 2),
        pen,
      );
    }
    pen.color = accent;
    for (final m in markers) {
      final x = s.width / 2 + (m - position) / 1000 * 60;
      if (x >= 0 && x <= s.width)
        c.drawLine(Offset(x, 0), Offset(x, s.height), pen);
    }
    pen.color = ink;
    pen.strokeWidth = 2;
    c.drawLine(Offset(s.width / 2, 0), Offset(s.width / 2, s.height), pen);
    c.drawCircle(Offset(s.width / 2, 6), 4, pen);
  }

  @override
  bool shouldRepaint(covariant _Wave old) => true;
}
