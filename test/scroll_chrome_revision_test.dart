import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sornaz/components/scroll_aware_scaffold.dart';
import 'package:sornaz/components/home_top_bar.dart';
import 'package:sornaz/screens/Articles/ui/components/article_progress.dart';
import 'package:sornaz/screens/Articles/ui/pages/article_detail_page.dart';
import 'package:sornaz/screens/Articles/provider/articles_provider.dart';
import 'package:sornaz/screens/Articles/cache/hive_articles_cache.dart';
import 'package:sornaz/screens/Articles/services/article_api_service.dart';
import 'package:sornaz/helpers/app_data.dart';

class MemoryArticles extends HiveArticlesCache {
  @override
  Future<List<String>> receipts(int id) async => [];
}

class ArticleLibrary extends ArticlesProvider {
  ArticleLibrary(this.post)
    : super(
        autoStart: false,
        cache: MemoryArticles(),
        api: ArticleApiService(
          client: MockClient(
            (r) async => http.Response(
              r.url.path.endsWith('/comments') ? '[]' : '{}',
              200,
            ),
          ),
        ),
      );
  final Map<String, dynamic> post;
  @override
  Future<Map<String, dynamic>> resolve(int id) async => post;
}

void main() {
  testWidgets('short content cannot hide header, growing content can', (
    tester,
  ) async {
    final count = ValueNotifier(1);
    await tester.pumpWidget(
      MaterialApp(
        home: ScrollAwareScaffold(
          appBar: AppBar(title: const Text('Header')),
          body: ValueListenableBuilder<int>(
            valueListenable: count,
            builder: (c, n, _) => ListView(
              children: List.generate(n, (i) => const SizedBox(height: 80)),
            ),
          ),
        ),
      ),
    );
    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pumpAndSettle();
    expect(
      tester
          .state<NestedScrollViewState>(find.byType(NestedScrollView))
          .outerController
          .offset,
      0,
    );
    count.value = 30;
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pumpAndSettle();
    expect(
      tester
          .state<NestedScrollViewState>(find.byType(NestedScrollView))
          .outerController
          .offset,
      56,
    );
    await tester.pumpWidget(const SizedBox());
    count.dispose();
  });
  for (final lang in ['fa', 'en']) {
    testWidgets('people toolbar aligns back and title in ' + lang, (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: Locale(lang),
          supportedLocales: const [Locale('fa'), Locale('en')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: Scaffold(
            appBar: HomeTopBar(
              searchOnly: true,
              pageTitle: 'People',
              onSearch: (_) {},
            ),
          ),
        ),
      );
      final back = tester.getCenter(find.byType(BackButton));
      final title = tester.getCenter(find.text('People'));
      expect(lang == 'fa' ? back.dx > title.dx : back.dx < title.dx, isTrue);
      final icon = tester.getRect(find.byIcon(Icons.search));
      expect(lang == 'fa' ? icon.left : 800 - icon.right, closeTo(24, 0.1));
      await tester.tap(find.byKey(const ValueKey('open-home-search')));
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsOneWidget);
    });
  }

  testWidgets(
    'toolbar is a scrolling header and bottom navigation stays fixed',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ScrollAwareScaffold(
            appBar: AppBar(title: const Text('Toolbar')),
            bottomNavigationBar: const SizedBox(
              key: ValueKey('bottom'),
              height: 50,
            ),
            body: ListView(
              children: List.generate(
                60,
                (i) => SizedBox(height: 60, child: Text('Row ' + i.toString())),
              ),
            ),
          ),
        ),
      );
      final bottom = tester.getTopLeft(find.byKey(const ValueKey('bottom')));
      final initial = tester.getTopLeft(find.byType(AppBar)).dy;
      expect(tester.widget<Scaffold>(find.byType(Scaffold)).appBar, isNull);
      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(ListView)),
      );
      await gesture.moveBy(const Offset(0, -25));
      await tester.pump();
      await gesture.moveBy(const Offset(0, -12));
      await tester.pump();
      final partial = tester.getTopLeft(find.byType(AppBar)).dy;
      expect(partial, lessThan(initial));
      expect(partial, greaterThan(initial - 56));
      await gesture.moveBy(const Offset(0, -300));
      await gesture.up();
      await tester.pumpAndSettle();
      expect(
        tester
            .state<NestedScrollViewState>(find.byType(NestedScrollView))
            .outerController
            .offset,
        56,
      );
      expect(tester.getTopLeft(find.byKey(const ValueKey('bottom'))), bottom);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('pinned article chrome never scrolls away', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ScrollAwareScaffold(
          pinTopBar: true,
          appBar: AppBar(title: const Text('Progress')),
          body: ListView(
            children: List.generate(30, (i) => const SizedBox(height: 100)),
          ),
        ),
      ),
    );
    final top = tester.getTopLeft(find.byType(AppBar));
    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.byType(AppBar)), top);
    expect(find.byType(NestedScrollView), findsNothing);
  });
  for (final locale in ['fa', 'en']) {
    testWidgets('search-only chrome and reading progress direction ' + locale, (
      tester,
    ) async {
      final progress = ValueNotifier<double>(0.25);
      await tester.pumpWidget(
        MaterialApp(
          locale: Locale(locale),
          supportedLocales: const [Locale('fa'), Locale('en')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: Scaffold(
            appBar: HomeTopBar(
              searchOnly: true,
              onSearch: (_) {},
              flexibleSpace: ArticleProgressBackground(
                progress: progress,
                isDark: false,
              ),
            ),
          ),
        ),
      );
      expect(find.byIcon(Icons.menu), findsNothing);
      final aligns = tester.widgetList<Align>(
        find.descendant(
          of: find.byType(ArticleProgressBackground),
          matching: find.byType(Align),
        ),
      );
      expect(
        aligns.single.alignment,
        locale == 'fa' ? Alignment.centerRight : Alignment.centerLeft,
      );
      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      progress.dispose();
    });
  }
  testWidgets(
    'long article progress follows real scroll extent before rating and comments',
    (tester) async {
      final post = <String, dynamic>{
        'id': 8,
        'locale': 'en',
        'title': {'rendered': 'Long article'},
        'content': {
          'rendered': List.generate(
            80,
            (i) =>
                '<p>A complete paragraph of music education content with several words for layout.</p>',
          ).join(),
        },
        'categories': <int>[],
      };
      final library = ArticleLibrary(post);
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AppData()),
            ChangeNotifierProvider<ArticlesProvider>.value(value: library),
          ],
          child: MaterialApp(home: ArticleDetailPage(post: post)),
        ),
      );
      await tester.pumpAndSettle();
      final scroll = tester
          .widget<CustomScrollView>(find.byType(CustomScrollView))
          .controller!;
      final initialMax = scroll.position.maxScrollExtent;
      expect(initialMax, greaterThan(3000));
      final progress = tester
          .widget<ArticleProgressBackground>(
            find.byType(ArticleProgressBackground),
          )
          .progress;
      for (final fraction in [0.2, 0.5, 0.8, 1.0]) {
        scroll.jumpTo(initialMax * fraction);
        await tester.pumpAndSettle();
        expect(scroll.position.maxScrollExtent, closeTo(initialMax, 2));
        expect(progress.value, closeTo(fraction, 0.015));
      }
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      library.dispose();
    },
  );
}
