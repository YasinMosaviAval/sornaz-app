import 'package:shared_preferences/shared_preferences.dart';

class LastPlaybackPosition {
  const LastPlaybackPosition(this.id, this.milliseconds);

  final String id;
  final int milliseconds;

  static LastPlaybackPosition? fromList(List<String>? values) {
    if (values == null || values.length != 2 || values.first.isEmpty) {
      return null;
    }
    final milliseconds = int.tryParse(values.last);
    if (milliseconds == null || milliseconds < 0) return null;
    return LastPlaybackPosition(values.first, milliseconds);
  }
}

class LastPlaybackPositionStore {
  static const _musicKey = 'music.lastPlayback';
  static const _videoKey = 'video.lastPlayback';

  static Future<void> saveMusic(String path, int milliseconds) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_musicKey, [path, '$milliseconds']);
  }

  static Future<void> saveVideo(String uri, int milliseconds) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_videoKey, [uri, '$milliseconds']);
  }

  static Future<LastPlaybackPosition?> readMusic() async {
    final prefs = await SharedPreferences.getInstance();
    var record = LastPlaybackPosition.fromList(prefs.getStringList(_musicKey));
    if (record == null) {
      final path = prefs.getString('music.lastFile');
      if (path != null && path.isNotEmpty) {
        record = LastPlaybackPosition(
          path,
          prefs.getInt('music.position.$path') ?? 0,
        );
        await saveMusic(record.id, record.milliseconds);
      }
    }
    await _removeLegacy(prefs, 'music.position.');
    await prefs.remove('music.lastFile');
    return record;
  }

  static Future<LastPlaybackPosition?> readVideo() async {
    final prefs = await SharedPreferences.getInstance();
    final record = LastPlaybackPosition.fromList(
      prefs.getStringList(_videoKey),
    );
    // Legacy video positions have no last-played identifier, so they cannot
    // safely be migrated to a single last-video record.
    await _removeLegacy(prefs, 'video.position.');
    return record;
  }

  static Future<void> clearMusic() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_musicKey);
    await prefs.remove('music.lastFile');
    await _removeLegacy(prefs, 'music.position.');
  }

  static Future<void> clearVideo() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_videoKey);
    await _removeLegacy(prefs, 'video.position.');
  }

  static Future<void> _removeLegacy(
    SharedPreferences prefs,
    String prefix,
  ) async {
    for (final key in prefs.getKeys().where((key) => key.startsWith(prefix))) {
      await prefs.remove(key);
    }
  }
}
