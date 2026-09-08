import 'package:sornaz/helpers/app_translations.dart';
import 'package:sornaz/components/app_text.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sornaz/screens/Authentication/providers/auth_session.dart';
import 'package:sornaz/screens/Authentication/ui/pages/authentication.dart';
import 'social_api.dart';
import 'social_widgets.dart';
import 'social_profile.dart';
import 'social_activity.dart';
import 'social_publish.dart';
import 'social_courses.dart';
import 'social_learning.dart';
import 'package:sornaz/components/bottom_nav.dart';

class UserPanelPage extends StatelessWidget {
  const UserPanelPage({super.key, this.initialTab = 2});
  final int initialTab;
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthSession>();
    if (!auth.isAuthenticated)
      return SocialScaffold(
        title: socialText(context, 'پنل کاربری', 'Your space'),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.account_circle_outlined, size: 72),
              const SizedBox(height: 16),
              AppText(
                socialText(
                  context,
                  'به جمع اهالی موسیقی بپیوندید',
                  'Join the music community',
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => socialPush(context, const SignInScreen()),
                child: AppText(
                  socialText(context, 'ورود یا ثبت‌نام', 'Sign in or register'),
                ),
              ),
            ],
          ),
        ),
      );
    return _Panel(
      key: ValueKey(auth.token),
      token: auth.token!,
      userId: auth.user!.id,
      initialTab: initialTab,
    );
  }
}

class _Panel extends StatefulWidget {
  const _Panel({
    super.key,
    required this.token,
    required this.userId,
    required this.initialTab,
  });
  final int initialTab;
  final String token;
  final int userId;
  @override
  State<_Panel> createState() => _PanelState();
}

class _PanelState extends State<_Panel> {
  late final SocialApi api = SocialApi(widget.token);
  List<Json> posts = [], stories = [];
  late int tab = widget.initialTab;
  int unread = 0;
  bool loading = true, more = true, fetchingMore = false;
  String? error;
  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void dispose() {
    api.dispose();
    super.dispose();
  }

  Future<void> load() async {
    try {
      final data = await Future.wait([
        api.get('/posts'),
        api.get('/posts?kind=story'),
        api.get('/notifications'),
      ]);
      if (!mounted) return;
      setState(() {
        posts = objects(data[0]);
        stories = objects(data[1]);
        unread = objects(data[2]).where((n) => n['read_at'] == null).length;
        loading = false;
        error = null;
        more = posts.length == 30;
      });
    } catch (e) {
      if (mounted)
        setState(() {
          error = e.toString();
          loading = false;
        });
    }
  }

  Future<void> loadMore() async {
    if (fetchingMore || !more || posts.isEmpty) return;
    setState(() => fetchingMore = true);
    try {
      final data = objects(await api.get('/posts?before=${posts.last['id']}'));
      if (mounted)
        setState(() {
          posts.addAll(data);
          more = data.length == 30;
        });
    } catch (e) {
      if (mounted) socialError(context, e);
    } finally {
      if (mounted) setState(() => fetchingMore = false);
    }
  }

  Future<void> create() async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final item in [
              ('post', Icons.grid_on_outlined, 'پست جدید'),
              ('story', Icons.add_circle_outline, 'استوری جدید'),
              ('course', Icons.school_outlined, 'دوره جدید'),
            ])
              ListTile(
                leading: Icon(item.$2),
                title: AppText(item.$3),
                onTap: () => Navigator.pop(context, item.$1),
              ),
          ],
        ),
      ),
    );
    if (!mounted || choice == null) return;
    await socialPush(
      context,
      choice == 'course'
          ? CourseEditorPage(api: api)
          : PublishPage(api: api, kind: choice),
    );
    if (mounted) {
      setState(() => tab = 0);
      await load();
    }
  }

  @override
  Widget build(BuildContext context) => SocialScaffold(
    title: socialText(context, 'دنیای موسیقی من', 'My music space'),
    actions: [
      IconButton(
        tooltip: 'پست‌ها و استوری‌ها'.translate(context),
        onPressed: () => setState(() => tab = tab == 0 ? 2 : 0),
        icon: Icon(
          tab == 0 ? Icons.person_outline : Icons.dynamic_feed_outlined,
        ),
      ),
      IconButton(
        tooltip: 'جست‌وجوی کاربران'.translate(context),
        onPressed: () => socialPush(context, PeoplePage(api: api)),
        icon: const Icon(Icons.search),
      ),
      IconButton(
        tooltip: 'اعلان‌ها'.translate(context),
        onPressed: () async {
          await socialPush(context, NotificationsPage(api: api));
          if (mounted) load();
        },
        icon: Badge(
          isLabelVisible: unread > 0,
          label: AppText('$unread'),
          child: const Icon(Icons.notifications_none),
        ),
      ),
      IconButton(
        tooltip: 'دایرکت'.translate(context),
        onPressed: () => socialPush(context, DirectPage(api: api)),
        icon: const Icon(Icons.chat_bubble_outline),
      ),
    ],
    body: switch (tab) {
      1 => CoursesBody(api: api),
      2 => AccountDashboardBody(api: api, key: ValueKey('profile-$tab')),
      _ =>
        loading
            ? const Center(child: CircularProgressIndicator())
            : error != null
            ? SocialEmpty(error!, onRetry: load)
            : RefreshIndicator(
                onRefresh: load,
                child: ListView(
                  children: [
                    SizedBox(
                      height: 112,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        children: [
                          InkWell(
                            onTap: () async {
                              await socialPush(
                                context,
                                PublishPage(api: api, kind: 'story'),
                              );
                              if (mounted) load();
                            },
                            child: const SizedBox(
                              width: 82,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CircleAvatar(
                                    radius: 30,
                                    child: Icon(Icons.add),
                                  ),
                                  SizedBox(height: 8),
                                  AppText(
                                    'استوری من',
                                    style: TextStyle(fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          for (var i = 0; i < stories.length; i++)
                            InkWell(
                              onTap: () => socialPush(
                                context,
                                StoryPage(
                                  api: api,
                                  stories: stories,
                                  initialIndex: i,
                                ),
                              ),
                              child: SizedBox(
                                width: 82,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SocialAvatar(
                                      api: api,
                                      user: object(stories[i]['author']),
                                      story: true,
                                      size: 52,
                                    ),
                                    const SizedBox(height: 6),
                                    AppText(
                                      '${stories[i]['author']['name']}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (posts.isEmpty)
                      const SocialEmpty(
                        'هنوز پستی منتشر نشده؛ اولین اجرای خود را به اشتراک بگذارید.',
                      ),
                    for (final p in posts)
                      PostCard(
                        key: ValueKey(p['id']),
                        api: api,
                        post: p,
                        onChanged: load,
                      ),
                    if (more)
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: TextButton(
                          onPressed: fetchingMore ? null : loadMore,
                          child: AppText(
                            fetchingMore ? 'در حال دریافت…' : 'نمایش بیشتر',
                          ),
                        ),
                      ),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
    },
    floatingActionButton: FloatingActionButton(
      onPressed: create,
      tooltip: 'ساخت محتوا'.translate(context),
      child: const Icon(Icons.add),
    ),
    bottom: tab == 2
        ? const BottomNavBarWidget(selectedIndex: 4)
        : NavigationBar(
            selectedIndex: tab,
            onDestinationSelected: (value) => setState(() => tab = value),
            destinations: [
              NavigationDestination(
                icon: const Icon(Icons.dynamic_feed_outlined),
                label: socialText(context, 'پست‌ها', 'Feed'),
              ),
              NavigationDestination(
                icon: const Icon(Icons.school_outlined),
                label: socialText(context, 'دوره‌ها', 'Courses'),
              ),
              NavigationDestination(
                icon: const Icon(Icons.person_outline),
                label: socialText(context, 'پروفایل', 'Profile'),
              ),
            ],
          ),
  );
}

class PostCard extends StatefulWidget {
  const PostCard({
    super.key,
    required this.api,
    required this.post,
    this.onChanged,
  });
  final SocialApi api;
  final Json post;
  final VoidCallback? onChanged;
  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  late Json post = widget.post;
  bool busy = false;
  @override
  void didUpdateWidget(PostCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    post = widget.post;
  }

  Future<void> react(String kind) async {
    if (busy) return;
    setState(() => busy = true);
    try {
      final data = object(
        await widget.api.post('/posts/${post['id']}/react', {
          'kind': kind,
          'active': post[kind == 'like' ? 'liked' : 'saved'] == true
              ? '0'
              : '1',
        }),
      );
      if (mounted) setState(() => post = data);
    } catch (e) {
      if (mounted) socialError(context, e);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final author = object(post['author']);
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: SocialAvatar(api: widget.api, user: author, size: 36),
            title: AppText(
              '${author['name']}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: AppText('@${author['username']}'),
            onTap: () => socialPush(
              context,
              ProfilePage(api: widget.api, userId: number(author['id'])),
            ),
            trailing: author['isMe'] == true
                ? IconButton(
                    tooltip: 'حذف پست'.translate(context),
                    icon: const Icon(Icons.delete_outline),
                    onPressed: busy
                        ? null
                        : () async {
                            final yes = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const AppText('این پست حذف شود؟'),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: const AppText('انصراف'),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    child: const AppText('حذف'),
                                  ),
                                ],
                              ),
                            );
                            if (yes != true) return;
                            try {
                              await widget.api.post(
                                '/posts/${post['id']}/delete',
                              );
                              widget.onChanged?.call();
                            } catch (e) {
                              if (context.mounted) socialError(context, e);
                            }
                          },
                  )
                : null,
          ),
          if (post['media'] != null)
            if ('${post['mime']}'.startsWith('video/'))
              SocialVideo(api: widget.api, path: post['media'])
            else
              SocialImage(
                api: widget.api,
                path: post['media'],
                width: double.infinity,
                height: 300,
              ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                IconButton(
                  onPressed: busy ? null : () => react('like'),
                  tooltip: 'پسندیدن'.translate(context),
                  icon: Icon(
                    post['liked'] == true
                        ? Icons.favorite
                        : Icons.favorite_border,
                    color: post['liked'] == true
                        ? const Color(0xffcc338c)
                        : null,
                  ),
                ),
                AppText('${post['likes']}'),
                const Spacer(),
                IconButton(
                  onPressed: busy ? null : () => react('save'),
                  tooltip: 'ذخیره'.translate(context),
                  icon: Icon(
                    post['saved'] == true
                        ? Icons.bookmark
                        : Icons.bookmark_border,
                  ),
                ),
              ],
            ),
          ),
          if ('${post['body']}'.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: AppText('${post['body']}'),
            ),
          const SizedBox(height: 12),
          const Divider(height: 1),
        ],
      ),
    );
  }
}
