import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:sornaz/screens/Site/chat_management.dart';
import 'package:flutter/services.dart';
import 'package:sornaz/screens/Players/ui/pages/video_player_page.dart';
import 'package:sornaz/screens/Players/ui/pages/video_crop_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';
import 'package:sornaz/screens/Site/chat_cache.dart';
import 'package:sornaz/screens/Site/chat_media.dart';
import 'package:sornaz/screens/Site/chat_message_bubble.dart';
import 'package:sornaz/screens/Site/chat_offline_sync.dart';
import 'package:sornaz/screens/Site/panel_api.dart';
import 'package:sornaz/screens/Site/panel_resource_page.dart';
import 'package:sornaz/screens/Social/social_api.dart';
import 'package:sornaz/screens/Social/social_widgets.dart';
import 'native_panel_test.dart' show reply;
import 'social_widget_test.dart' as fixture;
import 'story_playback_test.dart' show FakeVideo;

class FeedVideo extends FakeVideo {
  @override
  Future<void> initialize() async {
    value = VideoPlayerValue(
      duration: const Duration(seconds: 30),
      size: const Size(640, 360),
      isInitialized: true,
    );
  }

  @override
  Future<void> setPlaybackSpeed(double speed) async {
    value = value.copyWith(playbackSpeed: speed);
  }

  @override
  Future<void> setVolume(double volume) async {
    value = value.copyWith(volume: volume);
  }
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    SocialApi.locale = 'fa';
  });
  test(
    'chat responses survive client recreation offline and stay account scoped',
    () async {
      final online = PanelApi(
        'first',
        client: MockClient(
          (_) async => reply({
            'messages': [
              {'id': 5, 'body': 'Saved'},
            ],
          }),
        ),
      );
      await online.get('/chat/messages', {'id': '1', 'after': '0'});
      online.dispose();
      final offline = PanelApi(
        'first',
        client: MockClient((_) async => throw StateError('offline')),
      );
      expect(
        (await offline.get('/chat/messages', {
          'id': '1',
          'after': '0',
        }))['messages'][0]['body'],
        'Saved',
      );
      final other = PanelApi(
        'second',
        client: MockClient((_) async => throw StateError('offline')),
      );
      await expectLater(
        other.get('/chat/messages', {'id': '1', 'after': '0'}),
        throwsStateError,
      );
      final denied = PanelApi(
        'first',
        client: MockClient((_) async => reply({}, 403)),
      );
      await expectLater(
        denied.get('/chat/messages', {'id': '1', 'after': '0'}),
        throwsA(isA<SocialException>()),
      );
      offline.dispose();
      other.dispose();
      denied.dispose();
    },
  );
  test(
    'offline sync exhausts all history pages without marking them read or polling',
    () async {
      final cursors = <String>[];
      final api = PanelApi(
        'sync',
        client: MockClient((r) async {
          if (r.url.path.endsWith('/panel')) return reply({'sections': []});
          expect(r.url.queryParameters['read'], '0');
          final cursor = r.url.queryParameters['after']!;
          cursors.add(cursor);
          return reply({
            'messages': [
              for (
                var i = cursor == '0' ? 1 : 201;
                i <= (cursor == '0' ? 200 : 205);
                i++
              )
                {'id': i, 'body': 'Message $i'},
            ],
          });
        }),
      );
      final sync = ChatOfflineSync(api)
        ..start([
          {'id': 1},
        ]);
      sync.timer?.cancel();
      await sync.step();
      sync.timer?.cancel();
      await sync.step();
      sync.timer?.cancel();
      expect(cursors, ['0', '200']);
      expect(await ChatCache.read('sync', 'conversation:1'), hasLength(205));
      expect(sync.running, false);
      expect(cursors, hasLength(2));
      sync.dispose();
      api.dispose();
    },
  );
  testWidgets(
    'private chat hides sender names, replies in composer and deletes selected messages',
    (tester) async {
      final payloads = <Json>[];
      final deletes = <String>[];
      final rows = <Json>[
        for (var i = 1; i <= 2; i++)
          {
            'id': i,
            'body': 'Message $i',
            'mine': true,
            'sender': 'Hidden sender',
            'createdAt': '2026-09-24T12:00:00Z',
          },
        {'id': 3, 'body': 'Incoming', 'sender': 'Hidden sender', 'mine': false},
      ];
      final api = PanelApi(
        '',
        client: MockClient((r) async {
          if (r.method == 'POST') {
            if (r.url.path.endsWith('delete-message'))
              deletes.add(r.url.queryParameters['id']!);
            final encoded = RegExp(
              r'name="payload_b64"\r\n\r\n([^\r]+)',
            ).firstMatch(r.body)?.group(1);
            if (encoded != null)
              payloads.add(
                object(jsonDecode(utf8.decode(base64Decode(encoded)))),
              );
            return reply({'id': 4});
          }
          return reply({'messages': rows});
        }),
      );
      await tester.pumpWidget(
        fixture.host(
          PanelConversationPage(
            api: api,
            conversation: const {'id': 1, 'title': 'Peer', 'type': 'direct'},
            section: const {
              'actions': {'send': {}, 'delete-message': {}},
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Hidden sender'), findsNothing);
      expect(find.byIcon(Icons.refresh), findsNothing);
      expect(find.byIcon(Icons.info_outline), findsNothing);
      await tester.tap(find.byTooltip('پاسخ').first);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'A reply');
      await tester.tap(find.byIcon(Icons.send));
      await tester.pumpAndSettle();
      expect(payloads.last['replyTo'], 1);
      expect(payloads.last['body'], 'A reply');
      await tester.longPress(find.text('Message 1'));
      await tester.pumpAndSettle();
      await tester.tapAt(tester.getCenter(find.text('Message 2')));
      await tester.pumpAndSettle();
      expect(
        tester
            .widgetList<ChatMessageBubble>(find.byType(ChatMessageBubble))
            .where((b) => b.selected),
        hasLength(2),
      );
      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();
      await tester.tap(find.text('حذف'));
      await tester.pumpAndSettle();
      expect(deletes, ['1', '2']);
      expect(find.text('Message 1'), findsNothing);
      expect(find.text('Incoming'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      api.dispose();
    },
  );
  testWidgets('group notices have no bubble or message actions', (
    tester,
  ) async {
    await tester.pumpWidget(
      fixture.host(
        Scaffold(
          body: ChatMessageBubble(
            message: const {
              'id': 1,
              'system': true,
              'body': 'Member joined',
              'createdAt': '2026-09-24T12:34:00Z',
            },
            actions: const {'like': {}, 'forward': {}},
            onAction: (_) => fail('System action'),
          ),
        ),
      ),
    );
    final text = tester.widget<Text>(find.text('Member joined  12:34'));
    expect(text.textAlign, TextAlign.center);
    expect(text.maxLines, 1);
    expect(find.byType(IconButton), findsNothing);
    expect(find.byKey(const ValueKey('message-body-1')), findsNothing);
  });
  testWidgets(
    'expired story preview is hidden for recipients and retained for its owner',
    (tester) async {
      final api = PanelApi('');
      for (final owner in [false, true]) {
        await tester.pumpWidget(
          fixture.host(
            Scaffold(
              body: ChatMedia(
                key: ValueKey(owner),
                api: api,
                message: {
                  'reference': {
                    'id': 1,
                    'kind': 'story',
                    'available': true,
                    'owner': owner,
                    'expiresAt': '2000-01-01T00:00:00Z',
                    'body': 'Archived story',
                  },
                },
                onDownload: () => fail('Unexpected download'),
              ),
            ),
          ),
        );
        await tester.pump();
        expect(
          find.text('Archived story'),
          owner ? findsOneWidget : findsNothing,
        );
        expect(
          find.text('این محتوا دیگر در دسترس نیست'),
          owner ? findsNothing : findsOneWidget,
        );
      }
      await tester.pumpWidget(const SizedBox());
      api.dispose();
    },
  );
  testWidgets(
    'feed video autoplays once, exposes overlay controls, and restores held speed',
    (tester) async {
      final video = FeedVideo();
      final api = SocialApi('');
      await tester.pumpWidget(
        fixture.host(
          Scaffold(
            body: SocialVideo(
              api: api,
              path: '/feed-once-test.mp4',
              postControls: true,
              autoplay: true,
              controllerFactory: () => video,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 350));
      expect(video.plays, 1);
      expect(find.byType(VideoProgressIndicator), findsOneWidget);
      expect(
        tester
            .widget<VideoProgressIndicator>(find.byType(VideoProgressIndicator))
            .padding,
        EdgeInsets.zero,
      );
      expect(find.byIcon(Icons.fullscreen), findsNothing);
      expect(find.byIcon(Icons.speed), findsNothing);
      expect(find.byIcon(Icons.note_alt_outlined), findsNothing);
      final surface = tester.getRect(find.byType(VideoPlayer));
      final gesture = await tester.startGesture(
        Offset(surface.right - 80, surface.center.dy),
      );
      await tester.pump(const Duration(milliseconds: 600));
      expect(video.value.playbackSpeed, 2);
      await gesture.up();
      await tester.pump();
      expect(video.value.playbackSpeed, 1);
      final left = await tester.startGesture(
        Offset(surface.left + 80, surface.center.dy),
      );
      await tester.pump(const Duration(milliseconds: 600));
      expect(video.value.playbackSpeed, .5);
      await left.up();
      await tester.pump();
      expect(video.value.playbackSpeed, 1);
      video.advance(30);
      await video.pause();
      await tester.pump(const Duration(seconds: 2));
      expect(video.plays, 1);
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
      await tester.tap(find.byIcon(Icons.play_arrow));
      await tester.pump();
      expect(video.plays, 2);
      expect(video.value.position, Duration.zero);
      await tester.pumpWidget(const SizedBox());
      api.dispose();
      expect(video.released, true);
    },
  );
  testWidgets('open story loses access when its expiry timer elapses', (
    tester,
  ) async {
    await tester.pumpWidget(
      fixture.host(
        ChatReferenceAccess(
          expiresAt: DateTime.now().add(const Duration(seconds: 2)),
          child: const Scaffold(body: Text('Visible story')),
        ),
      ),
    );
    expect(find.text('Visible story'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    expect(find.text('Visible story'), findsNothing);
    expect(find.text('این محتوا دیگر در دسترس نیست'), findsOneWidget);
  });
  testWidgets(
    'device video toolbar search, rename and bulk share/delete use the selected files',
    (tester) async {
      const channel = MethodChannel('sornaz/device_videos');
      const permissions = MethodChannel(
        'flutter.baseflow.com/permissions/methods',
      );
      const media = MethodChannel('sornaz/story_media');
      final calls = <MethodCall>[];
      final rows = <Json>[
        for (var i = 1; i <= 2; i++)
          {
            'uri': 'content://media/external/video/media/$i',
            'name': 'Clip $i.mp4',
            'folder': 'Camera',
            'folderId': '1',
            'duration': 30000,
          },
      ];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
        call,
      ) async {
        if (call.method == 'sdk') return 33;
        if (call.method == 'list') return rows;
        calls.add(call);
        if (call.method == 'rename')
          rows.first['name'] = call.arguments['name'];
        if (call.method == 'delete')
          rows.removeWhere(
            (r) => (call.arguments['uris'] as List).contains(r['uri']),
          );
        return null;
      });
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        permissions,
        (call) async => {for (final key in call.arguments as List) key: 1},
      );
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        media,
        (_) async => null,
      );
      addTearDown(() {
        for (final channel in [channel, permissions, media]) {
          tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
            channel,
            null,
          );
        }
      });
      await tester.pumpWidget(fixture.host(const VideoLibraryPage()));
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsNothing);
      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Clip 2');
      await tester.pumpAndSettle();
      expect(find.text('Clip 1.mp4'), findsNothing);
      expect(find.text('Clip 2.mp4'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(PopupMenuButton<String>).first);
      await tester.pumpAndSettle();
      for (final label in ['تغییر نام', 'برش ویدیو', 'اشتراک‌گذاری', 'حذف']) {
        expect(find.text(label), findsOneWidget);
      }
      await tester.tap(find.text('تغییر نام'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField), 'Renamed');
      await tester.tap(find.text('ذخیره'));
      await tester.pumpAndSettle();
      expect(calls.last.method, 'rename');
      expect(calls.last.arguments['name'], 'Renamed.mp4');
      await tester.longPress(find.text('Renamed.mp4'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.check_box_outline_blank));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(PopupMenuButton<String>).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('اشتراک‌گذاری'));
      await tester.pumpAndSettle();
      expect(calls.last.method, 'share');
      expect(calls.last.arguments['uris'], hasLength(2));
      await tester.longPress(find.text('Renamed.mp4'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.check_box_outline_blank));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(PopupMenuButton<String>).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('حذف'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('حذف'));
      await tester.pumpAndSettle();
      expect(calls.last.method, 'delete');
      expect(calls.last.arguments['uris'], hasLength(2));
      expect(find.text('ویدیویی پیدا نشد'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets('video trim exports the selected range as a new video', (
    tester,
  ) async {
    const crop = MethodChannel('sornaz/audio_crop');
    const videos = MethodChannel('sornaz/device_videos');
    final calls = <MethodCall>[];
    for (final channel in [crop, videos]) {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
        call,
      ) async {
        calls.add(call);
        return call.method == 'render' ? 'missing-test-crop.mp4' : null;
      });
    }
    addTearDown(() {
      for (final channel in [crop, videos]) {
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          channel,
          null,
        );
      }
    });
    final player = FeedVideo();
    await tester.pumpWidget(
      fixture.host(
        VideoCropPage(
          uri: 'content://media/external/video/media/1',
          name: 'Clip',
          controllerFactory: () => player,
        ),
      ),
    );
    await tester.pumpAndSettle();
    tester.widget<RangeSlider>(find.byType(RangeSlider)).onChanged!(
      const RangeValues(5000, 12000),
    );
    await tester.pump();
    await tester.tap(find.text('ذخیره به عنوان ویدیوی جدید'));
    await tester.pumpAndSettle();
    expect(calls.first.method, 'render');
    expect(calls.first.arguments['video'], true);
    expect(calls.first.arguments['start'], 5000);
    expect(calls.first.arguments['end'], 12000);
    expect(calls.last.method, 'saveCrop');
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets(
    'offline reopening preserves edited history over stale response pages',
    (tester) async {
      final online = PanelApi(
        '',
        client: MockClient(
          (_) async => reply({
            'messages': [
              {'id': 1, 'body': 'Old text'},
              {'id': 2, 'body': 'Deleted message'},
            ],
          }),
        ),
      );
      await online.get('/chat/messages', {'id': '1', 'after': '0'});
      online.dispose();
      await ChatCache.write('', 'conversation:1', [
        {'id': 1, 'body': 'Edited text', 'mine': true},
      ]);
      final offline = PanelApi(
        '',
        client: MockClient((_) async => throw StateError('Offline')),
      );
      await tester.pumpWidget(
        fixture.host(
          PanelConversationPage(
            api: offline,
            conversation: const {'id': 1, 'title': 'Chat', 'type': 'direct'},
            section: const {'actions': {}},
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Edited text'), findsOneWidget);
      expect(find.text('Old text'), findsNothing);
      expect(find.text('Deleted message'), findsNothing);
      await tester.pumpWidget(const SizedBox());
      offline.dispose();
    },
  );
  testWidgets(
    'conversation management sheet follows direct and group permissions',
    (tester) async {
      const actions = {
        'rename': {'label': 'Rename'},
        'avatar': {'label': 'Picture'},
        'members': {'label': 'Add member'},
        'leave': {'label': 'Leave'},
        'delete': {'label': 'Delete'},
      };
      for (final permissions in [
        {
          'type': 'direct',
          'canManage': false,
          'canDelete': true,
          'canLeave': false,
        },
        {
          'type': 'group',
          'canManage': false,
          'canDelete': false,
          'canLeave': true,
        },
        {
          'type': 'group',
          'canManage': true,
          'canDelete': true,
          'canLeave': false,
        },
      ]) {
        final api = PanelApi(
          '',
          client: MockClient((_) async => reply(permissions)),
        );
        await tester.pumpWidget(
          fixture.host(
            Scaffold(
              body: Builder(
                builder: (context) => TextButton(
                  onPressed: () => conversationMenu(
                    context,
                    api,
                    {'actions': actions},
                    {'id': 1},
                  ),
                  child: const Text('Manage'),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Manage'));
        await tester.pumpAndSettle();
        for (final name in ['Rename', 'Picture', 'Add member']) {
          expect(
            find.text(name),
            permissions['canManage'] == true ? findsOneWidget : findsNothing,
          );
        }
        expect(
          find.text('Delete'),
          permissions['canDelete'] == true ? findsOneWidget : findsNothing,
        );
        expect(
          find.text('Leave'),
          permissions['canLeave'] == true ? findsOneWidget : findsNothing,
        );
        Navigator.of(tester.element(find.text('Manage'))).pop();
        await tester.pumpAndSettle();
        await tester.pumpWidget(const SizedBox());
        api.dispose();
      }
    },
  );
  testWidgets(
    'chat video is a first-frame preview and its attachment remains available offline',
    (tester) async {
      final dir = await tester.runAsync(
        () => Directory.systemTemp.createTemp('sornaz-chat-test-'),
      );
      const paths = MethodChannel('plugins.flutter.io/path_provider');
      const thumbnails = MethodChannel('sornaz/story_media');
      final frames = <MethodCall>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        paths,
        (_) async => dir!.path,
      );
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(thumbnails, (
        call,
      ) async {
        frames.add(call);
        return base64Decode(
          'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
        );
      });
      addTearDown(() async {
        for (final channel in [paths, thumbnails]) {
          tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
            channel,
            null,
          );
        }
        await dir!.delete(recursive: true);
      });
      final api = PanelApi(
        'media-test',
        client: MockClient((r) async {
          expect(r.url.path, endsWith('/chat/file'));
          expect(r.followRedirects, false);
          return http.Response.bytes([1, 2, 3], 200);
        }),
      );
      await tester.runAsync(() async {
        await tester.pumpWidget(
          fixture.host(
            Scaffold(
              body: ChatMedia(
                api: api,
                message: const {
                  'id': 91,
                  'file': {'mime': 'video/mp4', 'name': 'clip.mp4'},
                },
                onDownload: () => fail('Unexpected download chooser'),
              ),
            ),
          ),
        );

        await Future.wait(ChatFiles.pending.values.toList());
        await Future<void>.delayed(const Duration(milliseconds: 20));
      });
      await tester.pumpAndSettle();
      for (
        var attempt = 0;
        attempt < 5 && find.byType(Image).evaluate().isEmpty;
        attempt++
      ) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)),
        );
        await tester.pump();
      }
      expect(frames.single.arguments['timeMs'], 0);
      expect(find.byType(Image), findsOneWidget);
      expect(find.byIcon(Icons.play_circle_fill), findsOneWidget);
      expect(find.byType(SocialVideo), findsNothing);
      await tester.pumpWidget(const SizedBox());
      api.dispose();
      final offline = PanelApi(
        'media-test',
        client: MockClient((_) async => throw StateError('Offline')),
      );
      final saved = await tester.runAsync(() => ChatFiles.open(offline, '91'));
      expect(await tester.runAsync(() => saved!.readAsBytes()), [1, 2, 3]);
      offline.dispose();
      expect(chatAudio({'mime': 'video/mp4', 'name': 'voice-123.m4a'}), true);
      expect(chatAudio({'mime': 'video/webm', 'name': 'voice-123.webm'}), true);
    },
  );
}
