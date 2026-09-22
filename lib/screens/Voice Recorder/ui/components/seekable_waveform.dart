import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:sornaz/components/ab_repeat.dart';
import 'package:sornaz/helpers/app_colors.dart';
import 'package:sornaz/helpers/app_functions.dart';

class SeekableWaveform extends StatelessWidget {
  const SeekableWaveform({
    super.key,
    required this.samples,
    required this.duration,
    required this.position,
    required this.markers,
    this.onSeek,
    this.repeat,
  });
  final List<double> samples;
  final int duration, position;
  final List<int> markers;
  final ValueChanged<int>? onSeek;
  final AbRepeat? repeat;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      void seek(double x) => onSeek?.call(
        (position + (x - box.maxWidth / 2) / 60 * 1000).round().clamp(
          0,
          duration,
        ),
      );
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: onSeek == null ? null : (d) => seek(d.localPosition.dx),
        onHorizontalDragUpdate: onSeek == null
            ? null
            : (d) => onSeek?.call(
                (position - d.delta.dx / 60 * 1000).round().clamp(0, duration),
              ),
        child: ColoredBox(
          color: AppColors.voice_recorder_basic_waveform_decoration_color(
            isDark: Theme.of(context).brightness == Brightness.dark,
          ),
          child: ClipRect(
            child: CustomPaint(
              size: Size.infinite,
              painter: _Wave(
                samples,
                duration,
                position,
                markers,
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.onSurface,
                repeat,
              ),
            ),
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
    this.repeat,
  );
  final List<double> samples;
  final List<int> markers;
  final int duration, position;
  final Color accent, ink;
  final AbRepeat? repeat;
  bool outside(num time) =>
      repeat?.active == true &&
      (time < repeat!.start!.inMilliseconds ||
          time > repeat!.end!.inMilliseconds);
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
      final h = math.max(1, samples[index].abs().clamp(0, 1) * (s.height * .4));
      pen.color = outside(time) ? Colors.grey : ink.withValues(alpha: .6);
      c.drawLine(
        Offset(x, (s.height - h) / 2),
        Offset(x, (s.height + h) / 2),
        pen,
      );
    }
    pen.color = accent;
    for (final m in markers) {
      final x = s.width / 2 + (m - position) / 1000 * 60;
      pen.color = outside(m) ? Colors.lightBlue.withValues(alpha: .35) : accent;
      if (x >= 0 && x <= s.width)
        c.drawLine(Offset(x, 0), Offset(x, s.height), pen);
    }
    for (final at in [repeat?.start, repeat?.end]) {
      if (at == null) continue;
      final x = s.width / 2 + (at.inMilliseconds - position) / 1000 * 60;
      pen.color = accent;
      pen.strokeWidth = 2;
      c.drawLine(Offset(x, 0), Offset(x, s.height), pen);
    }
    final first = math.max(
      0,
      ((position - s.width / 120 * 1000) / 200).floor() * 200,
    );
    final last = position + s.width / 120 * 1000;
    pen.color = ink.withValues(alpha: .4);
    pen.strokeWidth = 1;
    for (var t = first; t <= last; t += 200) {
      final x = s.width / 2 + (t - position) / 1000 * 60;
      final major = t % 1000 == 0;
      c.drawLine(
        Offset(x, s.height - (major ? 22 : 15)),
        Offset(x, s.height - 10),
        pen,
      );
      if (major) {
        final label = TextPainter(
          text: TextSpan(
            text: formatSeconds(t ~/ 1000),
            style: TextStyle(fontSize: 10, color: ink.withValues(alpha: .65)),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        label.paint(c, Offset(x - label.width / 2, s.height - 36));
      }
    }
    pen.color = ink;
    pen.strokeWidth = 2;
    c.drawLine(Offset(s.width / 2, 0), Offset(s.width / 2, s.height), pen);
    c.drawCircle(Offset(s.width / 2, 6), 4, pen);
  }

  @override
  bool shouldRepaint(covariant _Wave old) => true;
}
