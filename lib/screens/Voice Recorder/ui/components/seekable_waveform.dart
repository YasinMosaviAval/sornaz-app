import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:sornaz/components/ab_repeat.dart';
import 'package:sornaz/helpers/app_colors.dart';
import 'package:sornaz/helpers/app_functions.dart';

class SeekableWaveform extends StatefulWidget {
  const SeekableWaveform({
    super.key,
    required this.samples,
    required this.duration,
    required this.position,
    required this.markers,
    this.onSeek,
    this.repeat,
    this.onSeekStart,
  });
  final List<double> samples;
  final int duration, position;
  final List<int> markers;
  final ValueChanged<int>? onSeek;
  final AbRepeat? repeat;
  final VoidCallback? onSeekStart;
  @override
  State<SeekableWaveform> createState() => _SeekableWaveformState();
}

class _SeekableWaveformState extends State<SeekableWaveform> {
  double? localPosition;
  bool dragging = false;
  @override
  void didUpdateWidget(SeekableWaveform old) {
    super.didUpdateWidget(old);
    if (!dragging && old.position != widget.position) localPosition = null;
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final position = (localPosition ?? widget.position.toDouble()).round();
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: widget.onSeek == null
            ? null
            : (d) {
                widget.onSeekStart?.call();
                final at =
                    (position +
                            (d.localPosition.dx - box.maxWidth / 2) / 60 * 1000)
                        .round()
                        .clamp(0, widget.duration);
                setState(() => localPosition = at.toDouble());
                widget.onSeek!(at);
              },
        onHorizontalDragStart: widget.onSeek == null
            ? null
            : (_) {
                widget.onSeekStart?.call();
                dragging = true;
                localPosition = position.toDouble();
              },
        onHorizontalDragUpdate: widget.onSeek == null
            ? null
            : (d) => setState(() {
                localPosition = (localPosition! - d.delta.dx / 40 * 1000).clamp(
                  0.0,
                  widget.duration.toDouble(),
                );
              }),
        onHorizontalDragEnd: widget.onSeek == null
            ? null
            : (_) {
                dragging = false;
                widget.onSeek!(localPosition!.round());
              },
        onHorizontalDragCancel: () => setState(() {
          dragging = false;
          localPosition = null;
        }),
        child: ColoredBox(
          color: AppColors.voice_recorder_basic_waveform_decoration_color(
            isDark: Theme.of(context).brightness == Brightness.dark,
          ),
          child: ClipRect(
            child: RepaintBoundary(
              child: CustomPaint(
                size: Size.infinite,
                painter: _Wave(
                  widget.samples,
                  widget.duration,
                  position,
                  widget.markers,
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.onSurface,
                  widget.repeat,
                ),
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
    final firstBar = math.max(
      0,
      ((position - s.width / 120 * 1000) / 100).floor(),
    );
    final lastBar = ((position + s.width / 120 * 1000) / 100).ceil();
    for (var bar = firstBar; bar <= lastBar; bar++) {
      final time = bar * 100;
      final x = s.width / 2 + (time - position) / 1000 * 60;
      if (time < 0 || time > duration || samples.isEmpty || duration <= 0)
        continue;
      if (bar >= samples.length) continue;
      final h = math.max(1, samples[bar].abs().clamp(0, 1) * (s.height * .4));
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
  }

  @override
  bool shouldRepaint(covariant _Wave old) => true;
}
