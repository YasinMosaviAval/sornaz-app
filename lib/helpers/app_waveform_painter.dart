import 'package:flutter/material.dart';

class WaveformPainter extends CustomPainter {
  final List<double> amplitudes;
  final bool isActive;

  WaveformPainter(this.amplitudes, this.isActive);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isActive ? const Color(0xFF00E676) : Colors.grey.shade400
      ..strokeWidth = 0.6
      ..strokeCap = StrokeCap.round;

    if (amplitudes.isEmpty) {
      final centerY = size.height / 2;
      canvas.drawLine(
        Offset(0, centerY),
        // Offset(300, centerY),
        Offset(size.width, centerY),
        paint..color = Colors.grey.shade300,
      );
      return;
    }

    final double barWidth = size.width / 800;
    final double centerY = size.height / 2;
    final int startIndex = 0;
    // final int startIndex = amplitudes.length > 300 ? 200 : 0;

    for (int i = startIndex; i < amplitudes.length; i++) {
      final double amplitude = amplitudes[i];
      final double height = amplitude * size.height * 2;
      final double x = (i - startIndex) * barWidth;
      // final double x = (i - startIndex) * barWidth;

      canvas.drawLine(
        Offset(x, centerY - height / 5),
        Offset(x, centerY + height / 5),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
