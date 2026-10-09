import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sornaz/screens/Players/services/player_settings.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'music and video preferences persist and folders hide descendants only',
    () async {
      SharedPreferences.setMockInitialValues({});
      final settings = PlayerSettings();
      await settings.load();
      expect(settings.musicSort, 'added');
      expect(settings.videoSort, 'added');
      expect(settings.musicSortAscending, isFalse);
      expect(settings.videoSortAscending, isFalse);
      await settings.setOption('savePlaybackPosition', true);
      await settings.setOption('videoSavePlaybackPosition', true);
      await settings.setOption('musicSort', 'duration');
      await settings.setOption('musicSortAscending', true);
      await settings.setOption('tabOrder', ['2', '0', '3', '1']);
      await settings.setOption('hiddenTabs', ['3']);
      await settings.setOption('hiddenPaths', ['/music/album']);
      await settings.setOption('videoTabOrder', ['2', '0', '1']);
      await settings.setOption('videoHiddenTabs', ['1']);
      await settings.setOption('videoSort', 'count');
      await settings.setOption('videoSortAscending', true);
      await settings.setOption('videoHiddenUris', ['content://video/7']);
      await settings.setOption('videoHiddenFolders', ['42']);
      final restored = PlayerSettings();
      await restored.load();
      expect(restored.savePlaybackPosition, isTrue);
      expect(restored.videoSavePlaybackPosition, isTrue);
      expect(restored.musicSort, 'duration');
      expect(restored.musicSortAscending, isTrue);
      expect(restored.tabOrder, ['2', '0', '3', '1']);
      expect(restored.hiddenTabs, ['3']);
      expect(restored.videoTabOrder, ['2', '0', '1']);
      expect(restored.videoHiddenTabs, ['1']);
      expect(restored.videoSort, 'count');
      expect(restored.videoSortAscending, isTrue);
      expect(restored.videoHiddenUris, ['content://video/7']);
      expect(restored.videoHiddenFolders, ['42']);
      expect(restored.isHidden('/music/album/song.mp3'), isTrue);
      expect(restored.isHidden('/music/album/disc/song.mp3'), isTrue);
      expect(restored.isHidden('/music/album-two/song.mp3'), isFalse);
      await restored.setOption('hiddenPaths', <String>[]);
      expect(restored.isHidden('/music/album/song.mp3'), isFalse);
      settings.dispose();
      restored.dispose();
    },
  );
}
