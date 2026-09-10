import 'package:flutter/material.dart';

class AbRepeat {
  Duration? start, end;
  bool get active => start != null && end != null;
  void cycle(Duration position) {
    if (start == null) {
      start = position;
    } else if (end == null && position > start!) {
      end = position;
    } else {
      clear();
    }
  }

  void clear() {
    start = null;
    end = null;
  }

  bool shouldLoop(Duration position) => active && position >= end!;
}

class AbRepeatButton extends StatelessWidget {
  const AbRepeatButton({
    super.key,
    required this.repeat,
    required this.onPressed,
  });
  final AbRepeat repeat;
  final VoidCallback? onPressed;
  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: repeat.active
        ? 'A–B: خاموش کردن تکرار'
        : repeat.start == null
        ? 'A: شروع محدوده تکرار'
        : 'B: پایان محدوده تکرار',
    onPressed: onPressed,
    color: repeat.start == null ? null : Theme.of(context).colorScheme.primary,
    icon: Badge(
      label: Text(
        repeat.active
            ? 'A–B'
            : repeat.start == null
            ? 'A'
            : 'B',
      ),
      child: Icon(
        repeat.active
            ? Icons.repeat_on
            : repeat.start == null
            ? Icons.repeat
            : Icons.repeat_one,
      ),
    ),
  );
}

class AbTrack extends StatelessWidget {
  const AbTrack({
    super.key,
    required this.repeat,
    required this.duration,
    required this.child,
  });
  final AbRepeat repeat;
  final Duration duration;
  final Widget child;
  @override
  Widget build(BuildContext context) => Stack(
    alignment: Alignment.center,
    children: [
      child,
      if (repeat.start != null && duration.inMilliseconds > 0)
        Positioned.fill(
          child: IgnorePointer(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: CustomPaint(
                painter: _RangePainter(
                  repeat.start!,
                  repeat.end,
                  duration,
                  Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ),
        ),
    ],
  );
}

class _RangePainter extends CustomPainter {
  _RangePainter(this.start, this.end, this.duration, this.color);
  final Duration start, duration;
  final Duration? end;
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    double x(Duration d) =>
        (d.inMilliseconds / duration.inMilliseconds).clamp(0, 1) * size.width;
    final a = x(start), b = x(end ?? start), y = size.height / 2;
    if (end != null)
      canvas.drawRect(
        Rect.fromLTRB(a, y - 5, b, y + 5),
        Paint()..color = color.withValues(alpha: .4),
      );
    for (final at in [a, if (end != null) b])
      canvas.drawLine(
        Offset(at, y - 10),
        Offset(at, y + 10),
        Paint()
          ..color = color
          ..strokeWidth = 2,
      );
  }

  @override
  bool shouldRepaint(covariant _RangePainter old) =>
      old.start != start ||
      old.end != end ||
      old.duration != duration ||
      old.color != color;
}
