import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sornaz/screens/Social/social_api.dart';
import 'package:sornaz/screens/Social/story_composer.dart';
import 'package:sornaz/screens/Social/story_text_editor.dart';
import 'social_widget_test.dart' as fixture;

class PublishingApi extends SocialApi {
  PublishingApi() : super('token');
  final uploads = <PlatformFile>[];
  final posts = <Map<String, String>>[];
  @override
  Future<Json> upload(PlatformFile file, {int? courseId}) async {
    uploads.add(file);
    return {'id': 41};
  }

  @override
  Future<dynamic> post(
    String path, [
    Map<String, String> body = const {},
  ]) async {
    posts.add(body);
    return {'id': 42};
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test('duration labels and all three text color modes', () {
    expect(storyDuration(65000), '1:05');
    expect(storyDuration(3661000), '1:01:01');
    for (var mode = 0; mode < 3; mode++) {
      final s = StorySticker(text: 'Music', color: Colors.red, mode: mode);
      expect(s.foreground, mode == 1 ? Colors.white : Colors.red);
      expect(
        s.background,
        [Colors.transparent, Colors.red, Colors.white][mode],
      );
    }
  });
  test(
    'eyedropper maps contain and cover coordinates without sampling letterbox',
    () {
      final rgba = Uint8List.fromList([255, 0, 0, 255, 0, 0, 255, 255]);
      expect(
        sampleStoryColor(
          rgba,
          const Size(2, 1),
          const Size(100, 100),
          const Offset(10, 10),
          BoxFit.contain,
        ),
        isNull,
      );
      expect(
        sampleStoryColor(
          rgba,
          const Size(2, 1),
          const Size(100, 100),
          const Offset(10, 50),
          BoxFit.contain,
        ),
        const Color(0xffff0000),
      );
      expect(
        sampleStoryColor(
          rgba,
          const Size(2, 1),
          const Size(100, 100),
          const Offset(90, 50),
          BoxFit.cover,
        ),
        const Color(0xff0000ff),
      );
    },
  );
  testWidgets(
    'gallery has portrait triples, duration and private camera without upload',
    (tester) async {
      final png = (await tester.runAsync(() async {
        final recorder = ui.PictureRecorder();
        Canvas(recorder).drawRect(
          const Rect.fromLTWH(0, 0, 20, 20),
          Paint()..color = Colors.blue,
        );
        final picture = recorder.endRecording();
        final image = await picture.toImage(20, 20);
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        image.dispose();
        picture.dispose();
        return data!.buffer.asUint8List();
      }))!;
      final calls = <MethodCall>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        StoryMediaBridge.channel,
        (call) async {
          calls.add(call);
          switch (call.method) {
            case 'permission':
              return 'full';
            case 'gallery':
              return [
                {'uri': 'content://image/1', 'video': false},
                {'uri': 'content://video/2', 'video': true, 'duration': 65000},
              ];
            case 'thumbnail':
              return png;
            case 'camera':
              return {
                'path': '/private/story.jpg',
                'uri': 'content://camera/1',
                'video': false,
                'size': 100,
                'name': 'story.jpg',
              };
            case 'delete':
              return null;
            case 'savePermission':
              return true;
            case 'writeImage':
              return {
                'path': '/private/designed.png',
                'name': 'designed.png',
                'size': 100,
              };
            case 'save':
              return 'content://saved/1';
          }
          throw StateError('Unexpected ${call.method}');
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          StoryMediaBridge.channel,
          null,
        ),
      );
      final api = PublishingApi();
      await tester.pumpWidget(fixture.host(StoryComposer(api: api)));
      await tester.pumpAndSettle();
      final grid = tester.widget<GridView>(find.byType(GridView));
      final layout =
          grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
      expect(layout.crossAxisCount, 3);
      expect(layout.childAspectRatio, 9 / 16);
      expect(find.text('1:05'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.camera_alt_outlined));
      await tester.pump();
      // Image codec completion is asynchronous, outside fake frame time.
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pumpAndSettle();
      expect(find.text('یک عنوان اضافه کنید'), findsOneWidget);
      expect(find.text('انتشار'), findsOneWidget);
      expect(find.byIcon(Icons.text_fields), findsOneWidget);
      expect(find.byIcon(Icons.alternate_email), findsOneWidget);
      expect(find.byIcon(Icons.save_alt), findsOneWidget);
      expect(api.uploads, isEmpty);
      expect(calls.where((c) => c.method == 'save'), isEmpty);
      await tester.tap(find.text('یک عنوان اضافه کنید'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'A music moment');
      await tester.tap(find.text('تأیید'));
      await tester.pumpAndSettle();
      expect(find.text('A music moment'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.save_alt));
      for (var i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 100));
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)),
        );
      }
      await tester.pumpAndSettle();
      expect(calls.where((c) => c.method == 'save').length, 1);
      expect(api.uploads, isEmpty);
      final pngOutput =
          calls.firstWhere((c) => c.method == 'writeImage').arguments['bytes']
              as Uint8List;
      expect(pngOutput.take(4), [137, 80, 78, 71]);
      await tester.tap(find.text('انتشار'));
      for (var i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 100));
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)),
        );
      }
      await tester.pumpAndSettle();
      expect(api.uploads.single.name, 'designed.png');
      expect(api.posts.single, {'kind': 'story', 'body': '', 'media_id': '41'});
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      expect(
        calls
            .where((c) => c.method == 'delete')
            .any(
              (c) =>
                  (c.arguments['paths'] as List).contains('/private/story.jpg'),
            ),
        isTrue,
      );
      expect(tester.takeException(), isNull);
      api.dispose();
    },
  );
  testWidgets(
    'mentions require selection and debounce user search without checkboxes',
    (tester) async {
      final queries = <Uri>[];
      final api = SocialApi(
        'token',
        client: MockClient((r) async {
          queries.add(r.url);
          return http.Response(
            jsonEncode({
              'success': true,
              'data': [
                {'id': 2, 'username': 'pianist'},
              ],
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      );
      await tester.pumpWidget(
        fixture.host(
          Scaffold(
            body: StoryMentionPicker(api: api, initial: const []),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );
      expect(find.byType(Checkbox), findsNothing);
      await tester.tap(find.text('pianist'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNotNull,
      );
      await tester.enterText(find.byType(TextField), 'p');
      await tester.pump(const Duration(milliseconds: 100));
      await tester.enterText(find.byType(TextField), 'piano');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      expect(queries.length, 2);
      expect(queries.last.queryParameters['q'], 'piano');
      await tester.pumpWidget(const SizedBox());
      api.dispose();
    },
  );
}
