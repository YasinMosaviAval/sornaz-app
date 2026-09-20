import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sornaz/screens/Authentication/providers/auth_session.dart';
import 'package:sornaz/components/app_text.dart';
import 'package:sornaz/helpers/user_facing_error.dart';
import '../Site/panel_api.dart';
import '../Site/panel_form.dart';
import '../Site/panel_resource_page.dart';
import 'social_api.dart';
import 'social_widgets.dart';
import 'social_profile.dart';

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

Future<Json> chatSection(PanelApi api) async => objects(
  (await api.get(''))['sections'],
).firstWhere((s) => s['key'] == 'chat');

class DirectPage extends StatefulWidget {
  const DirectPage({super.key, required this.api, this.panelApi});
  final SocialApi api;
  final PanelApi? panelApi;
  @override
  State<DirectPage> createState() => _DirectPageState();
}

class _DirectPageState extends State<DirectPage> {
  late final panel =
      widget.panelApi ??
      PanelApi(
        widget.api.token,
        isCurrentAccount: () =>
            mounted &&
            (context.read<AuthSession?>()?.token ?? widget.api.token) ==
                widget.api.token,
      );
  List<Json>? conversations;
  String? error;
  bool fetching = false, creating = false;
  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void dispose() {
    if (widget.panelApi == null) panel.dispose();
    super.dispose();
  }

  Future<void> load() async {
    if (fetching) return;
    fetching = true;
    try {
      final rows = objects(await widget.api.get('/conversations'));
      if (mounted)
        setState(() {
          conversations = rows;
          error = null;
        });
    } catch (e) {
      if (mounted) setState(() => error = userFacingError(e));
    } finally {
      fetching = false;
    }
  }

  Future<void> createGroup() async {
    if (creating) return;
    setState(() => creating = true);
    try {
      final section = await chatSection(panel);
      final action = optionalObject(
        optionalObject(section['actions'])['create'],
      );
      if (action.isEmpty) return;
      final options = await panel.get('/chat/list');
      if (!mounted) return;
      await socialPush(
        context,
        PanelFormPage(
          title: socialText(context, 'گروه جدید', 'New group'),
          fields: objects(
            action['fields'],
          ).where((f) => f['key'] != 'type').toList(),
          data: options,
          initial: const {'type': 'group'},
          onSubmit: (result) async {
            if ('${result.values['title'] ?? ''}'.trim().isEmpty ||
                (result.values['userIds'] as List? ?? []).length < 2)
              throw SocialException(
                socialText(
                  context,
                  'نام گروه و حداقل دو عضو را انتخاب کنید.',
                  'Enter a group name and select at least two members.',
                ),
              );
            await panel.act('chat', 'create', values: result.values);
          },
        ),
      );
      if (mounted) await load();
    } catch (e) {
      if (mounted) socialError(context, e);
    } finally {
      if (mounted) setState(() => creating = false);
    }
  }

  Widget conversationList(bool group) {
    if (error != null) return SocialEmpty(error!, onRetry: load);
    if (conversations == null)
      return const Center(child: CircularProgressIndicator());
    final rows = conversations!
        .where((c) => (c['type'] == 'group') == group)
        .toList();
    return RefreshIndicator(
      onRefresh: load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          if (rows.isEmpty)
            SocialEmpty(
              socialText(
                context,
                group
                    ? 'هنوز گفتگوی گروهی ندارید.'
                    : 'برای شروع گفتگو، کاربری را از صفحه جست‌وجو انتخاب کنید.',
                group
                    ? 'No group conversations yet.'
                    : 'Choose a person to start a conversation.',
              ),
            ),
          for (final c in rows)
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
                    panelApi: panel,
                    id: number(c['id']),
                    title: '${c['title']}',
                    type: group ? 'group' : 'direct',
                  ),
                );
                if (mounted) load();
              },
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: 2,
    child: SocialScaffold(
      title: socialText(context,'گفتگو','Conversations'),
      actions: [
        IconButton(
          tooltip: socialText(context, 'گروه جدید', 'New group'),
          onPressed: creating ? null : createGroup,
          icon: const Icon(Icons.group_add_outlined),
        ),
        IconButton(
          tooltip: socialText(context, 'پیام جدید', 'New message'),
          onPressed: () async {
            await socialPush(context, PeoplePage(api: widget.api));
            if (mounted) load();
          },
          icon: const Icon(Icons.edit_square),
        ),
      ],
      body: Column(
        children: [
          TabBar(
            tabs: [
              Tab(text: socialText(context, 'خصوصی', 'Private')),
              Tab(text: socialText(context, 'گروهی', 'Groups')),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [conversationList(false), conversationList(true)],
            ),
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
    this.type = 'direct',
    this.panelApi,
  });
  final SocialApi api;
  final int id;
  final String title, type;
  final PanelApi? panelApi;
  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  late final panel =
      widget.panelApi ??
      PanelApi(
        widget.api.token,
        isCurrentAccount: () =>
            mounted &&
            (context.read<AuthSession?>()?.token ?? widget.api.token) ==
                widget.api.token,
      );
  late Future<Json> section = chatSection(panel);
  @override
  void dispose() {
    if (widget.panelApi == null) panel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<Json>(
    future: section,
    builder: (context, snapshot) {
      if (snapshot.hasData)
        return PanelConversationPage(
          api: panel,
          section: snapshot.data!,
          sendText: (body) async {
            final sent = object(
              await widget.api.post('/conversations/${widget.id}/messages', {
                'body': body,
              }),
            );
            panel.invalidate();
            return sent;
          },
          conversation: {
            'id': widget.id,
            'title': widget.title,
            'type': widget.type,
          },
        );
      return SocialScaffold(
        title: widget.title,
        body: snapshot.hasError
            ? SocialEmpty(
                userFacingError(snapshot.error!),
                onRetry: () => setState(() => section = chatSection(panel)),
              )
            : const Center(child: CircularProgressIndicator()),
      );
    },
  );
}
