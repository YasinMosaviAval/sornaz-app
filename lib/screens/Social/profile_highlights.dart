import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'social_api.dart';
import 'social_widgets.dart';
import 'story_page.dart';

class ProfileHighlights extends StatefulWidget {
  const ProfileHighlights({
    super.key,
    required this.api,
    required this.owner,
    required this.isMe,
  });
  final SocialApi api;
  final int owner;
  final bool isMe;
  @override
  State<ProfileHighlights> createState() => _ProfileHighlightsState();
}

class _ProfileHighlightsState extends State<ProfileHighlights> {
  List<Json> rows = [];
  bool loading = true;
  Object? error;
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final items = objects(
        await widget.api.get('/users/${widget.owner}/highlights'),
      );
      if (mounted)
        setState(() {
          rows = items;
          error = null;
        });
    } catch (e) {
      if (mounted) setState(() => error = e);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> edit([Json? h]) async {
    if (await socialPush(
              context,
              HighlightEditor(api: widget.api, highlight: h),
            ) !=
            null &&
        mounted)
      await load();
  }

  Future<void> open(Json h) async {
    try {
      final stories = objects(
        await widget.api.get('/highlights/${h['id']}/stories'),
      );
      if (mounted)
        await socialPush(context, StoryPage(api: widget.api, stories: stories));
    } catch (e) {
      if (mounted) socialError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading)
      return const SizedBox(height: 2, child: LinearProgressIndicator());
    if (error != null)
      return TextButton(
        onPressed: load,
        child: Text(
          socialText(context, 'بارگذاری دوباره هایلایت‌ها', 'Retry highlights'),
        ),
      );
    if (rows.isEmpty && !widget.isMe) return const SizedBox.shrink();
    return SizedBox(
      height: 112,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          if (widget.isMe)
            SizedBox(
              width: 86,
              child: InkWell(
                onTap: edit,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircleAvatar(radius: 28, child: Icon(Icons.add)),
                    const SizedBox(height: 8),
                    Text(
                      socialText(context, 'هایلایت جدید', 'New highlight'),
                      style: const TextStyle(fontSize: 11),
                    ),
                  ],
                ),
              ),
            ),
          for (final h in rows)
            SizedBox(
              width: 86,
              child: InkWell(
                onTap: () => open(h),
                onLongPress: widget.isMe ? () => edit(h) : null,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ClipOval(
                      child: SocialImage(
                        api: widget.api,
                        path: h['cover'],
                        width: 56,
                        height: 56,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${h['title']}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class HighlightEditor extends StatefulWidget {
  const HighlightEditor({super.key, required this.api, this.highlight});
  final SocialApi api;
  final Json? highlight;
  @override
  State<HighlightEditor> createState() => _HighlightEditorState();
}

class _HighlightEditorState extends State<HighlightEditor> {
  late final title = TextEditingController(
    text: '${widget.highlight?['title'] ?? ''}',
  );
  late int cover = number(widget.highlight?['cover_id']);
  late String? coverUrl = widget.highlight?['cover'];
  final selected = <int>{};
  List<Json> stories = [];
  bool loading = true, busy = false, more = true;
  Object? error;
  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void dispose() {
    title.dispose();
    super.dispose();
  }

  Future<void> load({bool older = false}) async {
    setState(() => loading = true);
    try {
      final rows = objects(
        await widget.api.get(
          '/stories/archive${older && stories.isNotEmpty ? '?before=${stories.map((s) => number(s['id'])).reduce((a, b) => a < b ? a : b)}' : ''}',
        ),
      );
      if (!older && widget.highlight != null) {
        final saved = objects(
          await widget.api.get(
            '/highlights/${widget.highlight!['id']}/stories',
          ),
        );
        selected.addAll(saved.map((s) => number(s['id'])));
        stories = saved;
      }
      if (mounted)
        setState(() {
          stories = {
            for (final s in [...stories, ...rows]) number(s['id']): s,
          }.values.toList();
          more = rows.length == 100;
          error = null;
        });
    } catch (e) {
      if (mounted) setState(() => error = e);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> chooseCover() async {
    final files = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
    );
    if (files == null || !mounted) return;
    setState(() => busy = true);
    try {
      final media = await widget.api.upload(files.files.single);
      if (mounted)
        setState(() {
          cover = number(media['id']);
          coverUrl = widget.api.uri('/media/$cover').toString();
        });
    } catch (e) {
      if (mounted) socialError(context, e);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> save() async {
    if (busy || selected.isEmpty || cover == 0 || title.text.trim().isEmpty)
      return;
    setState(() => busy = true);
    try {
      await widget.api.post('/highlights', {
        'id': '${widget.highlight?['id'] ?? 0}',
        'title': title.text.trim(),
        'cover_id': '$cover',
        'story_ids': jsonEncode(selected.toList()),
      });
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) socialError(context, e);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> remove() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(socialText(c, 'هایلایت حذف شود؟', 'Delete highlight?')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: Text(socialText(c, 'خیر', 'No')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: Text(socialText(c, 'بلی', 'Yes')),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => busy = true);
    try {
      await widget.api.post(
        '/highlights/${widget.highlight!['id']}/delete',
        {},
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) socialError(context, e);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => SocialScaffold(
    title: socialText(context, 'هایلایت استوری', 'Story highlight'),
    actions: [
      if (widget.highlight != null)
        IconButton(
          onPressed: busy ? null : remove,
          icon: const Icon(Icons.delete_outline),
        ),
      IconButton(
        onPressed:
            busy || selected.isEmpty || cover == 0 || title.text.trim().isEmpty
            ? null
            : save,
        icon: const Icon(Icons.save_outlined),
      ),
    ],
    body: AbsorbPointer(
      absorbing: busy,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: title,
            onChanged: (_) => setState(() {}),
            maxLength: 80,
            decoration: InputDecoration(
              labelText: socialText(context, 'نام هایلایت', 'Highlight name'),
            ),
          ),
          if (coverUrl != null)
            Center(
              child: ClipOval(
                child: SocialImage(
                  api: widget.api,
                  path: coverUrl,
                  width: 80,
                  height: 80,
                ),
              ),
            ),
          OutlinedButton.icon(
            onPressed: chooseCover,
            icon: const Icon(Icons.image_outlined),
            label: Text(socialText(context, 'انتخاب کاور', 'Choose cover')),
          ),
          Text(
            socialText(
              context,
              'استوری‌ها را انتخاب کنید. برای انتخاب تصویر یک استوری به‌عنوان کاور، آن را نگه دارید.',
              'Select stories. Hold a photo story to use it as the cover.',
            ),
          ),
          if (loading || busy) const LinearProgressIndicator(),
          if (error != null)
            TextButton(
              onPressed: load,
              child: Text(socialText(context, 'تلاش دوباره', 'Retry')),
            ),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            childAspectRatio: 9 / 16,
            children: [
              for (final s in stories)
                InkWell(
                  onTap: () => setState(() {
                    final id = number(s['id']);
                    selected.contains(id)
                        ? selected.remove(id)
                        : selected.add(id);
                    if (cover == 0 && '${s['mime']}'.startsWith('image/')) {
                      cover = number(s['media_id']);
                      coverUrl = s['media'];
                    }
                  }),
                  onLongPress: '${s['mime']}'.startsWith('image/')
                      ? () => setState(() {
                          cover = number(s['media_id']);
                          coverUrl = s['media'];
                        })
                      : null,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if ('${s['mime']}'.startsWith('image/'))
                        SocialImage(
                          api: widget.api,
                          path: s['media'],
                          fit: BoxFit.cover,
                        )
                      else
                        const ColoredBox(
                          color: Colors.black26,
                          child: Icon(Icons.videocam_outlined),
                        ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: Icon(
                          selected.contains(number(s['id']))
                              ? Icons.check_circle
                              : Icons.circle_outlined,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      Positioned(
                        bottom: 4,
                        left: 4,
                        right: 4,
                        child: Text(
                          '${s['created_at'] ?? ''}',
                          style: const TextStyle(
                            fontSize: 10,
                            backgroundColor: Colors.black54,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          if (more && !loading)
            TextButton(
              onPressed: () => load(older: true),
              child: Text(
                socialText(context, 'استوری‌های قدیمی‌تر', 'Older stories'),
              ),
            ),
        ],
      ),
    ),
  );
}
