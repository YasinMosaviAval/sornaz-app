import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sornaz/screens/Players/services/player_settings.dart';
import 'package:sornaz/screens/Players/ui/pages/video_player_page.dart';
import 'social_widget_test.dart' as fixture;

void main() {
  testWidgets(
    'video defaults to lazy three-column grid and hides item menus during selection',
    (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.linux;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      SharedPreferences.setMockInitialValues({
        'video.playlists': jsonEncode({
          'Practice': [
            'content://media/external/video/media/2',
            'content://media/external/video/media/1',
          ],
        }),
      });
      final settings = PlayerSettings.instance;
      await settings.setOption('videoTabOrder', ['0', '1', '2']);
      await settings.setOption('videoHiddenTabs', <String>[]);
      await settings.setOption('videoHiddenUris', <String>[]);
      await settings.setOption('videoHiddenFolders', <String>[]);
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(
        const MethodChannel('sornaz/device_videos'),
        (call) async {
          if (call.method == 'sdk') return 33;
          if (call.method == 'list')
            return [
              for (var i = 0; i < 1000; i++)
                {
                  'uri': 'content://media/external/video/media/$i',
                  'name': 'video-$i.mp4',
                  'folder': 'Videos',
                  'folderId': '1',
                  'duration': 1000,
                  'addedAt': i,
                },
            ];
          return null;
        },
      );
      messenger.setMockMethodCallHandler(
        const MethodChannel('sornaz/story_media'),
        (_) async => null,
      );
      addTearDown(() {
        messenger.setMockMethodCallHandler(
          const MethodChannel('sornaz/device_videos'),
          null,
        );
        messenger.setMockMethodCallHandler(
          const MethodChannel('sornaz/story_media'),
          null,
        );
      });
      await tester.pumpWidget(fixture.host(const VideoLibraryPage()));
      await tester.pumpAndSettle();
      expect(
        (tester.widget<GridView>(find.byType(GridView)).gridDelegate
                as SliverGridDelegateWithFixedCrossAxisCount)
            .crossAxisCount,
        3,
      );
      expect(find.byType(VideoThumbnail).evaluate().length, lessThan(30));
      expect(find.byType(PopupMenuButton<String>), findsWidgets);
      await tester.longPress(find.byType(VideoThumbnail).first);
      await tester.pumpAndSettle();
      expect(find.byType(PopupMenuButton<String>), findsOneWidget);
      await tester.tap(find.widgetWithIcon(IconButton, Icons.close));
      await tester.pumpAndSettle();
      expect(
        find.byType(PopupMenuButton<String>).evaluate().length,
        greaterThan(1),
      );
      await tester.tap(find.text('لیست پخش‌ها'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Practice'));
      await tester.pumpAndSettle();
      final labels = tester
          .widgetList<Text>(find.byType(Text))
          .map((text) => text.data)
          .whereType<String>()
          .toList();
      expect(
        labels.indexOf('video-2.mp4'),
        lessThan(labels.indexOf('video-1.mp4')),
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      debugDefaultTargetPlatformOverride = null;
    },
  );
}
