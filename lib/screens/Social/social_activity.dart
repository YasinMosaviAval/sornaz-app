import 'social_direct.dart';
export 'social_direct.dart';
export 'story_page.dart';
import 'package:sornaz/helpers/user_facing_error.dart';
import 'package:sornaz/components/app_text.dart';
import 'package:flutter/material.dart';
import 'social_api.dart';
import 'social_widgets.dart';
import 'social_profile.dart';
import 'user_panel.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key, required this.api});
  final SocialApi api;
  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  List<Json>? items;
  String? error;
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final rows = objects(await widget.api.get('/notifications'));
      if (mounted)
        setState(() {
          items = rows;
          error = null;
        });
    } catch (e) {
      if (mounted) setState(() => error = userFacingError(e));
    }
  }

  Future<void> open(Json n) async {
    try {
      await widget.api.post('/notifications/${n['id']}/read');
      if (!mounted) return;
      setState(() => n['read_at'] = 'read');
      if (n['kind'] == 'message') {
        await socialPush(
          context,
          ChatPage(
            api: widget.api,
            id: number(n['target_id']),
            title: '${n['actor']['name']}',
          ),
        );
      } else if (n['kind'] == 'follow') {
        await socialPush(
          context,
          ProfilePage(api: widget.api, userId: number(n['actor_id'])),
        );
      } else {
        final p = object(await widget.api.get('/posts/${n['target_id']}'));
        if (mounted)
          await socialPush(
            context,
            SocialScaffold(
              title: 'پست',
              body: ListView(
                children: [PostCard(api: widget.api, post: p)],
              ),
            ),
          );
      }
    } catch (e) {
      if (mounted) socialError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) => SocialScaffold(
    title: 'اعلان‌ها',
    body: error != null
        ? SocialEmpty(error!, onRetry: load)
        : items == null
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: load,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                if (items!.isEmpty)
                  const SocialEmpty(
                    'هنوز اعلانی ندارید.',
                    icon: Icons.notifications_none,
                  ),
                for (final n in items!)
                  ListTile(
                    leading: SocialAvatar(
                      api: widget.api,
                      user: object(n['actor']),
                      size: 40,
                    ),
                    title: AppText('${n['actor']['name']} ${n['body']}'),
                    subtitle: AppText('${n['created_at']}'),
                    trailing: n['read_at'] == null ? const Badge() : null,
                    onTap: () => open(n),
                  ),
              ],
            ),
          ),
  );
}
