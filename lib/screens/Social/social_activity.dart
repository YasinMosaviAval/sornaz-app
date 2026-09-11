export 'story_page.dart';
import 'package:sornaz/helpers/user_facing_error.dart';
import 'package:sornaz/helpers/app_translations.dart';
import 'package:sornaz/components/app_text.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'social_api.dart';
import 'social_widgets.dart';
import 'social_profile.dart';
import 'user_panel.dart';

Future<void> openDirect(
  BuildContext context,
  SocialApi api,
  int userId,
  String name,
) async {
  try {
    final conversation = object(
      await api.post('/conversations', {'user_id': '$userId'}),
    );
    if (context.mounted)
      await socialPush(
        context,
        ChatPage(api: api, id: number(conversation['id']), title: name),
      );
  } catch (e) {
    if (context.mounted) socialError(context, e);
  }
}

class DirectPage extends StatefulWidget {
  const DirectPage({super.key, required this.api});
  final SocialApi api;
  @override
  State<DirectPage> createState() => _DirectPageState();
}

class _DirectPageState extends State<DirectPage> {
  List<Json>? conversations;
  String? error;
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final rows = objects(await widget.api.get('/conversations'));
      if (mounted)
        setState(() {
          conversations = rows;
          error = null;
        });
    } catch (e) {
      if (mounted) setState(() => error = userFacingError(e));
    }
  }

  @override
  Widget build(BuildContext context) => SocialScaffold(
    title: 'دایرکت',
    actions: [
      IconButton(
        tooltip: 'پیام جدید'.translate(context),
        onPressed: () => socialPush(context, PeoplePage(api: widget.api)),
        icon: const Icon(Icons.edit_square),
      ),
    ],
    body: error != null
        ? SocialEmpty(error!, onRetry: load)
        : conversations == null
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: load,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                if (conversations!.isEmpty)
                  const SocialEmpty(
                    'برای شروع گفتگو، کاربری را از صفحه جست‌وجو انتخاب کنید.',
                  ),
                for (final c in conversations!)
                  ListTile(
                    leading: ClipOval(
                      child: SocialImage(
                        api: widget.api,
                        path: c['image'],
                        width: 50,
                        height: 50,
                      ),
                    ),
                    title: AppText('${c['title']}'),
                    subtitle: AppText(
                      '${c['lastMessage']}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: number(c['unread']) > 0
                        ? Badge(label: AppText('${c['unread']}'))
                        : null,
                    onTap: () async {
                      await socialPush(
                        context,
                        ChatPage(
                          api: widget.api,
                          id: number(c['id']),
                          title: '${c['title']}',
                        ),
                      );
                      if (mounted) load();
                    },
                  ),
              ],
            ),
          ),
  );
}

class ChatPage extends StatefulWidget {
  const ChatPage({
    super.key,
    required this.api,
    required this.id,
    required this.title,
  });
  final SocialApi api;
  final int id;
  final String title;
  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> with WidgetsBindingObserver {
  final body = TextEditingController();
  final scroll = ScrollController();
  List<Json> messages = [];
  bool sending = false, loading = true, polling = false, foreground = true;
  String? error;
  Timer? timer;
  int lastId = 0;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    load();
    timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (foreground) load();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    foreground = state == AppLifecycleState.resumed;
    if (foreground) load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    timer?.cancel();
    body.dispose();
    scroll.dispose();
    super.dispose();
  }

  Future<void> load() async {
    if (polling) return;
    polling = true;
    try {
      final result = object(
        await widget.api.get(
          '/conversations/${widget.id}/messages?after=$lastId',
        ),
      );
      if (!mounted) return;
      final incoming = objects(result['messages']);
      final nearEnd =
          !scroll.hasClients ||
          scroll.position.maxScrollExtent - scroll.offset < 100;
      setState(() {
        messages.addAll(
          incoming.where((m) => !messages.any((old) => old['id'] == m['id'])),
        );
        lastId = number(result['lastId']);
        loading = false;
        error = null;
      });
      if (incoming.isNotEmpty && nearEnd)
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && scroll.hasClients)
            scroll.jumpTo(scroll.position.maxScrollExtent);
        });
    } catch (e) {
      if (mounted)
        setState(() {
          error = userFacingError(e);
          loading = false;
        });
    } finally {
      polling = false;
    }
  }

  Future<void> send() async {
    final text = body.text.trim();
    if (text.isEmpty || sending) return;
    setState(() => sending = true);
    try {
      await widget.api.post('/conversations/${widget.id}/messages', {
        'body': text,
      });
      if (!mounted) return;
      body.clear();
      await load();
    } catch (e) {
      if (mounted) socialError(context, e);
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  @override
  Widget build(BuildContext context) => SocialScaffold(
    title: widget.title,
    body: Column(
      children: [
        if (error != null)
          MaterialBanner(
            content: AppText(error!),
            actions: [
              TextButton(onPressed: load, child: const AppText('تلاش دوباره')),
            ],
          ),
        Expanded(
          child: loading
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  controller: scroll,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, i) {
                    final m = messages[i];
                    final mine = m['mine'] == true;
                    return Align(
                      alignment: mine
                          ? AlignmentDirectional.centerEnd
                          : AlignmentDirectional.centerStart,
                      child: Container(
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.sizeOf(context).width * .78,
                        ),
                        margin: const EdgeInsets.symmetric(vertical: 5),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: mine
                              ? Theme.of(context).colorScheme.primaryContainer
                              : Theme.of(
                                  context,
                                ).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (!mine)
                              AppText(
                                '${m['sender']}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            AppText('${m['body']}'),
                            if (m['file'] != null)
                              const AppText(
                                '📎 فایل پیوست (قابل مشاهده در سایت)',
                              ),
                            const SizedBox(height: 4),
                            AppText(
                              '${m['createdAt']}',
                              style: const TextStyle(fontSize: 10),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: body,
                    enabled: !sending,
                    minLines: 1,
                    maxLines: 4,
                    maxLength: 10000,
                    decoration: InputDecoration(
                      hintText: 'پیام خصوصی…'.translate(context),
                      counterText: '',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton.filled(
                  onPressed: sending ? null : send,
                  tooltip: 'ارسال'.translate(context),
                  icon: sending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send_outlined),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

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
