import 'package:flutter/material.dart';
import 'package:sornaz/helpers/app_typography.dart';

class WaveformPainterWithTicks extends CustomPainter {
  final List<double> amplitudes;
  final bool isRecording;

  WaveformPainterWithTicks(this.amplitudes, this.isRecording);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint wavePaint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 0.5
      ..strokeCap = StrokeCap.round;

    final Paint tickPaint = Paint()
      ..color = Colors.grey.shade400
      ..strokeWidth = 1;

    // =======================
    // 📌 1) رسم خط‌کش بالای ویجت
    // =======================
    const double tickHeightLong = 15;
    const double tickHeightShort = 8;
    const double tickSpacingPx = 20; // هر ۲۰px یک خط

    for (double x = 0; x < size.width; x += tickSpacingPx) {
      final bool isBigTick = (x ~/ tickSpacingPx) % 4 == 0;

      canvas.drawLine(
        Offset(x, 0),
        Offset(x, isBigTick ? tickHeightLong : tickHeightShort),
        tickPaint,
      );
    }

    // =======================
    // 📌 2) رسم Waveform
    // =======================
    if (amplitudes.isEmpty) return;

    double dxStep = size.width / amplitudes.length;
    double centerY = size.height / 2;

    for (int i = 0; i < amplitudes.length; i++) {
      double amp = amplitudes[i];
      double scaled = amp * (size.height * 0.4);

      canvas.drawLine(
        Offset(i * dxStep, centerY - scaled),
        Offset(i * dxStep, centerY + scaled),
        wavePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class WaveformPainterWithTicksAndTime extends CustomPainter {
  final List<double> amplitudes;
  final bool isRecording;
  final BuildContext context;

  WaveformPainterWithTicksAndTime(
    this.amplitudes,
    this.isRecording,
    this.context,
  );

  @override
  void paint(Canvas canvas, Size size) {
    final Paint wavePaint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final Paint tickPaint = Paint()
      ..color = Colors.grey.shade400
      ..strokeWidth = 1;

    final textPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );

    // -----------------------------------------
    // 🌟 1) رسم خط‌کش (Tick Marks)
    // -----------------------------------------

    const double tickSpacingPx = 20; // فاصله بین خطوط
    const double bigTick = 18; // هر 1 ثانیه
    const double midTick = 12; // هر نیم ثانیه
    const double smallTick = 6; // هر 0.25 ثانیه

    int tickIndex = 0;

    for (double x = 0; x < size.width; x += tickSpacingPx) {
      double height;

      // هر چهار خط → یک ثانیه کامل
      if (tickIndex % 4 == 0) {
        height = bigTick;
      }
      // هر دو خط → نیم ثانیه
      else if (tickIndex % 2 == 0) {
        height = midTick;
      }
      // بقیه → ربع ثانیه
      else {
        height = smallTick;
      }

      canvas.drawLine(Offset(x, 0), Offset(x, height), tickPaint);

      // -----------------------------------------
      // 🌟 2) رسم عدد ثانیه زیر خط‌کش
      // -----------------------------------------
      if (tickIndex % 4 == 0) {
        int seconds = tickIndex ~/ 4;

        if (seconds > 0) {
          textPainter.text = TextSpan(
            text: "$seconds s",
            style: AppTypography.waveformPainterSeconds(context),
            // ==================================================
          );

          textPainter.layout(minWidth: 0, maxWidth: 40);

          textPainter.paint(
            canvas,
            Offset(x - textPainter.width / 2, bigTick + 4),
          );
        }
      }

      tickIndex++;
    }

    // -----------------------------------------
    // 🌟 3) رسم Waveform
    // -----------------------------------------
    if (amplitudes.isEmpty) return;

    double dx = size.width / amplitudes.length;
    double centerY = size.height * 0.65;

    for (int i = 0; i < amplitudes.length; i++) {
      double amp = amplitudes[i];
      double scaled = amp * (size.height * 0.30);

      canvas.drawLine(
        Offset(i * dx, centerY - scaled),
        Offset(i * dx, centerY + scaled),
        wavePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
