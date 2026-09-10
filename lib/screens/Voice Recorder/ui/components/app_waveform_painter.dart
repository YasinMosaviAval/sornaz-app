import 'package:flutter/material.dart';
import 'package:sornaz/helpers/app_colors.dart';
import 'package:sornaz/helpers/app_constants.dart';
import 'package:sornaz/helpers/app_typography.dart';

class WaveformPainter extends CustomPainter {
  final int totalSamples;
  final List<int> bookmarks;
  final int elapsedMilliseconds;
  final List<double> amplitudes;
  final bool isActive;
  final bool isDark;
  final double samplesPerSecond;
  final BuildContext context;

  WaveformPainter(
    this.amplitudes,
    this.isActive,
    this.context,
    this.isDark, {
    this.samplesPerSecond = 10,
    required this.totalSamples,
    this.bookmarks = const [],
    this.elapsedMilliseconds = 0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerY = size.height / 2;
    final centerX = size.width / 2;

    final paint = Paint()
      ..color = isActive
          ? AppColors.voice_recorder_app_waveform_painter_active_color(
              isDark: isDark,
            )
          : AppColors.voice_recorder_app_waveform_painter_inactive_color(
              isDark: isDark,
            )
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;

    final double barWidth = 6;
    final int maxBars = (centerX / barWidth).floor(); // فقط نیم صفحه سمت چپ

    final visible = amplitudes.length > maxBars
        ? amplitudes.sublist(amplitudes.length - maxBars)
        : amplitudes;

    // GRID PAINTS
    final minorTickPaint = Paint()
      ..color = AppColors.voice_recorder_app_waveform_painter_minor_tick_color(
        isDark: isDark,
      )
      ..strokeWidth = 0.2;

    final majorTickPaint = Paint()
      ..color = AppColors.voice_recorder_app_waveform_painter_major_tick_color(
        isDark: isDark,
      )
      ..strokeWidth = 1;

    final double samplesPerMinorTick = samplesPerSecond / 5;
    final int samplesPerMajorTick = samplesPerSecond.toInt();

    for (int i = 0; i < visible.length; i++) {
      final x = centerX - (visible.length - 1 - i) * barWidth;
      final globalIndex = totalSamples - visible.length + i;

      if (globalIndex % samplesPerMinorTick.round() == 0) {
        final bool isMajor = (globalIndex % samplesPerMajorTick == 0);
        canvas.drawLine(
          Offset(x, 0),
          Offset(x, isMajor ? 16 : 10),
          isMajor ? majorTickPaint : minorTickPaint,
        );

        if (isMajor) {
          final totalSeconds = (globalIndex / samplesPerSecond).floor();
          final minutes = (totalSeconds ~/ 60).toString().padLeft(
            2,
            AppConstants.NUMBER_0,
          );
          final seconds = (totalSeconds % 60).toString().padLeft(
            2,
            AppConstants.NUMBER_0,
          );
          final timeString = "$minutes:$seconds";

          final textPainter = TextPainter(
            text: TextSpan(
              text: timeString,
              style: AppTypography.voiceRecorderAppWaveformPainterTimeText(
                context,
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
    final markerPaint = Paint()..color = isDark ? AppColors.primary_dark : AppColors.primary_light..strokeWidth = 1.2;
    for (final time in bookmarks) {
      final x = centerX - (elapsedMilliseconds - time) / 1000 * samplesPerSecond * barWidth;
      if (x >= 0 && x <= size.width) canvas.drawLine(Offset(x, 0), Offset(x, size.height), markerPaint);
    }
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
