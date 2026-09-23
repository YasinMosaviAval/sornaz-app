import 'package:flutter/material.dart';

/// Separate capture/release distances make guides feel sticky without jumping.
class StorySnapAxis {
  double? _locked;
  double snap(double raw, List<double> targets) {
    final locked = _locked;
    if (locked != null) {
      if ((raw - locked).abs() <= 24) return locked;
      _locked = null;
      return raw;
    }
    double? nearest;
    for (final target in targets) {
      if ((target - raw).abs() <= 8 &&
          (nearest == null || (target - raw).abs() < (nearest - raw).abs()))
        nearest = target;
    }
    _locked = nearest;
    return nearest ?? raw;
  }

  void reset() => _locked = null;
}

class StorySnapController {
  final x = StorySnapAxis(), y = StorySnapAxis();
  void reset() {
    x.reset();
    y.reset();
  }

  Offset snap(Offset raw, Size item, Size canvas) => Offset(
    x.snap(raw.dx, [
      16,
      (canvas.width - item.width) / 2,
      canvas.width - 16 - item.width,
    ]),
    y.snap(raw.dy, [
      16,
      (canvas.height - item.height) / 2,
      canvas.height - 16 - item.height,
    ]),
  );
}

class StoryGuidesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: .65)
      ..strokeWidth = 1;
    canvas.drawLine(const Offset(16, 0), Offset(16, size.height), paint);
    canvas.drawLine(
      Offset(size.width - 16, 0),
      Offset(size.width - 16, size.height),
      paint,
    );
    canvas.drawLine(const Offset(0, 16), Offset(size.width, 16), paint);
    canvas.drawLine(
      Offset(0, size.height - 16),
      Offset(size.width, size.height - 16),
      paint,
    );
    for (double y = 0; y < size.height; y += 10) {
      canvas.drawLine(
        Offset(size.width / 2, y),
        Offset(size.width / 2, (y + 5).clamp(0, size.height)),
        paint,
      );
    }
    for (double x = 0; x < size.width; x += 10) {
      canvas.drawLine(
        Offset(x, size.height / 2),
        Offset((x + 5).clamp(0, size.width), size.height / 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(StoryGuidesPainter oldDelegate) => false;
}
