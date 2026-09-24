import 'panel_navigation.dart';
import 'panel_list_item.dart';
import 'package:flutter/material.dart';
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
      }
    } catch (e) {
      if (mounted) setState(() => error = e);
    } finally {
      fetching = false;
      if (mounted) setState(() => loading = false);
    }
  }

  IconData icon(String key) => switch (key) {
    'account' => Icons.account_circle_outlined,
    'chat' => Icons.chat_bubble_outline,
    'dashboard' => Icons.dashboard_outlined,
    'finance' => Icons.account_balance_wallet_outlined,
    'courses' => Icons.menu_book_outlined,
    'classrooms' => Icons.meeting_room_outlined,
    'branches' => Icons.account_tree_outlined,
    'members' => Icons.groups_outlined,
    'students' => Icons.school_outlined,
    'gallery' || 'media' => Icons.photo_library_outlined,
    'messages' => Icons.mail_outline,
    'notifications' => Icons.notifications_outlined,
    'roles' || 'permissions' || 'users' => Icons.admin_panel_settings_outlined,
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
  Widget build(BuildContext context) => MainTabScaffold(
    index: 1,
    appBar: HomeTopBar(
      onSearch: contentOverflows || query.isNotEmpty
          ? (v) => setState(() => query = v)
          : null,
      hint: socialText(context, 'جستجو در پنل کاربری', 'Search user panel'),
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
                padding: const EdgeInsets.symmetric(vertical: 24),
                children: [
                  for (final section in panelNavigation(sections))
                    if (matches(section)) menuItem(section),
                ],
              ),
            ),
          ),
  );
}
