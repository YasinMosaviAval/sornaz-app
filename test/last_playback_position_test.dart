import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sornaz/screens/Players/services/last_playback_position.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('music and video each retain only the latest file', () async {
    await LastPlaybackPositionStore.saveMusic('/first.mp3', 12000);
    await LastPlaybackPositionStore.saveMusic('/second.mp3', 34000);
    await LastPlaybackPositionStore.saveVideo('content://first', 5000);
    await LastPlaybackPositionStore.saveVideo('content://second', 9000);

    final music = await LastPlaybackPositionStore.readMusic();
    final video = await LastPlaybackPositionStore.readVideo();
    expect(music?.id, '/second.mp3');
    expect(music?.milliseconds, 34000);
    expect(video?.id, 'content://second');
    expect(video?.milliseconds, 9000);
    final prefs = await SharedPreferences.getInstance();
    expect(
      prefs.getKeys().where((key) => key.startsWith('music.position.')),
      isEmpty,
    );
    expect(
      prefs.getKeys().where((key) => key.startsWith('video.position.')),
      isEmpty,
    );
  });

  test('legacy music positions migrate only for the last file', () async {
    SharedPreferences.setMockInitialValues({
      'music.lastFile': '/last.mp3',
      'music.position./old.mp3': 14000,
      'music.position./last.mp3': 28000,
    });
    final saved = await LastPlaybackPositionStore.readMusic();
    expect(saved?.id, '/last.mp3');
    expect(saved?.milliseconds, 28000);
    final prefs = await SharedPreferences.getInstance();
    expect(
      prefs.getKeys().where((key) => key.startsWith('music.position.')),
      isEmpty,
    );
    expect(prefs.containsKey('music.lastFile'), false);
  });
}
