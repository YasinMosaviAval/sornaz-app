import 'package:flutter/material.dart';
import 'package:sornaz/helpers/app_spacing.dart';

class MarqueeText extends StatefulWidget {
  final String text;
  final TextStyle textStyle;
  final double speed;
  final double gap;

  const MarqueeText({
    super.key,
    required this.text,
    required this.textStyle,
    this.speed = 60,
    this.gap = AppSpacing.space_50,
  });

  @override
  State<MarqueeText> createState() => _MarqueeTextState();
}

class _MarqueeTextState extends State<MarqueeText>
    with SingleTickerProviderStateMixin {
  late ScrollController _scrollController;
  late AnimationController _animationController;
  double _textWidth = AppSpacing.space_0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _animationController =
        AnimationController(vsync: this, duration: const Duration(seconds: 10))
          ..addListener(() {
            if (_scrollController.hasClients) {
              final maxScroll = _scrollController.position.maxScrollExtent;
              final position = _scrollController.offset;
              final newOffset = position + (widget.speed / 60);

              if (maxScroll > 0 && newOffset >= maxScroll) {
                _scrollController.jumpTo(0);
              } else {
                _scrollController.jumpTo(newOffset);
              }
            }
          });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _startAnimationIfNeeded();
      }
    });
  }

  void _startAnimationIfNeeded() {
    if (!mounted) return;
    final renderBox = context.findRenderObject() as RenderBox?;
    final containerWidth = renderBox?.size.width ?? 0;

    final textPainter = TextPainter(
      text: TextSpan(text: widget.text, style: widget.textStyle),
      textDirection: TextDirection.ltr,
    )..layout();

    _textWidth = textPainter.width;

    if (_textWidth > containerWidth - widget.gap) {
      _animationController.repeat();
    }
  }

  @override
  void didUpdateWidget(MarqueeText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text ||
        oldWidget.textStyle != widget.textStyle) {
      _scrollController.jumpTo(0);
      _startAnimationIfNeeded();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SizedBox(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            controller: _scrollController,
            physics: const NeverScrollableScrollPhysics(),
            child: Row(
              children: [
                Text(
                  widget.text,
                  textDirection: TextDirection.ltr,
                  style: widget.textStyle,
                ),
                SizedBox(width: widget.gap),
                if (_textWidth > constraints.maxWidth) ...{
                  Text(widget.text, style: widget.textStyle),
                },
              ],
            ),
          ),
        );
      },
    );
  }
}
