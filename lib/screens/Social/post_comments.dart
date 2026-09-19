import 'package:flutter/material.dart';
import 'social_api.dart';
import 'social_widgets.dart';

class PostComments extends StatefulWidget {
  const PostComments({super.key, required this.api, required this.post});
  final SocialApi api;
  final Json post;
  @override
  State<PostComments> createState() => PostCommentsState();
}

class PostCommentsState extends State<PostComments> {
  final input = TextEditingController();
  final focus = FocusNode();
  List<Json> rows = [];
  Json? reply;
  bool expanded = false, loading = false, sending = false, more = true;
  String? error;
  final busy = <int>{};
  int get id => number(widget.post['id']);
  @override
  void dispose() {
    input.dispose();
    focus.dispose();
    super.dispose();
  }

  Future<void> open() async {
    if (!expanded) {
      setState(() => expanded = true);
      await load();
    }
    if (mounted) focus.requestFocus();
  }

  Future<void> load({bool older = false}) async {
    if (loading) return;
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final next = objects(
        await widget.api.get(
          '/posts/$id/comments' +
              (older && rows.isNotEmpty ? '?before=${rows.last['id']}' : ''),
        ),
      );
      if (mounted)
        setState(() {
          if (!older) rows = [];
          final ids = rows.map((c) => c['id']).toSet();
          rows.addAll(next.where((c) => !ids.contains(c['id'])));
          more = next.length == 30;
        });
    } catch (_) {
      if (mounted)
        setState(
          () => error = socialText(
            context,
            'دریافت نظرات ممکن نشد.',
            'Could not load comments.',
          ),
        );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> send() async {
    if (sending || input.text.trim().isEmpty) return;
    setState(() => sending = true);
    try {
      final c = object(
        await widget.api.post('/posts/$id/comments', {
          'body': input.text.trim(),
          if (reply != null) 'parent_id': '${reply!['id']}',
        }),
      );
      if (mounted)
        setState(() {
          rows.insert(0, c);
          reply = null;
          input.clear();
        });
    } catch (e) {
      if (mounted) socialError(context, e);
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  Future<void> like(Json c) async {
    final cid = number(c['id']);
    if (!busy.add(cid)) return;
    setState(() {});
    try {
      final data = object(
        await widget.api.post('/posts/$id/comments/$cid/like', {
          'active': c['liked'] == true ? '0' : '1',
        }),
      );
      if (mounted) setState(() => c.addAll(data));
    } catch (e) {
      if (mounted) socialError(context, e);
    } finally {
      busy.remove(cid);
      if (mounted) setState(() {});
    }
  }

  Future<void> remove(Json c) async {
    final cid = number(c['id']);
    if (!busy.add(cid)) return;
    try {
      await widget.api.post('/posts/$id/comments/$cid/delete');
      if (mounted) setState(() => rows.remove(c));
    } catch (e) {
      if (mounted) socialError(context, e);
    } finally {
      busy.remove(cid);
    }
  }

  @override
  Widget build(BuildContext context) {
    final preview = widget.post['comments'] is List
        ? objects(widget.post['comments'])
        : <Json>[];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!expanded) ...[
            for (final c in preview)
              InkWell(
                onTap: open,
                child: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    '${socialUserName(c)}  ${c['body']}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ),
            if (number(widget.post['comment_count']) > 0)
              TextButton(
                onPressed: open,
                child: Text(
                  socialText(context, 'نمایش نظرات', 'View comments') +
                      ' (${widget.post['comment_count']})',
                ),
              ),
          ] else ...[
            for (final c in rows)
              Padding(
                padding: EdgeInsetsDirectional.only(
                  start: number(c['parent_id']) > 0 ? 16 : 0,
                  top: 8,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (c['parent_body'] != null)
                      Text(
                        socialText(context, 'در پاسخ به: ', 'Replying to: ') +
                            c['parent_body'].toString(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: Theme.of(context).hintColor,
                        ),
                      ),
                    Text(
                      socialUserName(optionalObject(c['author'])),
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                    Text('${c['body']}', style: const TextStyle(fontSize: 13)),
                    Row(
                      children: [
                        IconButton(
                          tooltip: socialText(
                            context,
                            'پسندیدن نظر',
                            'Like comment',
                          ),
                          visualDensity: VisualDensity.compact,
                          iconSize: 18,
                          onPressed: busy.contains(number(c['id']))
                              ? null
                              : () => like(c),
                          icon: Icon(
                            c['liked'] == true
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: c['liked'] == true
                                ? Theme.of(context).colorScheme.primary
                                : null,
                          ),
                        ),
                        Text(
                          '${c['likes'] ?? 0}',
                          style: const TextStyle(fontSize: 11),
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() => reply = c);
                            focus.requestFocus();
                          },
                          child: Text(socialText(context, 'پاسخ', 'Reply')),
                        ),
                        if (c['canDelete'] == true)
                          IconButton(
                            tooltip: socialText(
                              context,
                              'حذف نظر',
                              'Delete comment',
                            ),
                            iconSize: 18,
                            onPressed: busy.contains(number(c['id']))
                                ? null
                                : () => remove(c),
                            icon: const Icon(Icons.delete_outline),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            if (loading) const LinearProgressIndicator(),
            if (error != null) TextButton(onPressed: load, child: Text(error!)),
            if (more && !loading && rows.isNotEmpty)
              TextButton(
                onPressed: () => load(older: true),
                child: Text(
                  socialText(context, 'نظرات بیشتر', 'More comments'),
                ),
              ),
            if (reply != null)
              Row(
                children: [
                  Expanded(
                    child: Text(
                      socialText(context, 'پاسخ به ', 'Reply to ') +
                          socialUserName(optionalObject(reply!['author'])),
                    ),
                  ),
                  IconButton(
                    onPressed: () => setState(() => reply = null),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: input,
                    focusNode: focus,
                    minLines: 1,
                    maxLines: 4,
                    maxLength: 2000,
                    decoration: InputDecoration(
                      hintText: socialText(
                        context,
                        'نظر شما…',
                        'Your comment…',
                      ),
                      counterText: '',
                    ),
                  ),
                ),
                IconButton(
                  tooltip: socialText(context, 'ارسال نظر', 'Send comment'),
                  onPressed: sending ? null : send,
                  icon: const Icon(Icons.send_outlined),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

Future<void> sharePost(BuildContext context, SocialApi api, int id) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => SharePostSheet(api: api, postId: id),
    );

class SharePostSheet extends StatefulWidget {
  const SharePostSheet({super.key, required this.api, required this.postId});
  final SocialApi api;
  final int postId;
  @override
  State<SharePostSheet> createState() => _SharePostSheetState();
}

class _SharePostSheetState extends State<SharePostSheet> {
  List<Json> users = [];
  final selected = <int>{};
  bool loading = false, sending = false;
  String? error;
  int version = 0;
  @override
  void initState() {
    super.initState();
    load('');
  }

  Future<void> load(String q) async {
    final current = ++version;
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final rows = objects(
        await widget.api.get('/people?q=${Uri.encodeQueryComponent(q.trim())}'),
      );
      if (mounted && current == version)
        setState(() => users = rows.where((u) => u['isMe'] != true).toList());
    } catch (_) {
      if (mounted && current == version)
        setState(
          () => error = socialText(
            context,
            'دریافت کاربران ممکن نشد.',
            'Could not load members.',
          ),
        );
    } finally {
      if (mounted && current == version) setState(() => loading = false);
    }
  }

  Future<void> send() async {
    if (sending || selected.isEmpty) return;
    setState(() => sending = true);
    try {
      await widget.api.post('/posts/${widget.postId}/share', {
        for (var i = 0; i < selected.length; i++)
          'user_ids[$i]': selected.elementAt(i).toString(),
      });
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) socialError(context, e);
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        16,
        24,
        MediaQuery.viewInsetsOf(context).bottom + 16,
      ),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * .6,
        child: Column(
          children: [
            Text(
              socialText(
                context,
                'ارسال پست برای اعضا',
                'Send post to members',
              ),
            ),
            TextField(
              onSubmitted: load,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: socialText(
                  context,
                  'جستجوی نام کاربری',
                  'Search username',
                ),
                prefixIcon: const Icon(Icons.search),
              ),
            ),
            if (loading) const LinearProgressIndicator(),
            if (error != null) Text(error!),
            Expanded(
              child: ListView(
                children: [
                  for (final u in users)
                    CheckboxListTile(
                      value: selected.contains(number(u['id'])),
                      title: Text(socialUserName(u)),
                      secondary: SocialAvatar(
                        api: widget.api,
                        user: u,
                        size: 32,
                      ),
                      onChanged: sending
                          ? null
                          : (v) {
                              setState(() {
                                if (v == true && selected.length < 10)
                                  selected.add(number(u['id']));
                                else if (v == false)
                                  selected.remove(number(u['id']));
                              });
                            },
                    ),
                ],
              ),
            ),
            FilledButton(
              onPressed: sending || selected.isEmpty ? null : send,
              child: Text(
                socialText(context, 'ارسال', 'Send') +
                    ' (${selected.length}/10)',
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
