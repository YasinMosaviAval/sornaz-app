import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:sornaz/helpers/app_typography.dart';

class SmoothRecordingTimer extends StatefulWidget {
  const SmoothRecordingTimer({
    super.key,
    required this.position,
    required this.running,
  });
  final int Function() position;
  final bool running;
  @override
  State<SmoothRecordingTimer> createState() => _SmoothRecordingTimerState();
}

class _SmoothRecordingTimerState extends State<SmoothRecordingTimer>
    with SingleTickerProviderStateMixin {
  late final Ticker ticker = createTicker((_) {
    if (mounted) setState(() {});
  });
  void sync() {
    if (widget.running && !ticker.isActive)
      ticker.start();
    else if (!widget.running)
      ticker.stop();
  }

  @override
  void initState() {
    super.initState();
    sync();
  }

  @override
  void didUpdateWidget(SmoothRecordingTimer oldWidget) {
    super.didUpdateWidget(oldWidget);
    sync();
  }

  @override
  void dispose() {
    ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ms = widget.position();
    return RecordingTimer(
      text:
          '${(ms ~/ 60000).toString().padLeft(2, '0')}:${(ms ~/ 1000 % 60).toString().padLeft(2, '0')}.${(ms ~/ 10 % 100).toString().padLeft(2, '0')}',
    );
  }
}

/// Fixed digit cells also work with fonts that do not provide tabular figures.
class RecordingTimer extends StatelessWidget {
  const RecordingTimer({super.key, required this.text});
  final String text;
  @override
  Widget build(BuildContext context) {
    final style = AppTypography.voiceRecorderRecordingTimer(
      context,
    ).copyWith(fontWeight: FontWeight.w300);
    final painter = TextPainter(
      textDirection: TextDirection.ltr,
      textScaler: MediaQuery.textScalerOf(context),
    );
    var width = 0.0;
    for (var i = 0; i < 10; i++) {
      painter.text = TextSpan(text: '$i', style: style);
      painter.layout();
      if (painter.width > width) width = painter.width;
    }
    painter.dispose();
    return Semantics(
      label: text,
      child: ExcludeSemantics(
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final character in text.split(''))
                SizedBox(
                  width: character == ':' || character == '.'
                      ? width * .5
                      : width,
                  child: Text(
                    character,
                    textAlign: TextAlign.center,
                    style: style,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
