import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sornaz/components/home_top_bar.dart';
import 'package:sornaz/screens/Articles/provider/articles_provider.dart';
import 'package:sornaz/screens/Articles/ui/components/article_progress.dart';
import 'package:sornaz/screens/Articles/ui/pages/articles_page.dart';
import 'package:sornaz/screens/Authentication/providers/auth_session.dart';
import 'package:sornaz/screens/Home/ui/pages/home.dart';
import 'package:sornaz/helpers/app_data.dart';
import 'drawer_accounts_test.dart' as fixture;

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  for (final id in <int?>[null, 2, 1]) {
    testWidgets('home uses searchable articles and home chrome for $id', (
      tester,
    ) async {
      final articles = ArticlesProvider(autoStart: false);
      articles.allPosts = List.generate(
        30,
        (i) => {
          'id': i,
          'title': {'rendered': i == 0 ? 'Piano lesson' : 'Guitar lesson $i'},
          'excerpt': {'rendered': 'Music article'},
        },
      );
      final session = AuthSession();
      if (id != null) {
        session.user = fixture.account(id).user;
        session.token = 'test-$id';
      }
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: articles,
          child: fixture.host(const HomePage(), AppData(), session),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('article-list')), findsOneWidget);
      expect(find.text('خانه'), findsOneWidget);
      expect(find.byType(BackButton), findsNothing);
      expect(
        tester.widget<HomeTopBar>(find.byType(HomeTopBar)).searchOnly,
        false,
      );
      expect(find.byType(Scrollbar), findsWidgets);
      await tester.drag(
        find.byKey(const Key('article-list')),
        const Offset(0, -650),
      );
      await tester.pumpAndSettle();
      final progress = tester.widget<ArticleProgressBackground>(
        find.byType(ArticleProgressBackground),
      );
      expect(progress.progress.value, greaterThan(0));
      // Opening the full list must not attach two viewports to one controller.
      final context = tester.element(find.byType(ArticlesPage));
      Navigator.of(
        context,
      ).push(MaterialPageRoute<void>(builder: (_) => const ArticlesPage()));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      Navigator.of(tester.element(find.byType(ArticlesPage).last)).pop();
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('open-home-search')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('home-search')),
        'Piano',
      );
      await tester.pumpAndSettle();
      expect(articles.searchQuery, 'Piano');
      expect(progress.progress.value, 0);
      expect(find.text('Piano lesson'), findsOneWidget);
      expect(find.text('Guitar lesson 1'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      articles.dispose();
      session.dispose();
    });
  }
}
