import 'package:flutter/material.dart';

class MarqueeText extends StatefulWidget {
  const MarqueeText({
    super.key,
    required this.text,
    required this.textStyle,
    this.speed = 60,
    this.gap = 50,
  });
  final String text;
  final TextStyle textStyle;
  final double speed, gap;
  @override
  State<MarqueeText> createState() => _MarqueeTextState();
}

class _MarqueeTextState extends State<MarqueeText>
    with SingleTickerProviderStateMixin {
  late final AnimationController animation = AnimationController(vsync: this);
  double cycle = 0;
  @override
  void dispose() {
    animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final painter = TextPainter(
        text: TextSpan(text: widget.text, style: widget.textStyle),
        textDirection: TextDirection.ltr,
        textScaler: MediaQuery.textScalerOf(context),
      )..layout();
      final width = painter.width, height = painter.height;
      painter.dispose();
      if (width <= constraints.maxWidth) {
        animation.stop();
        return Text(widget.text, style: widget.textStyle, maxLines: 1);
      }
      final distance = width + widget.gap;
      if (cycle != distance || !animation.isAnimating) {
        cycle = distance;
        animation.duration = Duration(
          milliseconds: (distance / widget.speed * 1000).round(),
        );
        animation.repeat();
      }
      return ClipRect(
        child: SizedBox(
          height: height,
          child: AnimatedBuilder(
            animation: animation,
            builder: (_, _) => Stack(
              children: [
                for (var i = 0; i < 2; i++)
                  Positioned(
                    left: i * distance - animation.value * distance,
                    width: width,
                    child: Text(
                      widget.text,
                      style: widget.textStyle,
                      textDirection: TextDirection.ltr,
                      maxLines: 1,
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
