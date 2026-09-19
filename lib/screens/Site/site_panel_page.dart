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
  @override
  Widget build(BuildContext context) => MainTabScaffold(
    index: 1,
    appBar: HomeTopBar(
      onSearch: (v) => setState(() => query = v),
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
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    socialText(context, 'پنل کاربری', 'User panel'),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                for (final section in sections.where(
                  (s) => '${s['label']} ${s['en']}'.toLowerCase().contains(
                    query.toLowerCase(),
                  ),
                ))
                  Card(
                    child: ListTile(
                      leading: Icon(icon('${section['key']}')),
                      title: Text(panelLabel(context, section)),
                      trailing: Icon(
                        Directionality.of(context) == TextDirection.rtl
                            ? Icons.chevron_left
                            : Icons.chevron_right,
                      ),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              PanelResourcePage(api: api, section: section),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
  );
}
