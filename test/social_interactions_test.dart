import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sornaz/screens/Social/social_api.dart';
import 'package:sornaz/screens/Social/user_panel.dart';
import 'package:sornaz/screens/Social/social_widgets.dart';
import 'package:sornaz/screens/Social/story_seen.dart';
import 'package:sornaz/screens/Social/profile_posts_page.dart';
import 'package:sornaz/screens/Social/social_profile.dart';
import 'social_widget_test.dart' as fixture;

http.Response response(Object data) => http.Response(
  jsonEncode({'success': true, 'data': data}),
  200,
  headers: {'content-type': 'application/json; charset=utf-8'},
);
Json post(int id) => {
  'id': id,
  'owner_id': 9,
  'body': 'Post body $id',
  'likes': 0,
  'media': null,
  'author': {'id': 9, 'username': 'musician', 'name': 'hidden@example.test'},
  'comment_count': 1,
  'comments': [
    {'id': 11, 'username': 'listener', 'body': 'Existing comment'},
  ],
};

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    StorySeen.resetForTesting();
  });
  testWidgets(
    'inline comments load on demand, like and reply without reloading the feed',
    (tester) async {
      final requests = <http.Request>[];
      final api = SocialApi(
        'token',
        client: MockClient((r) async {
          requests.add(r);
          if (r.url.path.endsWith('/like'))
            return response({'liked': true, 'likes': 1});
          if (r.method == 'POST')
            return response({
              'id': 12,
              'body': r.bodyFields['body'],
              'parent_id': 11,
              'parent_body': 'Existing comment',
              'likes': 0,
              'liked': false,
              'author': {'username': 'me'},
            });
          return response([
            {
              'id': 11,
              'body': 'Existing comment',
              'likes': 0,
              'liked': false,
              'author': {'username': 'listener'},
            },
          ]);
        }),
      );
      await tester.pumpWidget(
        fixture.host(
          Scaffold(
            body: SingleChildScrollView(
              child: PostCard(api: api, post: post(1)),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(requests, isEmpty);
      expect(find.text('hidden@example.test'), findsNothing);
      expect(find.textContaining('Existing comment'), findsOneWidget);
      await tester.tap(find.byTooltip('نظرات'));
      await tester.pumpAndSettle();
      expect(requests.length, 1);
      await tester.ensureVisible(find.byTooltip('پسندیدن نظر'));
      await tester.tap(find.byTooltip('پسندیدن نظر'));
      await tester.pumpAndSettle();
      expect(requests.last.url.path, endsWith('/comments/11/like'));
      expect(requests.last.bodyFields['active'], '1');
      await tester.tap(find.text('پاسخ'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'My reply');
      await tester.ensureVisible(find.byTooltip('ارسال نظر'));
      await tester.tap(find.byTooltip('ارسال نظر'));
      await tester.pumpAndSettle();
      expect(requests.last.bodyFields['parent_id'], '11');
      expect(find.text('My reply'), findsOneWidget);
      expect(requests.where((r) => r.method == 'GET').length, 1);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      api.dispose();
    },
  );
  testWidgets(
    'share sends only selected members and requires an explicit send',
    (tester) async {
      final sent = <http.Request>[];
      final api = SocialApi(
        'token',
        client: MockClient((r) async {
          if (r.method == 'POST') {
            sent.add(r);
            return response({
              'sent': [2],
            });
          }
          return response([
            {'id': 1, 'username': 'myself', 'isMe': true},
            {'id': 2, 'username': 'recipient'},
          ]);
        }),
      );
      await tester.pumpWidget(
        fixture.host(
          Scaffold(
            body: SingleChildScrollView(
              child: PostCard(api: api, post: post(1)),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('ارسال پست'));
      await tester.pumpAndSettle();
      expect(find.text('myself'), findsNothing);
      await tester.tap(find.text('recipient'));
      await tester.pumpAndSettle();
      expect(sent, isEmpty);
      await tester.tap(find.widgetWithText(FilledButton, 'ارسال (1/10)'));
      await tester.pumpAndSettle();
      expect(sent.single.url.path, endsWith('/posts/1/share'));
      expect(sent.single.bodyFields, {'user_ids[0]': '2'});
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      api.dispose();
    },
  );
  testWidgets(
    'story rings share view state, persist locally and hide empty own ring',
    (tester) async {
      final api = SocialApi('');
      final user = <String, dynamic>{
        'id': 90,
        'stories': [
          {'id': 50501, 'media': null, 'mime': 'image/jpeg'},
        ],
      };
      await tester.pumpWidget(
        fixture.host(
          Scaffold(
            body: Column(
              children: [
                SocialAvatar(key: const ValueKey('one'), api: api, user: user),
                SocialAvatar(key: const ValueKey('two'), api: api, user: user),
                SocialAvatar(
                  key: const ValueKey('empty'),
                  api: api,
                  user: const {'id': 91},
                  showEmptyRing: false,
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      Border? border(String key) => tester
          .widgetList<Container>(
            find.descendant(
              of: find.byKey(ValueKey(key)),
              matching: find.byType(Container),
            ),
          )
          .map((w) => w.decoration)
          .whereType<BoxDecoration>()
          .map((d) => d.border)
          .whereType<Border>()
          .firstOrNull;
      expect(border('one')!.top.color, const Color(0xffcc338c));
      expect(border('empty'), isNull);
      await tester.runAsync(() => StorySeen.forAccount(0).mark(50501));
      await tester.pumpAndSettle();
      expect(border('one')!.top.color, Colors.grey);
      expect(border('two')!.top.color, Colors.grey);
      final persisted = await tester.runAsync(
        () async => (await SharedPreferences.getInstance()).getStringList(
          'seen-stories-v1-0',
        ),
      );
      expect(persisted, contains('50501'));
      expect(StorySeen.forAccount(7).ids, isNot(contains('50501')));
      await tester.pumpWidget(const SizedBox());
      api.dispose();
    },
  );
  testWidgets(
    'profile stream starts at selected post and can reveal earlier and later posts',
    (tester) async {
      final api = SocialApi(
        'token',
        client: MockClient((_) async => response([])),
      );
      await tester.pumpWidget(
        fixture.host(
          ProfilePostsPage(
            api: api,
            posts: [for (var i = 0; i < 6; i++) post(i)],
            selected: 3,
            onChanged: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      final view = find.byKey(const ValueKey('profile-post-stream'));
      final selected = tester
          .getTopLeft(
            find.byWidgetPredicate((w) => w is PostCard && w.post['id'] == 3),
          )
          .dy;
      expect(selected, closeTo(56, 1));
      await tester.drag(view, const Offset(0, 300));
      await tester.pumpAndSettle();
      expect(find.text('Post body 2').hitTestable(), findsOneWidget);
      await tester.drag(view, const Offset(0, -650));
      await tester.pumpAndSettle();
      expect(find.text('Post body 4'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      api.dispose();
    },
  );
  testWidgets('follower search is in the toolbar and keeps follower scope', (
    tester,
  ) async {
    final queries = <Uri>[];
    final api = SocialApi(
      'token',
      client: MockClient((r) async {
        queries.add(r.url);
        return response([
          {'id': 2, 'username': 'person'},
        ]);
      }),
    );
    await tester.pumpWidget(
      fixture.host(PeoplePage(api: api, userId: 9, kind: 'followers')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('open-home-search')));
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.byType(TextField),
      ),
      findsOneWidget,
    );
    expect(find.byType(Card), findsNothing);
    await tester.enterText(find.byType(TextField), 'piano');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(queries.last.path, endsWith('/users/9/followers'));
    expect(queries.last.queryParameters['q'], 'piano');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    api.dispose();
  });
}
