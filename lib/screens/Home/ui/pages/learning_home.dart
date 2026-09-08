import 'package:sornaz/components/app_text.dart';
import 'package:sornaz/screens/Social/course_browse.dart';
import 'package:sornaz/components/app_logo.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sornaz/components/bottom_nav.dart';
import 'package:sornaz/helpers/app_data.dart';
import 'package:sornaz/screens/Authentication/providers/auth_session.dart';
import 'package:sornaz/screens/Articles/provider/articles_provider.dart';
import 'package:sornaz/screens/Articles/ui/pages/article_detail_page.dart';
import 'package:sornaz/screens/Articles/ui/pages/articles_page.dart';
import 'package:sornaz/screens/Home/ui/components/app_drawer.dart';
import 'package:sornaz/screens/Social/social_api.dart';
import 'package:sornaz/screens/Social/social_widgets.dart';
import 'package:sornaz/screens/Social/social_courses.dart';
import 'package:sornaz/screens/Social/social_profile.dart';
import 'package:sornaz/screens/Social/learning_widgets.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key, this.api, this.articleLoader});
  final SocialApi? api;
  final Future<List<dynamic>> Function()? articleLoader;
  @override
  Widget build(BuildContext context) {
    final token = context.watch<AuthSession?>()?.token ?? '';
    return HomeContent(
      key: ValueKey(token),
      api: api,
      token: token,
      articleLoader: articleLoader,
    );
  }
}

class HomeContent extends StatefulWidget {
  const HomeContent({
    super.key,
    this.api,
    required this.token,
    this.articleLoader,
  });
  final SocialApi? api;
  final String token;
  final Future<List<dynamic>> Function()? articleLoader;
  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  late final api = widget.api ?? SocialApi(widget.token);
  List<Json> courses = [], authors = [], articles = [];
  bool loading = true;
  String? error, articleError;
  final search = TextEditingController();
  String query = '', filter = 'all';
  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void dispose() {
    search.dispose();
    if (widget.api == null) api.dispose();
    super.dispose();
  }

  Future<void> load() async {
    await Future.wait([
      loadCourses(),
      loadArticles(),
      if (widget.articleLoader == null &&
          context.read<ArticlesProvider?>() != null)
        context.read<ArticlesProvider>().synchronize(),
    ]);
    if (mounted) setState(() => loading = false);
  }

  Future<void> loadCourses() async {
    try {
      final d = object(await api.get('/home'));
      if (mounted)
        setState(() {
          courses = objects(d['courses']);
          authors = objects(d['authors']);
          error = null;
        });
    } catch (e) {
      if (mounted) setState(() => error = '$e');
    }
  }

  Future<void> loadArticles() async {
    try {
      final rows =
          await (widget.articleLoader?.call() ??
              Future.value(
                context.read<ArticlesProvider?>()?.allPosts ?? <Json>[],
              ));
      if (mounted)
        setState(() {
          articles = objects(rows);
          articleError = null;
        });
    } catch (e) {
      if (mounted) setState(() => articleError = '$e');
    }
  }

  String title(Json p) => p['title'] is Map
      ? '${p['title']['rendered'] ?? ''}'.replaceAll(RegExp('<[^>]*>'), '')
      : '${p['title'] ?? ''}';
  String? articleImage(Json p) {
    final embedded = p['_embedded'];
    if (embedded is Map &&
        embedded['wp:featuredmedia'] is List &&
        (embedded['wp:featuredmedia'] as List).isNotEmpty)
      return embedded['wp:featuredmedia'][0]['source_url'] as String?;
    return null;
  }

  Future<void> filters() async {
    final next = await showModalBottomSheet<String>(
      context: context,
      builder: (c) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final f in [
              ('all', 'همه دوره‌ها', 'All courses'),
              ('free', 'دوره‌های رایگان', 'Free courses'),
              ('paid', 'دوره‌های غیررایگان', 'Paid courses'),
            ])
              ListTile(
                title: AppText(socialText(c, f.$2, f.$3)),
                trailing: filter == f.$1 ? const Icon(Icons.check) : null,
                onTap: () => Navigator.pop(c, f.$1),
              ),
          ],
        ),
      ),
    );
    if (next != null && mounted) setState(() => filter = next);
  }

  void openCourse(Json c) =>
      socialPush(context, CourseDetailPage(api: api, id: number(c['id'])));
  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppData>();
    final dark = app.isDark;
    final accent = dark ? const Color(0xffd3ae32) : const Color(0xff0064fb);
    final theme = ThemeData(
      useMaterial3: true,
      brightness: dark ? Brightness.dark : Brightness.light,
      fontFamily: app.fontFamily,
      scaffoldBackgroundColor: dark ? Colors.black : Colors.white,
      colorScheme:
          ColorScheme.fromSeed(
            seedColor: accent,
            brightness: dark ? Brightness.dark : Brightness.light,
          ).copyWith(
            primary: accent,
            surface: dark ? const Color(0xff202020) : const Color(0xfff1f1f1),
          ),
    );
    final filtered = courses
        .where(
          (c) =>
              '${c['title']} ${c['description']}'.toLowerCase().contains(
                query.toLowerCase(),
              ) &&
              (filter == 'all' ||
                  (filter == 'free'
                      ? number(c['price']) == 0
                      : number(c['price']) > 0)),
        )
        .toList();
    final sorted = [...filtered]
      ..sort((a, b) => '${b['updated_at']}'.compareTo('${a['updated_at']}'));
    final updated = sorted.take(10).toList();
    final library = context.watch<ArticlesProvider?>();
    final articleRows =
        (widget.articleLoader == null && library != null
                ? library.allPosts
                : articles)
            .where((p) => title(p).toLowerCase().contains(query.toLowerCase()))
            .toList()
          ..sort((a, b) => '${b["date"]}'.compareTo('${a["date"]}'));
    final blogs = articleRows.take(10).toList();
    final people = authors
        .where(
          (a) => '${a['name']}'.toLowerCase().contains(query.toLowerCase()),
        )
        .take(10)
        .toList();
    return Theme(
      data: theme,
      child: Builder(
        builder: (context) => Scaffold(
          appBar: AppBar(
            backgroundColor: theme.scaffoldBackgroundColor,
            automaticallyImplyLeading: false,
            title: Align(
              alignment: AlignmentDirectional.centerStart,
              child: AppLogo(size: 40, withBackground: false),
            ),
            actions: [
              Builder(
                builder: (c) => IconButton(
                  tooltip: socialText(c, 'منو', 'Menu'),
                  onPressed: () => Scaffold.of(c).openDrawer(),
                  icon: const Icon(Icons.menu),
                ),
              ),
              const SizedBox(width: 12),
            ],
          ),
          drawer: const AppDrawer(),
          bottomNavigationBar: const BottomNavBarWidget(selectedIndex: 0),
          body: RefreshIndicator(
            onRefresh: load,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(0, 8, 0, 24),
              children:
                  [
                        TextField(
                          key: const ValueKey('home-search'),
                          controller: search,
                          onChanged: (v) => setState(() => query = v.trim()),
                          decoration: InputDecoration(
                            hintText: socialText(
                              context,
                              'جست‌وجوی دوره، موضوع، مدرس…',
                              'Search course, topic, mentor…',
                            ),
                            hintStyle: const TextStyle(fontSize: 12),
                            prefixIcon: const Icon(Icons.search, size: 22),
                            suffixIcon: IconButton(
                              tooltip: socialText(
                                context,
                                'فیلتر دوره‌ها',
                                'Course filters',
                              ),
                              onPressed: filters,
                              icon: Icon(
                                Icons.tune,
                                size: 20,
                                color: filter == 'all' ? null : accent,
                              ),
                            ),
                            filled: true,
                            fillColor: theme.colorScheme.surface,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        if (loading)
                          const Padding(
                            padding: EdgeInsets.only(top: 12),
                            child: LinearProgressIndicator(),
                          ),
                        LearningHeading(
                          socialText(context, 'تازه‌های وبلاگ', 'New blog'),
                          onMore: () =>
                              socialPush(context, const ArticlesPage()),
                        ),
                        if (articleError != null)
                          SocialEmpty(
                            socialText(
                              context,
                              'مقاله‌ها دریافت نشدند.',
                              'Could not load articles.',
                            ),
                            onRetry: loadArticles,
                          )
                        else if (blogs.isEmpty && !loading)
                          AppText(
                            socialText(
                              context,
                              'مقاله‌ای پیدا نشد.',
                              'No articles found.',
                            ),
                          )
                        else
                          SizedBox(
                            height: 186,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                              ),
                              itemCount: blogs.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(width: 14),
                              itemBuilder: (context, i) {
                                final p = blogs[i];
                                final image = articleImage(p);
                                return SizedBox(
                                  width: 166,
                                  child: Card(
                                    elevation: 0,
                                    margin: EdgeInsets.zero,
                                    clipBehavior: Clip.antiAlias,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4),
                                      side: BorderSide(
                                        color: theme.dividerColor,
                                      ),
                                    ),
                                    child: InkWell(
                                      onTap: () => socialPush(
                                        context,
                                        ArticleDetailPage(post: p),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          if (image != null)
                                            Image.network(
                                              image,
                                              width: 166,
                                              height: 100,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) =>
                                                  const SizedBox(
                                                    height: 100,
                                                    child: Center(
                                                      child: Icon(
                                                        Icons.article_outlined,
                                                      ),
                                                    ),
                                                  ),
                                            )
                                          else
                                            const SizedBox(
                                              height: 100,
                                              child: Center(
                                                child: Icon(
                                                  Icons.article_outlined,
                                                ),
                                              ),
                                            ),
                                          Padding(
                                            padding: const EdgeInsets.all(8),
                                            child: AppText(
                                              title(p),
                                              maxLines: 3,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        LearningHeading(
                          socialText(context, 'دوره‌های جدید', 'New courses'),
                        ),
                        if (error != null)
                          SocialEmpty(
                            socialText(
                              context,
                              'دوره‌ها دریافت نشدند.',
                              'Could not load courses.',
                            ),
                            onRetry: loadCourses,
                          )
                        else if (filtered.isEmpty && !loading)
                          AppText(
                            socialText(
                              context,
                              'دوره‌ای با این مشخصات پیدا نشد.',
                              'No matching courses.',
                            ),
                          )
                        else if (filtered.isNotEmpty)
                          SizedBox(
                            height: 370,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                              ),
                              itemCount: updated.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(width: 16),
                              itemBuilder: (context, i) => SizedBox(
                                width: 270,
                                child: CourseCard(
                                  api: api,
                                  course: updated[i],
                                  onTap: () => openCourse(updated[i]),
                                ),
                              ),
                            ),
                          ),
                        LearningHeading(
                          socialText(
                            context,
                            'دوره‌های به‌روزشده',
                            'Updated courses',
                          ),
                          onMore: () =>
                              socialPush(context, CoursesPage(api: api)),
                        ),
                        if (updated.isNotEmpty)
                          SizedBox(
                            height: 274,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                              ),
                              itemCount: updated.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(width: 16),
                              itemBuilder: (context, i) {
                                final c = updated[i];
                                return SizedBox(
                                  width: 270,
                                  child: Card(
                                    margin: EdgeInsets.zero,
                                    clipBehavior: Clip.antiAlias,
                                    child: InkWell(
                                      onTap: () => openCourse(c),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          SocialImage(
                                            api: api,
                                            path: c['cover_id'] == null
                                                ? null
                                                : api.courseMedia(
                                                    c['cover_id'],
                                                  ),
                                            height: 150,
                                            width: 270,
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.all(12),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                AppText(
                                                  '${c['title']}',
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                AppText(
                                                  '${(c['author'] as Map?)?['name'] ?? ''}',
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                  ),
                                                ),
                                                AppText(
                                                  '${number(c['lesson_count'])} ${socialText(context, 'درس', 'lessons')}',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: theme.hintColor,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        LearningHeading(
                          socialText(
                            context,
                            'برای شروع یادگیری',
                            'Start learning',
                          ),
                        ),
                        for (final c in filtered.take(3))
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: dark
                                    ? const Color(0xff003c1b)
                                    : const Color(0xff609e79),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.music_note_outlined,
                                color: Colors.white,
                              ),
                            ),
                            title: AppText(
                              '${c['title']}',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: AppText(
                              '${number(c['lesson_count'])} ${socialText(context, 'درس', 'lessons')}',
                            ),
                            onTap: () => openCourse(c),
                          ),
                        LearningHeading(
                          socialText(
                            context,
                            'مدرسان و نویسندگان',
                            'Instructors & authors',
                          ),
                        ),
                        SizedBox(
                          height: 108,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            itemCount: people.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 18),
                            itemBuilder: (context, i) {
                              final a = people[i];
                              return InkWell(
                                onTap: () => socialPush(
                                  context,
                                  ProfilePage(
                                    api: api,
                                    userId: number(a['id']),
                                  ),
                                ),
                                child: SizedBox(
                                  width: 62,
                                  child: Column(
                                    children: [
                                      SocialAvatar(api: api, user: a, size: 48),
                                      const SizedBox(height: 6),
                                      AppText(
                                        '${a['name']}',
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ]
                      .map(
                        (child) => child is SizedBox
                            ? child
                            : Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                ),
                                child: child,
                              ),
                      )
                      .toList(),
            ),
          ),
        ),
      ),
    );
  }
}
