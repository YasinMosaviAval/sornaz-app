import 'dart:async';
import 'panel_navigation.dart';
import 'branch_style.dart';
import 'panel_list_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:sornaz/components/home_top_bar.dart';
import 'package:sornaz/components/join_community.dart';
import 'package:sornaz/components/main_tab_scaffold.dart';
import 'package:sornaz/components/main_tabs.dart';
import 'package:sornaz/screens/Authentication/providers/auth_session.dart';
import '../Social/social_api.dart';
import '../Social/social_widgets.dart';
import 'panel_api.dart';
import 'panel_resource_page.dart';

class SitePanelPage extends StatelessWidget {
  const SitePanelPage({super.key, this.api});
  final PanelApi? api;
  @override
  Widget build(BuildContext context) {
    if (MainTabsScope.maybeOf(context) == null) {
      return MainTabs(initialIndex: 1, initialChild: this);
    }
    final token = context.watch<AuthSession?>()?.token ?? '';
    if (token.isEmpty && api == null) {
      return const MainTabScaffold(
        index: 1,
        appBar: HomeTopBar(),
        body: JoinCommunity(),
      );
    }
    return NativePanel(key: ValueKey(token), token: token, api: api);
  }
}

class NativePanel extends StatefulWidget {
  const NativePanel({super.key, required this.token, this.api});
  final String token;
  final PanelApi? api;
  @override
  State<NativePanel> createState() => _NativePanelState();
}

class _NativePanelState extends State<NativePanel> {
  late final api =
      widget.api ??
      PanelApi(
        widget.token,
        isCurrentAccount: () =>
            mounted && context.read<AuthSession?>()?.token == widget.token,
      );
  List<Json> sections = [];
  int unreadMessages = 0, unreadNotifications = 0;
  bool loading = true;
  Object? error;
  String query = '';
  bool contentOverflows = false;
  bool measure(ScrollMetricsNotification n) {
    if (n.depth == 0) {
      final overflow =
          n.metrics.maxScrollExtent > n.metrics.minScrollExtent + 1;
      if (overflow != contentOverflows)
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && contentOverflows != overflow)
            setState(() => contentOverflows = overflow);
        });
    }
    return false;
  }

  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void dispose() {
    if (widget.api == null) api.dispose();
    super.dispose();
  }

  bool fetching = false;
  Future<void> load({bool refresh = false}) async {
    if (fetching) return;
    fetching = true;
    try {
      final result = await (refresh ? api.refresh('') : api.get(''));
      if (mounted) {
        setState(() {
          sections = objects(result['sections'] ?? []);
          error = null;
        });
        unawaited(loadUnread());
      }
    } catch (e) {
      if (mounted) setState(() => error = e);
    } finally {
      fetching = false;
      if (mounted) setState(() => loading = false);
    }
  }

  bool hasSection(String key) =>
      sections.any((section) => section['key'] == key);

  Future<void> loadUnread({bool refresh = false}) async {
    if (!hasSection('messages') && !hasSection('notifications')) return;
    try {
      if (refresh) api.invalidate();
      final data = await api.get('/messages/list');
      if (!mounted) return;
      final unread = optionalObject(data['unread']);
      setState(() {
        unreadMessages = number(unread['messages']);
        unreadNotifications = number(unread['notifications']);
      });
    } catch (_) {
      // The destinations remain available when the count cannot be loaded.
    }
  }

  Future<void> openTopSection(String key) async {
    final section = sections.where((item) => item['key'] == key).firstOrNull;
    if (section == null) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PanelResourcePage(api: api, section: section),
      ),
    );
    if (mounted) await loadUnread(refresh: true);
  }

  Widget topSection(String key, Widget icon, String fa, String en, int count) =>
      IconButton(
        tooltip: socialText(context, fa, en),
        onPressed: () => openTopSection(key),
        icon: Badge(
          isLabelVisible: count > 0,
          label: Text('$count'),
          child: icon,
        ),
      );

  IconData icon(String key) => switch (key) {
    'tests' => Icons.science_outlined,
    'posts' => Icons.description_outlined,
    'post-categories' => Icons.folder_open_outlined,
    'pages' => Icons.content_copy_outlined,
    'media' => Icons.perm_media_outlined,
    'comments' => Icons.forum_outlined,
    'chart-gallery' => Icons.pie_chart_outline,
    'reports' => Icons.bar_chart_outlined,
    'dashboard' => Icons.home_outlined,
    'account' => Icons.manage_accounts_outlined,
    'chat' => Icons.mark_chat_unread_outlined,
    'my-classrooms' => Icons.co_present_outlined,
    'my-courses' || 'courses' || 'publications' => Icons.menu_book_outlined,
    'my-terms' || 'terms' => Icons.event_available_outlined,
    'achievements-menu' => Icons.emoji_events_outlined,
    'awards' => Icons.workspace_premium_outlined,
    'badges' => Icons.military_tech_outlined,
    'experiences' => Icons.work_outline,
    'certificates' => Icons.verified_outlined,
    'educations' => Icons.school_outlined,
    'events' => Icons.today_outlined,
    'polls' => Icons.poll_outlined,
    'tracking' => Icons.trending_up,
    'national-holidays' => Icons.event_busy_outlined,
    'branches-menu' || 'branches' => Icons.business_outlined,
    'branch-types' => Icons.layers_outlined,
    'access-menu' => Icons.badge_outlined,
    'users' || 'students' => Icons.groups_outlined,
    'roles' => Icons.person_outline,
    'permissions' => Icons.key_outlined,
    'gallery-menu' => Icons.photo_library_outlined,
    'gallery' => Icons.collections_outlined,
    'lessons-menu' || 'lessons' => Icons.book_outlined,
    'course-levels' => Icons.signal_cellular_alt,
    'teachers' || 'members' => Icons.co_present_outlined,
    'classes-menu' || 'classrooms' => Icons.meeting_room_outlined,
    'classroom-types' => Icons.category_outlined,
    'schedules-menu' || 'schedules' => Icons.calendar_month_outlined,
    'scheduling-rules' => Icons.gavel_outlined,
    'availabilities' => Icons.schedule_outlined,
    'member-schedules' => Icons.access_time_outlined,
    'availability-exceptions' => Icons.beach_access_outlined,
    'finance' => Icons.payments_outlined,
    'messages' => Icons.mail_outline,
    'notifications' => Icons.notifications_outlined,
    _ => Icons.view_list_outlined,
  };
  bool matches(Json section) =>
      query.isEmpty ||
      ('${section['label']} ${section['en']}').toLowerCase().contains(
        query.toLowerCase(),
      ) ||
      (section['children'] is List &&
          objects(section['children']).any(matches));
  Widget menuItem(Json section, [int depth = 0]) {
    final children = section['children'];
    if (children is List)
      return PanelListItem(
        child: ExpansionTile(
          key: PageStorageKey('${section['key']}-${query.isNotEmpty}'),
          tilePadding: EdgeInsetsDirectional.only(
            start: 24 + depth * 20.0,
            end: 8,
          ),
          title: Text(panelLabel(context, section)),
          leading: Icon(icon('${section['key']}')),
          initiallyExpanded: query.isNotEmpty,
          shape: const Border(),
          collapsedShape: const Border(),
          children: [
            for (final child in objects(children))
              if (query.isEmpty ||
                  matches(child) ||
                  ('${section['label']} ${section['en']}')
                      .toLowerCase()
                      .contains(query.toLowerCase()))
                menuItem(child, depth + 1),
          ],
        ),
      );
    return PanelListItem(
      child: ListTile(
        contentPadding: EdgeInsetsDirectional.only(
          start: 24 + depth * 20.0,
          end: 8,
        ),
        leading: Icon(icon('${section['key']}')),
        title: Text(panelLabel(context, section)),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => PanelResourcePage(
              api: api,
              section: section,
              params: optionalObject(
                section['initialParams'],
              ).map((k, v) => MapEntry(k, '$v')),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Theme(
    data: branchTheme(context),
    child: MainTabScaffold(
      index: 1,
      appBar: HomeTopBar(
        showLogo: false,
        onSearch: (v) => setState(() => query = v),
        hint: socialText(context, 'جستجو در پنل کاربری', 'Search user panel'),
        extraActions: [
          if (hasSection('points'))
            topSection(
              'points',
              SvgPicture.asset(
                'assets/icons/coins.svg',
                width: 24,
                height: 24,
                colorFilter: ColorFilter.mode(
                  IconTheme.of(context).color ??
                      Theme.of(context).colorScheme.onSurface,
                  BlendMode.srcIn,
                ),
              ),
              'امتیازها',
              'Points',
              0,
            ),
          if (hasSection('messages'))
            topSection(
              'messages',
              const Icon(Icons.mail_outline),
              'پیام‌ها',
              'Messages',
              unreadMessages,
            ),
          if (hasSection('notifications'))
            topSection(
              'notifications',
              const Icon(Icons.notifications_none),
              'اعلان‌ها',
              'Notifications',
              unreadNotifications,
            ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
          ? SocialEmpty(
              socialText(
                context,
                'پنل دریافت نشد. دوباره تلاش کنید.',
                'Could not load your panel. Please retry.',
              ),
              onRetry: load,
            )
          : RefreshIndicator(
              onRefresh: () => load(refresh: true),
              child: NotificationListener<ScrollMetricsNotification>(
                onNotification: measure,
                child: ListView(
                  padding: const EdgeInsets.only(bottom: 24),
                  children: [
                    for (final section in panelNavigation(sections))
                      if (matches(section)) menuItem(section),
                  ],
                ),
              ),
            ),
    ),
  );
}
