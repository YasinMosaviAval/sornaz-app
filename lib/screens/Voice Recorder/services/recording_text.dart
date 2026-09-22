import 'package:shared_preferences/shared_preferences.dart';

/// Keep the shared lyrics editor's text attached when a recording URI changes.
Future<void> moveRecordingText(String before, String? after) async {
  if (before == after) return;
  final prefs = await SharedPreferences.getInstance();
  final key = 'music_lyrics_$before';
  final text = prefs.getString(key);
  if (text == null) return;
  if (after != null && !await prefs.setString('music_lyrics_$after', text)) {
    throw StateError('Could not move recording text');
  }
  await prefs.remove(key);
}
