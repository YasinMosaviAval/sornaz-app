import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sornaz/screens/Players/services/sleep_timer_status.dart';

/// Fits in the lower strip of the toolbar without taking space from its actions.
class SleepTimerChrome extends StatefulWidget {
  const SleepTimerChrome({super.key, required this.child});
  final Widget child;
  @override
  State<SleepTimerChrome> createState() => _SleepTimerChromeState();
}

class _SleepTimerChromeState extends State<SleepTimerChrome> {
  final status = SleepTimerStatus.instance;
  Timer? timer;
  @override
  void initState() {
    super.initState();
    status.addListener(changed);
    changed();
  }

  void changed() {
    if (status.active) {
      timer ??= Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
      });
    } else {
      timer?.cancel();
      timer = null;
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    status.removeListener(changed);
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final seconds = (status.remaining.inMilliseconds + 999) ~/ 1000;
    return Stack(
      children: [
        widget.child,
        if (status.active)
          Positioned(
            top: MediaQuery.paddingOf(context).top + 38,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: Center(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    child: Text(
                      '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}',
                      key: const ValueKey('global-sleep-countdown'),
                      textDirection: TextDirection.ltr,
                      style: TextStyle(
                        fontSize: 11,
                        height: 1.25,
                        color: Theme.of(context).colorScheme.primary,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
