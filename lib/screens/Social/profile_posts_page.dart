import 'package:flutter/material.dart';
import 'social_api.dart';
import 'social_widgets.dart';
import 'user_panel.dart';

/// Two slivers grow around the selected post, avoiding estimated item offsets.
class ProfilePostsPage extends StatefulWidget {
  const ProfilePostsPage({
    super.key,
    required this.api,
    required this.posts,
    required this.selected,
    required this.onChanged,
  });
  final SocialApi api;
  final List<Json> posts;
  final int selected;
  final VoidCallback onChanged;
  @override
  State<ProfilePostsPage> createState() => _ProfilePostsPageState();
}

class _ProfilePostsPageState extends State<ProfilePostsPage> {
  final center = GlobalKey();
  late final rows = [...widget.posts];
  bool loading = false, more = true;
  Future<void> loadMore() async {
    if (loading || !more || rows.isEmpty) return;
    setState(() => loading = true);
    try {
      final last = rows.last;
      final owner = last['owner_id'] ?? optionalObject(last['author'])['id'];
      final next = objects(
        await widget.api.get('/posts?owner=$owner&before=${last['id']}'),
      );
      if (!mounted) return;
      setState(() {
        final ids = rows.map((p) => p['id']).toSet();
        rows.addAll(next.where((p) => !ids.contains(p['id'])));
        more = next.length == 30;
      });
    } catch (e) {
      if (mounted) socialError(context, e);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => SocialScaffold(
    title: socialText(context, 'پست‌ها', 'Posts'),
    body: CustomScrollView(
      key: const ValueKey('profile-post-stream'),
      center: center,
      slivers: [
        SliverList.builder(
          itemCount: widget.selected,
          itemBuilder: (c, i) => PostCard(
            key: ValueKey(rows[widget.selected - i - 1]['id']),
            api: widget.api,
            post: rows[widget.selected - i - 1],
            onChanged: widget.onChanged,
          ),
        ),
        SliverList.builder(
          key: center,
          itemCount: rows.length - widget.selected,
          itemBuilder: (c, i) => PostCard(
            key: ValueKey(rows[widget.selected + i]['id']),
            api: widget.api,
            post: rows[widget.selected + i],
            onChanged: widget.onChanged,
          ),
        ),
        if (more)
          SliverToBoxAdapter(
            child: TextButton(
              onPressed: loading ? null : loadMore,
              child: Text(
                socialText(context, 'نمایش پست‌های بیشتر', 'Load more posts'),
              ),
            ),
          ),
      ],
    ),
  );
}
