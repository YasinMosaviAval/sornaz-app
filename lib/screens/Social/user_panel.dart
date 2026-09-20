import 'post_comments.dart';
import 'create_content_button.dart';
import 'story_seen.dart';
import 'dart:async';
import 'package:sornaz/components/home_top_bar.dart';
import 'package:sornaz/screens/Home/ui/components/app_drawer.dart';
import 'package:sornaz/components/main_tabs.dart';
import 'package:sornaz/components/join_community.dart';
import 'package:sornaz/helpers/user_facing_error.dart';
import 'package:sornaz/helpers/app_translations.dart';
import 'package:sornaz/components/app_text.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sornaz/screens/Authentication/providers/auth_session.dart';
import 'social_api.dart';
import 'social_widgets.dart';
import 'social_profile.dart';
import 'social_activity.dart';
import 'social_courses.dart';
import 'social_learning.dart';
import 'package:sornaz/components/bottom_nav.dart';

class UserPanelPage extends StatelessWidget {
  const UserPanelPage({super.key, this.initialTab = 0});
  final int initialTab;
  @override
  Widget build(BuildContext context) {
    if (initialTab != 2 && MainTabsScope.maybeOf(context) == null)
      return MainTabs(initialIndex: 2, initialChild: this);
    final auth = context.watch<AuthSession>();
    if (!auth.isAuthenticated)
      return SocialScaffold(
        tabIndex: 2,
        title: socialText(context, 'صحنه', 'Stage'),
        bottom: const BottomNavBarWidget(selectedIndex: 2),
        body: const JoinCommunity(),
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
  late final viewed = StorySeen.forAccount(widget.userId);
  Set<String> get seenStories => viewed.ids;
  Future<void> restoreSeenStories() => viewed.load();
  void markSeen(int id) {
    viewed.mark(id);
  }

  bool groupSeen(List<Json> group) =>
      group.every((s) => seenStories.contains(s['id'].toString()));
  Json? self;
  late int tab = widget.initialTab;
  int unread = 0;
  String searchQuery = '';
  Timer? searchTimer;
  int searchVersion = 0;
  List<Json> peopleResults = [];
  void searchCommunity(String value) {
    searchTimer?.cancel();
    final query = value.trim().toLowerCase();
    final version = ++searchVersion;
    setState(() {
      searchQuery = query;
      peopleResults = [];
    });
    if (query.isEmpty) return;
    searchTimer = Timer(const Duration(milliseconds: 300), () async {
      try {
        final people = objects(
          await api.get('/people?q=${Uri.encodeQueryComponent(query)}'),
        );
        if (mounted && version == searchVersion)
          setState(() => peopleResults = people);
      } catch (_) {}
    });
  }

  bool loading = true, more = true, fetchingMore = false;
  String? error;
  @override
  void initState() {
    super.initState();
    viewed.addListener(storyChanged);
    if (tab != 2) load();
  }

  void storyChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    viewed.removeListener(storyChanged);
    searchTimer?.cancel();
    api.dispose();
    super.dispose();
  }

  Future<void> load() async {
    try {
      await restoreSeenStories();
      final data = await Future.wait([
        api.get('/posts'),
        api.get('/posts?kind=story'),
        api.get('/notifications'),
        api.get('/users/' + widget.userId.toString()),
      ]);
      if (!mounted) return;
      setState(() {
        posts = objects(data[0]);
        self = object(data[3]);
        stories = [
          ...objects(data[1]),
          for (final s
              in (self!['stories'] is List
                  ? objects(self!['stories'])
                  : <Json>[]))
            {...s, 'author': self},
        ];
        final storyIds = <int>{};
        stories = stories.where((s) => storyIds.add(number(s['id']))).toList();
        unread = objects(data[2]).where((n) => n['read_at'] == null).length;
        loading = false;
        error = null;
        more = posts.length == 30;
      });
    } catch (e) {
      if (mounted)
        setState(() {
          error = userFacingError(e);
          loading = false;
        });
    }
  }

  List<List<Json>> get storyGroups => groupStoriesByAuthor(
    stories
        .where(
          (s) =>
              number(s['owner_id'] ?? optionalObject(s['author'])['id']) !=
              widget.userId,
        )
        .toList(),
    seen: seenStories,
  );

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

  @override
  Widget build(BuildContext context) => SocialScaffold(
    tabIndex: tab == 2 ? null : 2,
    appBar: tab == 2
        ? null
        : HomeTopBar(
            leadingWidget: CreateContentButton(api: api, onCreated: load),
            hint: socialText(
              context,
              'جست‌وجو در پست‌ها و جامعه سرناز…',
              'Search posts and the Sornaz community…',
            ),
            onSearch: searchCommunity,
            extraActions: [
              IconButton(
                icon: const Icon(Icons.chat_bubble_outline),
                onPressed: () => socialPush(context, DirectPage(api: api)),
              ),
              IconButton(
                icon: Badge(
                  isLabelVisible: unread > 0,
                  label: Text('$unread'),
                  child: const Icon(Icons.notifications_none),
                ),
                onPressed: () async {
                  await socialPush(context, NotificationsPage(api: api));
                  if (mounted) load();
                },
              ),
            ],
          ),
    drawer: tab == 2 ? null : const AppDrawer(),
    title: socialText(
      context,
      tab == 2 ? 'حساب کاربری' : 'صحنه',
      tab == 2 ? 'Account' : 'Stage',
    ),
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
                    if (searchQuery.isNotEmpty)
                      for (final person in peopleResults)
                        ListTile(
                          leading: SocialAvatar(api: api, user: person),
                          title: Text('${person['name']}'),
                          onTap: () => socialPush(
                            context,
                            ProfilePage(api: api, userId: number(person['id'])),
                          ),
                        ),
                    SizedBox(
                      height: 112,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        children: [
                          SizedBox(
                            width: 82,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SocialAvatar(
                                  api: api,
                                  user: self ?? {'id': widget.userId},
                                  size: 52,
                                  showEmptyRing: false,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  socialText(context, 'استوری من', 'My story'),
                                  style: const TextStyle(fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                          for (final group in storyGroups)
                            InkWell(
                              onTap: () async {
                                final first = group.indexWhere(
                                  (s) =>
                                      !seenStories.contains(s['id'].toString()),
                                );
                                await socialPush(
                                  context,
                                  StoryPage(
                                    api: api,
                                    stories: group,
                                    authorGroups: storyGroups,
                                    seen: seenStories,
                                    initialIndex: first < 0 ? 0 : first,
                                    onSeen: markSeen,
                                  ),
                                );
                                if (mounted) setState(() {});
                              },
                              child: SizedBox(
                                width: 82,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SocialAvatar(
                                      api: api,
                                      user: {
                                        ...object(group.first['author']),
                                        'stories': group,
                                      },
                                      story: true,
                                      seen: groupSeen(group),
                                      size: 52,
                                    ),
                                    const SizedBox(height: 6),
                                    AppText(
                                      '${group.first['author']['name']}',
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
                    for (final p in posts.where(
                      (p) =>
                          searchQuery.isEmpty ||
                          '${p['body']} ${p['caption']} ${p['title']} ${p['author']}'
                              .toLowerCase()
                              .contains(searchQuery),
                    ))
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
    bottom: tab == 2 ? null : const BottomNavBarWidget(selectedIndex: 2),
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
  final comments = GlobalKey<PostCommentsState>();
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
              socialUserName(author),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
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
                IconButton(
                  tooltip: socialText(context, 'نظرات', 'Comments'),
                  onPressed: () => comments.currentState?.open(),
                  icon: const Icon(Icons.chat_bubble_outline),
                ),
                IconButton(
                  tooltip: socialText(context, 'ارسال پست', 'Share post'),
                  onPressed: () =>
                      sharePost(context, widget.api, number(post['id'])),
                  icon: const Icon(Icons.send_outlined),
                ),
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
          PostComments(key: comments, api: widget.api, post: post),
          const Divider(height: 1),
        ],
      ),
    );
  }
}
