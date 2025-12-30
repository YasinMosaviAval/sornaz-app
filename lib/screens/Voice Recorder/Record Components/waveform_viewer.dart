

/*
import 'package:flutter/material.dart';
class WaveformViewer extends StatelessWidget {
  final List<int> waveformDataPairs;
  final Color color;
  final double zoom;

  const WaveformViewer({
    super.key,
    required this.waveformDataPairs,
    required this.color,
    this.zoom = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    final pixelCount = waveformDataPairs.length ~/ 2;
    final basePixelWidth = 1.0;
    final totalWidth = (pixelCount * basePixelWidth) * zoom;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: CustomPaint(
        size: Size(totalWidth.clamp(200.0, double.infinity), double.infinity),
        painter: _WaveformPainter(pairs: waveformDataPairs, color: color),
      ),
    );
  }
}

class _WaveformPainter extends CustomPainter {
  final List<int> pairs;
  final Color color;

  const _WaveformPainter({required this.pairs, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (pairs.isEmpty) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final midY = size.height / 2;
    final pixelCount = pairs.length ~/ 2;
    final dx = size.width / (pixelCount == 0 ? 1 : pixelCount);

    const normaliser = 32768.0;

    for (int i = 0; i < pixelCount; i++) {
      final minVal = pairs[i * 2];
      final maxVal = pairs[i * 2 + 1];

      final minNorm = minVal / normaliser;
      final maxNorm = maxVal / normaliser;

      final yTop = midY - (maxNorm * midY);
      final yBottom = midY - (minNorm * midY);

      final x = i * dx + dx / 2;

      canvas.drawLine(Offset(x, yTop), Offset(x, yBottom), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _WaveformPainter oldDelegate) {
    return oldDelegate.pairs != pairs || oldDelegate.color != color;
  }
}
*/