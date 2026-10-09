import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'last_playback_position.dart';

enum ListEndAction { restart, nextList, stop }

enum PlaybackInterruption { leavePlayer, exitApp, recording, metronome, tuner }

class PlayerSettings extends ChangeNotifier {
  static final instance = PlayerSettings();
  final Map<PlaybackInterruption, bool> _stop = {};
  ListEndAction listEnd = ListEndAction.stop;
  Future<void>? _loading;
  bool savePlaybackPosition = false;
  String musicSort = 'added';
  String videoSort = 'added';
  bool musicSortAscending = false;
  bool videoSortAscending = false;
  bool videoSavePlaybackPosition = false;
  List<String> tabOrder = ['0', '1', '2', '3'];
  List<String> hiddenTabs = [], hiddenPaths = [];
  List<String> videoTabOrder = ['0', '1', '2'];
  List<String> videoHiddenTabs = [],
      videoHiddenUris = [],
      videoHiddenFolders = [];
  bool isHidden(String path) => hiddenPaths.any(
    (p) => path == p || path.startsWith('$p/') || path.startsWith('$p\\'),
  );
  Future<void> setOption(String key, Object value) async {
    await load();
    final prefs = await SharedPreferences.getInstance();
    if (value is bool) await prefs.setBool('player.$key', value);
    if (value is String) await prefs.setString('player.$key', value);
    if (value is List<String>) await prefs.setStringList('player.$key', value);
    switch (key) {
      case 'savePlaybackPosition':
        savePlaybackPosition = value as bool;
      case 'musicSort':
        musicSort = value as String;
      case 'videoSort':
        videoSort = value as String;
      case 'musicSortAscending':
        musicSortAscending = value as bool;
      case 'videoSortAscending':
        videoSortAscending = value as bool;
      case 'videoSavePlaybackPosition':
        videoSavePlaybackPosition = value as bool;
      case 'tabOrder':
        tabOrder = List<String>.from(value as List);
      case 'hiddenTabs':
        hiddenTabs = List<String>.from(value as List);
      case 'hiddenPaths':
        hiddenPaths = List<String>.from(value as List);
      case 'videoTabOrder':
        videoTabOrder = List<String>.from(value as List);
      case 'videoHiddenTabs':
        videoHiddenTabs = List<String>.from(value as List);
      case 'videoHiddenUris':
        videoHiddenUris = List<String>.from(value as List);
      case 'videoHiddenFolders':
        videoHiddenFolders = List<String>.from(value as List);
    }
    if (key == 'savePlaybackPosition' && value == false) {
      await LastPlaybackPositionStore.clearMusic();
    }
    if (key == 'videoSavePlaybackPosition' && value == false) {
      await LastPlaybackPositionStore.clearVideo();
    }
    notifyListeners();
  }

  bool stopsFor(PlaybackInterruption reason) =>
      _stop[reason] ?? reason != PlaybackInterruption.leavePlayer;
  Future<void> load() => _loading ??= _load();
  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    savePlaybackPosition =
        prefs.getBool('player.savePlaybackPosition') ?? false;
    musicSort = prefs.getString('player.musicSort') ?? 'added';
    videoSort = prefs.getString('player.videoSort') ?? 'added';
    musicSortAscending =
        prefs.getBool('player.musicSortAscending') ??
        (musicSort == 'name' || musicSort == 'duration');
    videoSortAscending =
        prefs.getBool('player.videoSortAscending') ??
        (videoSort == 'name' || videoSort == 'duration');
    videoSavePlaybackPosition =
        prefs.getBool('player.videoSavePlaybackPosition') ?? false;
    tabOrder = prefs.getStringList('player.tabOrder') ?? ['0', '1', '2', '3'];
    hiddenTabs = prefs.getStringList('player.hiddenTabs') ?? [];
    hiddenPaths = prefs.getStringList('player.hiddenPaths') ?? [];
    videoTabOrder =
        prefs.getStringList('player.videoTabOrder') ?? ['0', '1', '2'];
    videoHiddenTabs = prefs.getStringList('player.videoHiddenTabs') ?? [];
    videoHiddenUris = prefs.getStringList('player.videoHiddenUris') ?? [];
    videoHiddenFolders = prefs.getStringList('player.videoHiddenFolders') ?? [];
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
