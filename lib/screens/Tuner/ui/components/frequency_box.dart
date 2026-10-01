import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sornaz/helpers/app_colors.dart';
import 'package:sornaz/helpers/app_data.dart';
import 'package:sornaz/helpers/app_spacing.dart';
import 'package:sornaz/screens/Tuner/controller/tuner_provider.dart';
import 'dart:async';

class FrequencyBox extends StatefulWidget {
  final double cents;
  final bool inRange;
  final bool active;
  final double fillDuration;
  final double pointSize;
  final double scale;

  const FrequencyBox({
    super.key,
    required this.cents,
    required this.inRange,
    required this.active,
    this.fillDuration = 3.0,
    this.pointSize = 1.0,
    this.scale = 4.0,
  });

  @override
  State<FrequencyBox> createState() => _FrequencyBoxState();
}

class _FrequencyBoxState extends State<FrequencyBox> {
  static const _sampleInterval = Duration(milliseconds: 16);
  late List<double> _points;
  Timer? _timer;
  double _lastCents = 0;
  DateTime? _silenceStarted;
  bool _gapInserted = false;

  final ValueNotifier<int> _repaintTick = ValueNotifier(0);

  @override
  void initState() {
    super.initState();
    _points = [];
    _lastCents = widget.cents;

    _timer = Timer.periodic(_sampleInterval, (_) {
      if (!widget.active) {
        final started = _silenceStarted;
        if (started == null) return;
        if (DateTime.now().difference(started) < const Duration(seconds: 1)) {
          _appendPoint(_lastCents);
        } else if (!_gapInserted) {
          _appendPoint(double.nan);
          _gapInserted = true;
        }
        return;
      }
      _appendPoint(_lastCents);
    });
  }

  void _appendPoint(double cents) {
    if (_points.length >= _maximumPoints) _points.removeAt(0);
    _points.add(cents);
    _repaintTick.value++;
  }

  @override
  void didUpdateWidget(covariant FrequencyBox oldWidget) {
    super.didUpdateWidget(oldWidget);
    _lastCents = widget.cents;
    if (oldWidget.active && !widget.active) {
      _silenceStarted = DateTime.now();
      _gapInserted = false;
    } else if (!oldWidget.active && widget.active) {
      _silenceStarted = null;
      _gapInserted = false;
    }
    if (oldWidget.fillDuration != widget.fillDuration &&
        _points.length > _maximumPoints) {
      _points.removeRange(0, _points.length - _maximumPoints);
    }
  }

  int get _maximumPoints =>
      (widget.fillDuration * 1000 / _sampleInterval.inMilliseconds)
          .round()
          .clamp(2, 1875)
          .toInt();

  @override
  void dispose() {
    _timer?.cancel();
    _repaintTick.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appData = context.watch<AppData>();
    final tuner = context.watch<TunerProvider>();
    final isDark = appData.isDark;
    final height = AppSpacing.space_300;

    return LayoutBuilder(
      builder: (context, constraints) => SizedBox(
        height: height,
        child: Stack(
          children: [
            Positioned.fill(
              child: ColoredBox(
                color: AppColors.tuner_frequency_box_background_color(
                  isDark: isDark,
                ),
              ),
            ),

            Positioned(
              left: constraints.maxWidth / 2 - widget.scale * 5,
              top: 0,
              bottom: 0,
              child: Container(
                width: widget.scale * 10,
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
                  width: constraints.maxWidth,
                  height: height,
                  pointSize: widget.pointSize,
                  scale: widget.scale,
                  maximumPoints: _maximumPoints,
                  lineThickness: tuner.lineThickness,
                  lineColor: Theme.of(context).colorScheme.onSurface,
                  isDark: isDark,
                  repaint: _repaintTick,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FrequencyPointsPainter extends CustomPainter {
  final List<double> points;
  final double width;
  final double height;
  final double pointSize;
  final int maximumPoints;
  final bool isDark;
  final double scale;
  final double lineThickness;
  final Color lineColor;

  _FrequencyPointsPainter({
    required this.points,
    required this.width,
    required this.height,
    required this.pointSize,
    required this.maximumPoints,
    required this.isDark,
    required this.lineThickness,
    required this.lineColor,
    this.scale = 1.0,
    required Listenable repaint,
  }) : super(repaint: repaint);

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final paintLine = Paint()
      ..color = lineColor
      ..strokeWidth = lineThickness
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    const safeInset = 12.0;
    final dy =
        (size.height - safeInset * 2 - lineThickness) / (maximumPoints - 1);
    final minX = safeInset + lineThickness / 2;
    final maxX = size.width - safeInset - lineThickness / 2;

    final path = Path();

    var beginSegment = true;
    for (int i = 0; i < points.length; i++) {
      if (!points[i].isFinite) {
        beginSegment = true;
        continue;
      }
      final y = size.height - safeInset - lineThickness / 2 - (i * dy);
      final x = (size.width / 2 + (points[i] * scale))
          .clamp(minX, maxX)
          .toDouble();

      if (beginSegment) {
        path.moveTo(x, y);
        beginSegment = false;
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paintLine);
  }

  @override
  bool shouldRepaint(covariant _FrequencyPointsPainter old) {
    return old.points.length != points.length ||
        old.lineThickness != lineThickness ||
        old.lineColor != lineColor ||
        old.maximumPoints != maximumPoints;
  }
}
