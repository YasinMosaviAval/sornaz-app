import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sornaz/screens/Social/story_page.dart';
import 'package:sornaz/screens/Social/social_profile.dart';

import 'package:sornaz/screens/Social/social_api.dart';
import 'story_playback_test.dart' show FakeVideo;
import 'social_widget_test.dart' as fixture;

void main() {
  testWidgets('oldest unread story opens and horizontal swipe changes author', (
    tester,
  ) async {
    final api = SocialApi('');
    final seen = <int>[];
    Json story(int id, int owner) => {
      'id': id,
      'owner_id': owner,
      'mime': 'video/mp4',
      'media': '/story$id',
      'created_at': '2026-09-20 08:00:0$id',
      'author': {'id': owner, 'username': 'author$owner'},
    };
    final first = [story(3, 1), story(1, 1), story(2, 1)],
        second = [story(4, 2)];
    await tester.pumpWidget(
      fixture.host(
        StoryPage(
          api: api,
          stories: first,
          authorGroups: [first, second],
          seen: {'1'},
          onSeen: seen.add,
          controllerFactory: (_) => FakeVideo(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(seen.last, 2);
    final name = tester.getRect(
      find.byKey(const ValueKey('story-author-name')),
    );
    final age = tester.getRect(find.byKey(const ValueKey('story-age')));
    expect(name.left - age.right, closeTo(4, .01));
    await tester.drag(find.byType(StoryPage), const Offset(200, 0));
    await tester.pump();
    await tester.pump();
    expect(seen.last, 4);
    await tester.drag(find.byType(StoryPage), const Offset(-200, 0));
    await tester.pump();
    await tester.pump();
    expect(seen.last, 2);
    await tester.tap(find.byKey(const ValueKey('story-author-name')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(ProfilePage), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    api.dispose();
  });
  testWidgets('all viewed stories replay in chronological order', (
    tester,
  ) async {
    final api = SocialApi('');
    final seen = <int>[];
    await tester.pumpWidget(
      fixture.host(
        StoryPage(
          api: api,
          stories: [
            for (final id in [3, 1, 2])
              {
                'id': id,
                'mime': 'video/mp4',
                'media': '/story$id',
                'owner_id': 1,
                'author': {'id': 1, 'username': 'author'},
              },
          ],
          seen: {'1', '2', '3'},
          onSeen: seen.add,
          controllerFactory: (_) => FakeVideo(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(seen.first, 1);
    await tester.pumpWidget(const SizedBox());
    api.dispose();
  });
}
