import 'package:shared_preferences/shared_preferences.dart';

/// Keep the shared lyrics editor's text attached when a recording URI changes.
Future<void> moveRecordingText(String before, String? after) async {
  if (before == after) return;
  final prefs = await SharedPreferences.getInstance();
  for (final prefix in ['music_lyrics', 'audio_notes']) {
    final key = '${prefix}_$before';
    final text = prefs.getString(key);
    if (text == null) continue;
    if (after != null && !await prefs.setString('${prefix}_$after', text)) {
      throw StateError('Could not move recording text');
    }
    await prefs.remove(key);
  }
}
