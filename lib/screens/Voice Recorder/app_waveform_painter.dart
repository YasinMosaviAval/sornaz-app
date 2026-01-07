import 'package:flutter/material.dart';
import 'package:sornaz/helpers/app_colors.dart';

class WaveformPainter extends CustomPainter {
  final List<double> amplitudes;
  final bool isActive;
  final bool isDark;
  final double samplesPerSecond;

  WaveformPainter(
    this.amplitudes,
    this.isActive,
    this.isDark, {
    this.samplesPerSecond = 10,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerY = size.height / 2;
    final centerX = size.width / 2;

    final paint = Paint()
      ..color = isActive
          ? (isDark ? AppColors.text_primary_dark : AppColors.text_primary_light)
          : (isDark ? AppColors.text_secondary_dark : AppColors.text_secondary_light)
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;

    final double barWidth = 6;
    final int maxBars = (centerX / barWidth).floor(); // فقط نیم صفحه سمت چپ

    final visible = amplitudes.length > maxBars
        ? amplitudes.sublist(amplitudes.length - maxBars)
        : amplitudes;

    // GRID PAINTS
    final minorTickPaint = Paint()
      ..color = isDark ? AppColors.text_secondary_dark : AppColors.text_secondary_light
      ..strokeWidth = 0.2;

    final majorTickPaint = Paint()
      ..color = isDark ? AppColors.text_primary_dark : AppColors.text_primary_light
      ..strokeWidth = 1;

    final double samplesPerMinorTick = samplesPerSecond / 5;
    final int samplesPerMajorTick = samplesPerSecond.toInt();

    for (int i = 0; i < visible.length; i++) {
      final x = centerX - (visible.length - 1 - i) * barWidth;
      final globalIndex = amplitudes.length - visible.length + i;

      if (globalIndex % samplesPerMinorTick.round() == 0) {
        final bool isMajor = (globalIndex % samplesPerMajorTick == 0);
        canvas.drawLine(
          Offset(x, 0),
          Offset(x, isMajor ? 16 : 10),
          isMajor ? majorTickPaint : minorTickPaint,
        );

        if (isMajor) {
          final totalSeconds = (globalIndex / samplesPerSecond).floor();
          final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
          final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
          final timeString = "$minutes:$seconds";

          final textPainter = TextPainter(
            text: TextSpan(
              text: timeString,
              style: TextStyle(
                fontSize: 10,
                color: isDark
                    ? AppColors.text_primary_dark
                    : AppColors.text_primary_light,
              ),
            ),
            textDirection: TextDirection.ltr,
          );

          textPainter.layout();
          textPainter.paint(canvas, Offset(x - 12, 16 + 2));
        }
      }
    }

    // رسم WAVEFORM
    for (int i = 0; i < visible.length; i++) {
      final a = visible[i].clamp(-1.0, 1.0);
      final h = a.abs() * (size.height * 0.4);
      final x = centerX - (visible.length - 1 - i) * barWidth;

      canvas.drawLine(
        Offset(x, centerY - h / 2),
        Offset(x, centerY + h / 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}


