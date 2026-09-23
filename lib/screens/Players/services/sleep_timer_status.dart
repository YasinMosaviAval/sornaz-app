import 'package:flutter/foundation.dart';

class SleepTimerStatus extends ChangeNotifier {
  static final instance = SleepTimerStatus();
  DateTime? deadline;
  Duration? trackRemaining;
  bool get active => deadline != null || trackRemaining != null;
  void update({DateTime? deadline, Duration? trackRemaining}) {
    this.deadline = deadline;
    this.trackRemaining = trackRemaining;
    notifyListeners();
  }

  Duration get remaining {
    final value =
        deadline?.difference(DateTime.now()) ?? trackRemaining ?? Duration.zero;
    return value.isNegative ? Duration.zero : value;
  }
}
