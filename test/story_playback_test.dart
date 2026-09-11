import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_player/video_player.dart';
import 'package:sornaz/screens/Social/story_page.dart';
import 'package:sornaz/screens/Social/social_api.dart';
import 'social_widget_test.dart' as fixture;

class FakeVideo extends VideoPlayerController {
  FakeVideo() : super.networkUrl(Uri.parse('https://example.test/story.mp4'));
  int plays = 0;
  bool released = false;
  @override
  Future<void> initialize() async {
    value = VideoPlayerValue(
      duration: const Duration(seconds: 125),
      size: const Size(1080, 1920),
      isInitialized: true,
    );
  }

  @override
  Future<void> setLooping(bool looping) async {}
  @override
  Future<void> seekTo(Duration p) async {
    value = value.copyWith(position: p);
  }

  @override
  Future<void> play() async {
    plays++;
    value = value.copyWith(isPlaying: true);
  }

  @override
  Future<void> pause() async {
    value = value.copyWith(isPlaying: false);
  }

  @override
  // This fake never creates a platform player; avoid native disposal in widget tests.
  // ignore: must_call_super
  Future<void> dispose() async {
    released = true;
  }

  void advance(int seconds) {
    value = value.copyWith(position: Duration(seconds: seconds));
  }
}

void main() {
  test('groups multiple stories under one author without dropping items', () {
    final groups = groupStoriesByAuthor([
      {'id': 1, 'owner_id': 4},
      {'id': 2, 'owner_id': 7},
      {'id': 3, 'owner_id': 4},
    ]);
    expect(groups.length, 2);
    expect(groups.first.map((s) => s['id']), [1, 3]);
  });
  test(
    'minute segmentation preserves exact boundaries and final remainder',
    () {
      expect(storySegments(const Duration(seconds: 60)).length, 1);
      final parts = storySegments(const Duration(seconds: 125));
      expect(parts.length, 3);
      expect(parts[1], (
        const Duration(seconds: 60),
        const Duration(seconds: 120),
      ));
      expect(parts.last.$2 - parts.last.$1, const Duration(seconds: 5));
    },
  );
  testWidgets(
    'video stories autoplay fullscreen with segmented top progress only',
    (tester) async {
      final api = SocialApi('');
      final players = <FakeVideo>[];
      await tester.pumpWidget(
        fixture.host(
          StoryPage(
            api: api,
            stories: [
              for (var i = 1; i <= 2; i++)
                {
                  'id': i,
                  'owner_id': 4,
                  'mime': 'video/mp4',
                  'media': '/story$i',
                  'body': '',
                  'author': {
                    'id': 4,
                    'name': 'Author',
                    'avatar': null,
                    'isMe': true,
                  },
                },
            ],
            controllerFactory: (_) {
              final p = FakeVideo();
              players.add(p);
              return p;
            },
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
      expect(players.first.plays, greaterThan(0));
      expect(find.byType(Slider), findsNothing);
      expect(find.byType(VideoProgressIndicator), findsNothing);
      expect(find.byIcon(Icons.play_arrow), findsNothing);
      expect(find.byType(LinearProgressIndicator), findsNWidgets(4));
      players.first.advance(30);
      await tester.pump();
      expect(
        tester
            .widgetList<LinearProgressIndicator>(
              find.byType(LinearProgressIndicator),
            )
            .first
            .value,
        closeTo(.5, .01),
      );
      players.first.advance(60);
      await tester.pump();
      await tester.pump();
      final bars = tester
          .widgetList<LinearProgressIndicator>(
            find.byType(LinearProgressIndicator),
          )
          .toList();
      expect(bars[0].value, 1);
      expect(bars[1].value, 0);
      players.first.advance(124);
      await tester.pump();
      await tester.pump();
      players.first.advance(124);
      await tester.pump();
      expect(
        tester
            .widgetList<LinearProgressIndicator>(
              find.byType(LinearProgressIndicator),
            )
            .elementAt(2)
            .value,
        closeTo(.8, .01),
      );
      players.first.advance(125);
      await tester.pump();
      await tester.pump();
      expect(players.length, 2);
      expect(players.first.released, true);
      expect(players.last.plays, greaterThan(0));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      api.dispose();
    },
  );
}
