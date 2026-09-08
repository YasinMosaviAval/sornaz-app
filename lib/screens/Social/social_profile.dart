import 'package:sornaz/helpers/app_translations.dart';
import 'package:sornaz/components/app_text.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'social_api.dart';
import 'social_widgets.dart';
import 'social_activity.dart';
import 'social_courses.dart';
import 'user_panel.dart';
import 'learning_actions.dart';
import 'package:url_launcher/url_launcher.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key, required this.api, required this.userId});
  final SocialApi api;
  final int userId;
  @override
  Widget build(BuildContext context) => SocialScaffold(
    title: socialText(context, 'پروفایل کاربر', 'User profile'),
    actions: [BookmarkButton(api: api, kind: 'author', id: userId)],
    body: ProfileBody(api: api, userId: userId),
  );
}

class ProfileBody extends StatefulWidget {
  const ProfileBody({super.key, required this.api, required this.userId});
  final SocialApi api;
  final int userId;
  @override
  State<ProfileBody> createState() => _ProfileBodyState();
}

class _ProfileBodyState extends State<ProfileBody> {
  Json? user;
  List<Json> posts = [];
  int tab = 0;
  bool busy = false;
  String? error;
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final results = await Future.wait([
        widget.api.get('/users/${widget.userId}'),
        widget.api.get('/posts?owner=${widget.userId}'),
      ]);
      if (mounted)
        setState(() {
          user = object(results[0]);
          posts = objects(results[1]);
          error = null;
        });
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    }
  }

  Future<void> follow() async {
    setState(() => busy = true);
    try {
      final data = object(
        await widget.api.post('/users/${widget.userId}/follow', {
          'active': user!['isFollowing'] == true ? '0' : '1',
        }),
      );
      if (mounted) setState(() => user = data);
    } catch (e) {
      if (mounted) socialError(context, e);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Widget stat(String key, String label, {VoidCallback? onTap}) => Expanded(
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          children: [
            AppText(
              '${user![key]}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            AppText(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).hintColor,
              ),
            ),
          ],
        ),
      ),
    ),
  );
  @override
  Widget build(BuildContext context) {
    if (error != null) return SocialEmpty(error!, onRetry: load);
    if (user == null) return const Center(child: CircularProgressIndicator());
    final u = user!;
    return RefreshIndicator(
      onRefresh: load,
      child: ListView(
        children: [
          SizedBox(
            height: 238,
            child: Stack(
              children: [
                SocialImage(
                  api: widget.api,
                  path: u['cover'],
                  height: 180,
                  width: double.infinity,
                ),
                PositionedDirectional(
                  start: 20,
                  bottom: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Theme.of(context).scaffoldBackgroundColor,
                    ),
                    padding: const EdgeInsets.all(3),
                    child: SocialAvatar(api: widget.api, user: u, size: 96),
                  ),
                ),
                PositionedDirectional(
                  end: 16,
                  bottom: 7,
                  child: u['isMe'] == true
                      ? OutlinedButton(
                          onPressed: () async {
                            await socialPush(
                              context,
                              EditProfilePage(api: widget.api, profile: u),
                            );
                            if (mounted) load();
                          },
                          child: AppText(
                            socialText(
                              context,
                              'ویرایش پروفایل',
                              'Edit profile',
                            ),
                          ),
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            OutlinedButton(
                              onPressed: busy ? null : follow,
                              child: AppText(
                                u['isFollowing'] == true
                                    ? 'دنبال می‌کنید'
                                    : 'دنبال کردن',
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton.filledTonal(
                              tooltip: 'پیام خصوصی'.translate(context),
                              onPressed: () => openDirect(
                                context,
                                widget.api,
                                widget.userId,
                                '${u['name']}',
                              ),
                              icon: const Icon(Icons.chat_bubble_outline),
                            ),
                          ],
                        ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  '${u['name']}',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                AppText(
                  '@${u['username']}',
                  style: TextStyle(color: Theme.of(context).hintColor),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                const Divider(),
                Row(
                  children: [
                    stat(
                      'posts',
                      'پست‌ها',
                      onTap: () => setState(() => tab = 0),
                    ),
                    stat(
                      'courses',
                      'دوره‌ها',
                      onTap: () => setState(() => tab = 1),
                    ),
                    stat(
                      'followers',
                      'دنبال‌کنندگان',
                      onTap: () => socialPush(
                        context,
                        PeoplePage(
                          api: widget.api,
                          userId: widget.userId,
                          kind: 'followers',
                        ),
                      ),
                    ),
                    stat(
                      'following',
                      'دنبال‌شونده‌ها',
                      onTap: () => socialPush(
                        context,
                        PeoplePage(
                          api: widget.api,
                          userId: widget.userId,
                          kind: 'following',
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(),
              ],
            ),
          ),
          if ('${u['bio']}'.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(20),
              child: AppText('${u['bio']}'),
            ),
          if (u['links'] is Map)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Wrap(
                spacing: 8,
                children: [
                  for (final entry in object(
                    u['links'],
                  ).entries.where((e) => '${e.value}'.isNotEmpty))
                    TextButton.icon(
                      onPressed: () async {
                        final url = Uri.tryParse('${entry.value}');
                        if (url != null && url.scheme == 'https') {
                          try {
                            if (!await launchUrl(
                              url,
                              mode: LaunchMode.externalApplication,
                            ))
                              throw const SocialException('لینک باز نشد.');
                          } catch (e) {
                            if (context.mounted) socialError(context, e);
                          }
                        }
                      },
                      icon: const Icon(Icons.open_in_new, size: 16),
                      label: AppText(entry.key),
                    ),
                ],
              ),
            ),
          if (u['isMe'] == true)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 8,
                children: [
                  ActionChip(
                    avatar: const Icon(Icons.school_outlined, size: 18),
                    label: const AppText('مدیریت دوره‌ها'),
                    onPressed: () => socialPush(
                      context,
                      CoursesPage(api: widget.api, mode: 'manage'),
                    ),
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.bookmark_border, size: 18),
                    label: const AppText('ذخیره‌شده‌ها'),
                    onPressed: () =>
                        socialPush(context, SavedPostsPage(api: widget.api)),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                for (var i = 0; i < 2; i++)
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => tab = i),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: tab == i
                                  ? const Color(0xffcc338c)
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                        ),
                        child: AppText(
                          i == 0 ? 'پست‌ها' : 'دوره‌ها',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: tab == i ? const Color(0xffcc338c) : null,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (tab == 0) ...[
            if (posts.isEmpty) const SocialEmpty('هنوز پستی منتشر نشده است.'),
            for (final post in posts)
              PostCard(
                key: ValueKey(post['id']),
                api: widget.api,
                post: post,
                onChanged: load,
              ),
          ] else
            CoursesBody(api: widget.api, owner: widget.userId, embedded: true),
          const SizedBox(height: 90),
        ],
      ),
    );
  }
}

class PeoplePage extends StatefulWidget {
  const PeoplePage({super.key, required this.api, this.userId, this.kind});
  final SocialApi api;
  final int? userId;
  final String? kind;
  @override
  State<PeoplePage> createState() => _PeoplePageState();
}

class _PeoplePageState extends State<PeoplePage> {
  List<Json>? users;
  String? error;
  final search = TextEditingController();
  int requestId = 0;
  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  Future<void> load() async {
    final version = ++requestId;
    try {
      final rows = objects(
        await widget.api.get(
          widget.userId == null
              ? '/people?q=${Uri.encodeQueryComponent(search.text.trim())}'
              : '/users/${widget.userId}/${widget.kind}',
        ),
      );
      if (mounted && version == requestId)
        setState(() {
          users = rows;
          error = null;
        });
    } catch (e) {
      if (mounted && version == requestId) setState(() => error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) => SocialScaffold(
    title: widget.kind == 'followers'
        ? 'دنبال‌کنندگان'
        : widget.kind == 'following'
        ? 'دنبال‌شونده‌ها'
        : 'کشف کاربران',
    body: Column(
      children: [
        if (widget.userId == null)
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: search,
              onSubmitted: (_) => load(),
              decoration: InputDecoration(
                hintText: 'جست‌وجوی نام کاربری'.translate(context),
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  onPressed: load,
                  icon: const Icon(Icons.search),
                ),
              ),
            ),
          ),
        Expanded(
          child: error != null
              ? SocialEmpty(error!, onRetry: load)
              : users == null
              ? const Center(child: CircularProgressIndicator())
              : users!.isEmpty
              ? const SocialEmpty('کاربری پیدا نشد.')
              : RefreshIndicator(
                  onRefresh: load,
                  child: ListView.builder(
                    itemCount: users!.length,
                    itemBuilder: (context, i) {
                      final user = users![i];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 6,
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(12),
                          leading: SocialAvatar(
                            api: widget.api,
                            user: user,
                            size: 40,
                          ),
                          title: AppText('${user['name']}'),
                          subtitle: AppText('@${user['username']}'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () async {
                            await socialPush(
                              context,
                              ProfilePage(
                                api: widget.api,
                                userId: number(user['id']),
                              ),
                            );
                            if (mounted) load();
                          },
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    ),
  );
}

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key, required this.api, required this.profile});
  final SocialApi api;
  final Json profile;
  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late final name = TextEditingController(text: '${widget.profile['name']}');
  late final bio = TextEditingController(text: '${widget.profile['bio']}');
  late final links = {
    for (final key in ['website', 'instagram', 'youtube'])
      key: TextEditingController(
        text: '${(widget.profile['links'] as Map?)?[key] ?? ''}',
      ),
  };
  final previews = <String, String>{};
  final form = GlobalKey<FormState>();
  final Map<String, String> media = {};
  bool busy = false;
  @override
  void dispose() {
    name.dispose();
    bio.dispose();
    for (final c in links.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> image(String key) async {
    final file = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
    );
    if (file == null || !mounted) return;
    setState(() => busy = true);
    try {
      final result = await widget.api.upload(file.files.single);
      if (mounted)
        setState(() {
          media['${key}_id'] = '${result['id']}';
          previews[key] = widget.api.uri('/media/${result['id']}').toString();
        });
    } catch (e) {
      if (mounted) socialError(context, e);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> save() async {
    if (!(form.currentState?.validate() ?? false)) return;
    setState(() => busy = true);
    try {
      await widget.api.post('/me', {
        'name': name.text.trim(),
        'bio': bio.text,
        ...media,
      });
      await widget.api.post('/settings', {
        for (final e in links.entries) e.key: e.value.text.trim(),
      });
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) socialError(context, e);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => SocialScaffold(
    title: 'ویرایش پروفایل',
    body: AbsorbPointer(
      absorbing: busy,
      child: Form(
        key: form,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Center(
              child: Stack(
                children: [
                  SocialAvatar(
                    api: widget.api,
                    user: {
                      ...widget.profile,
                      if (previews['avatar'] != null)
                        'avatar': previews['avatar'],
                    },
                    size: 112,
                  ),
                  PositionedDirectional(
                    end: 0,
                    bottom: 0,
                    child: IconButton.filled(
                      tooltip: 'تغییر تصویر پروفایل'.translate(context),
                      onPressed: () => image('avatar'),
                      icon: const Icon(Icons.camera_alt_outlined),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: name,
              validator: (v) => v == null || v.trim().isEmpty
                  ? 'نام نمایشی را وارد کنید.'.translate(context)
                  : null,
              maxLength: 180,
              decoration: InputDecoration(
                labelText: 'نام نمایشی'.translate(context),
              ),
            ),
            TextField(
              controller: bio,
              maxLength: 3000,
              maxLines: 5,
              decoration: InputDecoration(
                labelText: 'درباره من'.translate(context),
              ),
            ),
            const SizedBox(height: 16),
            const AppText(
              'لینک‌های عمومی',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            for (final e in links.entries)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: TextFormField(
                  controller: e.value,
                  keyboardType: TextInputType.url,
                  textDirection: TextDirection.ltr,
                  maxLength: 500,
                  decoration: InputDecoration(
                    labelText: e.key,
                    hintText: 'https://',
                    border: const OutlineInputBorder(),
                    counterText: '',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return null;
                    final uri = Uri.tryParse(value.trim());
                    return uri == null ||
                            uri.scheme != 'https' ||
                            uri.host.isEmpty
                        ? 'آدرس معتبر https وارد کنید.'.translate(context)
                        : null;
                  },
                ),
              ),
            for (final key in ['avatar', 'cover'])
              OutlinedButton.icon(
                onPressed: () => image(key),
                icon: Icon(
                  media.containsKey('${key}_id')
                      ? Icons.check
                      : Icons.image_outlined,
                ),
                label: AppText(
                  key == 'avatar' ? 'انتخاب تصویر پروفایل' : 'انتخاب کاور',
                ),
              ),
            const SizedBox(height: 20),
            if (busy) const LinearProgressIndicator(),
            FilledButton(
              onPressed: busy ? null : save,
              child: const AppText('ذخیره تغییرات'),
            ),
          ],
        ),
      ),
    ),
  );
}

class SavedPostsPage extends StatefulWidget {
  const SavedPostsPage({super.key, required this.api});
  final SocialApi api;
  @override
  State<SavedPostsPage> createState() => _SavedPostsPageState();
}

class _SavedPostsPageState extends State<SavedPostsPage> {
  late Future<dynamic> data = widget.api.get('/posts?saved=1');
  @override
  Widget build(BuildContext context) => SocialScaffold(
    title: 'پست‌های ذخیره‌شده',
    body: FutureBuilder(
      future: data,
      builder: (context, snapshot) {
        if (snapshot.hasError)
          return SocialEmpty(
            '${snapshot.error}',
            onRetry: () =>
                setState(() => data = widget.api.get('/posts?saved=1')),
          );
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());
        final rows = objects(snapshot.data);
        return rows.isEmpty
            ? const SocialEmpty('هنوز پستی ذخیره نکرده‌اید.')
            : ListView(
                children: [
                  for (final p in rows) PostCard(api: widget.api, post: p),
                ],
              );
      },
    ),
  );
}
