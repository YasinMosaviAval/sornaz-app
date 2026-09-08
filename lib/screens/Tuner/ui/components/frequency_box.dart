import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sornaz/helpers/app_colors.dart';
import 'package:sornaz/helpers/app_data.dart';
import 'package:sornaz/helpers/app_spacing.dart';
import 'dart:async';

class FrequencyBox extends StatefulWidget {
  final double cents;
  final bool inRange;
  final int pointsPerSecond;
  final double pointSize;
  final double scale;

  const FrequencyBox({
    super.key,
    required this.cents,
    required this.inRange,
    this.pointsPerSecond = 60,
    this.pointSize = 1.0,
    this.scale = 4.0,
  });

  @override
  State<FrequencyBox> createState() => _FrequencyBoxState();
}

class _FrequencyBoxState extends State<FrequencyBox> {
  late List<double> _points;
  Timer? _timer;
  double _lastCents = 0;

  final ValueNotifier<int> _repaintTick = ValueNotifier(0);

  @override
  void initState() {
    super.initState();
    _points = [];
    _lastCents = widget.cents;

    _timer = Timer.periodic(const Duration(milliseconds: 16), (_) {
      if (_points.length >= widget.pointsPerSecond) {
        _points.removeAt(0);
      }
      _points.add(_lastCents);

      _repaintTick.value++;
    });
  }

  @override
  void didUpdateWidget(covariant FrequencyBox oldWidget) {
    super.didUpdateWidget(oldWidget);
    _lastCents = widget.cents;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _repaintTick.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appData = context.watch<AppData>();
    final isDark = appData.isDark;
    final width = MediaQuery.of(context).size.width;
    final height = AppSpacing.space_300;

    return SizedBox(
      height: height,
      child: Stack(
        children: [
          Container(
            color: AppColors.tuner_frequency_box_background_color(
              isDark: isDark,
            ),
          ),

          Positioned(
            left: width / 2 - 25,
            top: 0,
            bottom: 0,
            child: Container(
              width: 50,
              color: widget.inRange
                  ? AppColors.tuner_frequency_box_in_range_frequency_color(
                      isDark: isDark,
                    )
                  : AppColors.tuner_frequency_box_not_in_range_frequency_color(
                      isDark: isDark,
                    ),
            ),
          ),

          // رسم نقاط و خطوط
          Positioned.fill(
            child: CustomPaint(
              painter: _FrequencyPointsPainter(
                points: _points,
                width: width,
                height: height,
                pointSize: widget.pointSize,
                scale: widget.scale,
                pointsPerSecond: widget.pointsPerSecond,
                isDark: isDark,
                repaint: _repaintTick,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FrequencyPointsPainter extends CustomPainter {
  final List<double> points;
  final double width;
  final double height;
  final double pointSize;
  final int pointsPerSecond;
  final bool isDark;
  final double scale;

  _FrequencyPointsPainter({
    required this.points,
    required this.width,
    required this.height,
    required this.pointSize,
    required this.pointsPerSecond,
    required this.isDark,
    this.scale = 1.0,
    required Listenable repaint,
  }) : super(repaint: repaint);

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final paintLine = Paint()
      ..color = AppColors.tuner_frequency_box_line_color(isDark: isDark)
      ..strokeWidth = 0.6
      ..style = PaintingStyle.stroke;

    final paintPoint = Paint()
      ..color = AppColors.tuner_frequency_box_point_color(isDark: isDark)
      ..style = PaintingStyle.fill;

    final dy = height / (pointsPerSecond - 1);

    final path = Path();

    for (int i = 0; i < points.length; i++) {
      final y = height - (i * dy);
      final x = width / 2 + (points[i] * scale);

      canvas.drawCircle(Offset(x, y), pointSize, paintPoint);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paintLine);
  }

  @override
  bool shouldRepaint(covariant _FrequencyPointsPainter old) {
    return old.points.length != points.length;
  }
}
