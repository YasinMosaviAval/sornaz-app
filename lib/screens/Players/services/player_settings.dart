import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ListEndAction { restart, nextList, stop }

enum PlaybackInterruption { leavePlayer, exitApp, recording, metronome, tuner }

class PlayerSettings extends ChangeNotifier {
  static final instance = PlayerSettings();
  final Map<PlaybackInterruption, bool> _stop = {};
  ListEndAction listEnd = ListEndAction.stop;
  Future<void>? _loading;
  bool stopsFor(PlaybackInterruption reason) =>
      _stop[reason] ?? reason != PlaybackInterruption.leavePlayer;
  Future<void> load() => _loading ??= _load();
  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    for (final reason in PlaybackInterruption.values) {
      _stop[reason] =
          prefs.getBool('player.stop.${reason.name}') ??
          reason != PlaybackInterruption.leavePlayer;
    }
    listEnd = ListEndAction.values.firstWhere(
      (v) => v.name == prefs.getString('player.listEnd'),
      orElse: () => ListEndAction.stop,
    );
    notifyListeners();
  }

  Future<void> setStop(PlaybackInterruption reason, bool value) async {
    await load();
    _stop[reason] = value;
    notifyListeners();
    await (await SharedPreferences.getInstance()).setBool(
      'player.stop.${reason.name}',
      value,
    );
  }

  Future<void> setListEnd(ListEndAction value) async {
    await load();
    listEnd = value;
    notifyListeners();
    await (await SharedPreferences.getInstance()).setString(
      'player.listEnd',
      value.name,
    );
  }
}
