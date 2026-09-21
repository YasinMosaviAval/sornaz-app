import 'profile_highlights.dart';
import 'profile_articles.dart';
import '../Site/panel_api.dart';
import 'package:sornaz/components/home_top_bar.dart';
import 'dart:async';
import 'profile_posts_page.dart';
import 'package:provider/provider.dart';
import 'package:sornaz/screens/Authentication/providers/auth_session.dart';
import 'package:sornaz/helpers/user_facing_error.dart';
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
      if (mounted) setState(() => error = userFacingError(e));
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
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Column(
          children: [
            AppText(
              '${user![key]}',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            AppText(
              label,
              style: TextStyle(
                fontSize: 10,
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
            height: 180,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                SocialImage(
                  api: widget.api,
                  path: u['cover'],
                  height: 180,
                  width: double.infinity,
                ),
                PositionedDirectional(
                  start: 20,
                  bottom: -48,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Theme.of(context).scaffoldBackgroundColor,
                    ),
                    padding: const EdgeInsets.all(3),
                    child: SocialAvatar(
                      api: widget.api,
                      user: u,
                      size: 96,
                      ringWidth: 3,
                    ),
                  ),
                ),
              ],
            ),
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 52),
            child: Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(130, 4, 20, 0),
              child: AppText(
                '${u['shortIntro'] ?? ''}',
                key: const ValueKey('profile-bio'),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: AppText(
                    socialUserName(u),
                    key: const ValueKey('profile-username'),
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
                stat(
                  'followers',
                  socialText(context, 'دنبال‌کنندگان', 'Followers'),
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
                  socialText(context, 'دنبال‌شونده‌ها', 'Following'),
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
          ),
          if (u['isMe'] != true)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: busy ? null : follow,
                    child: AppText(
                      u['isFollowing'] == true ? 'دنبال می‌کنید' : 'دنبال کردن',
                    ),
                  ),
                  IconButton(
                    onPressed: () => openDirect(
                      context,
                      widget.api,
                      widget.userId,
                      socialUserName(u),
                    ),
                    icon: const Icon(Icons.chat_bubble_outline),
                  ),
                ],
              ),
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
                        final url = entry.key == 'email'
                            ? Uri(scheme: 'mailto', path: '${entry.value}')
                            : Uri.tryParse('${entry.value}');
                        if (url != null &&
                            (url.scheme == 'https' ||
                                (entry.key == 'email' &&
                                    url.scheme == 'mailto'))) {
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
          ProfileHighlights(
            api: widget.api,
            owner: widget.userId,
            isMe: u['isMe'] == true,
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                for (var i = 0; i < 3; i++)
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => tab = i),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: tab == i
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                        ),
                        child: AppText(
                          i == 2
                              ? socialText(context, 'مقاله‌ها', 'Articles') +
                                    ' (' +
                                    number(u['articles']).toString() +
                                    ')'
                              : (i == 0
                                        ? socialText(context, 'پست‌ها', 'Posts')
                                        : socialText(
                                            context,
                                            'دوره‌ها',
                                            'Courses',
                                          )) +
                                    ' (' +
                                    (i == 0 ? u['posts'] : u['courses'])
                                        .toString() +
                                    ')',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: tab == i
                                ? Theme.of(context).colorScheme.primary
                                : null,
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
            ProfilePostGrid(api: widget.api, posts: posts, onChanged: load),
          ] else if (tab == 1)
            CoursesBody(api: widget.api, owner: widget.userId, embedded: true)
          else
            ProfileArticles(owner: widget.userId),
          const SizedBox(height: 90),
        ],
      ),
    );
  }
}

class ProfilePostGrid extends StatelessWidget {
  const ProfilePostGrid({
    super.key,
    required this.api,
    required this.posts,
    required this.onChanged,
  });
  final SocialApi api;
  final List<Json> posts;
  final VoidCallback onChanged;
  @override
  Widget build(BuildContext context) => GridView.builder(
    key: const ValueKey('profile-post-grid'),
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    padding: const EdgeInsets.symmetric(horizontal: 3),
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 3,
      childAspectRatio: 9 / 16,
      crossAxisSpacing: 3,
      mainAxisSpacing: 3,
    ),
    itemCount: posts.length,
    itemBuilder: (context, index) {
      final post = posts[index];
      final video = '${post['mime']}'.startsWith('video/');
      final path = video ? post['thumbnail'] : post['media'];
      return InkWell(
        key: ValueKey('profile-post-${post['id']}'),
        onTap: () async {
          var changed = false;
          await socialPush(
            context,
            ProfilePostsPage(
              api: api,
              posts: posts,
              selected: index,
              onChanged: () => changed = true,
            ),
          );
          if (changed && context.mounted) onChanged();
        },
        child: Semantics(
          label: '${post['body'] ?? ''}',
          button: true,
          child: Stack(
            fit: StackFit.expand,
            children: [
              SocialImage(api: api, path: path is String ? path : null),
              if (path == null && '${post['body'] ?? ''}'.isNotEmpty)
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: AppText(
                      '${post['body']}',
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ),
              if (video)
                const PositionedDirectional(
                  top: 8,
                  end: 8,
                  child: Icon(Icons.play_circle_fill, color: Colors.white),
                ),
            ],
          ),
        ),
      );
    },
  );
}

class PeoplePage extends StatefulWidget {
  const PeoplePage({
    super.key,
    required this.api,
    this.userId,
    this.kind,
    this.community = false,
  });
  final SocialApi api;
  final int? userId;
  final String? kind;
  final bool community;
  @override
  State<PeoplePage> createState() => _PeoplePageState();
}

class _PeoplePageState extends State<PeoplePage> {
  List<Json>? users;
  String? error;
  final search = TextEditingController();
  int requestId = 0;
  Timer? debounce;
  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void dispose() {
    debounce?.cancel();
    search.dispose();
    super.dispose();
  }

  Future<void> load() async {
    final version = ++requestId;
    try {
      final rows = objects(
        await widget.api.get(
          widget.userId == null
              ? (widget.community && search.text.trim().isEmpty
                    ? '/community'
                    : '/people?q=${Uri.encodeQueryComponent(search.text.trim())}')
              : '/users/${widget.userId}/${widget.kind}?q=${Uri.encodeQueryComponent(search.text.trim())}',
        ),
      );
      if (mounted && version == requestId)
        setState(() {
          users = rows;
          error = null;
        });
    } catch (e) {
      if (mounted && version == requestId)
        setState(() => error = userFacingError(e));
    }
  }

  @override
  Widget build(BuildContext context) => SocialScaffold(
    title: widget.kind == 'followers'
        ? 'دنبال‌کنندگان'
        : widget.kind == 'following'
        ? 'دنبال‌شونده‌ها'
        : 'کشف کاربران',
    appBar: HomeTopBar(
      searchOnly: true,
      pageTitle: widget.community
          ? socialText(context, 'جامعه سرناز', 'Sornaz community')
          : widget.kind == 'followers'
          ? socialText(context, 'دنبال‌کنندگان', 'Followers')
          : widget.kind == 'following'
          ? socialText(context, 'دنبال‌شوندگان', 'Following')
          : socialText(context, 'کشف کاربران', 'Discover people'),
      hint: socialText(context, 'جستجوی نام کاربری', 'Search username'),
      onSearch: (value) {
        search.text = value;
        debounce?.cancel();
        debounce = Timer(const Duration(milliseconds: 350), load);
      },
    ),
    body: Column(
      children: [
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
                    padding: const EdgeInsets.only(top: 12, bottom: 12),
                    itemCount: users!.length,
                    itemBuilder: (context, i) {
                      final user = users![i];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                          ),
                          minVerticalPadding: 0,
                          minTileHeight: 48,
                          leading: SocialAvatar(
                            api: widget.api,
                            user: user,
                            size: 48,
                          ),
                          title: AppText(socialUserName(user)),
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
  const EditProfilePage({
    super.key,
    required this.api,
    required this.profile,
    this.accountApi,
  });
  final SocialApi api;
  final Json profile;
  final PanelApi? accountApi;
  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late final panel =
      widget.accountApi ??
      PanelApi(
        widget.api.token,
        isCurrentAccount: () =>
            mounted &&
            (context.read<AuthSession?>()?.token ?? widget.api.token) ==
                widget.api.token,
      );
  final contacts = {
    for (final key in ['email', 'phone', 'founded', 'address', 'shortIntro'])
      key: TextEditingController(),
  };
  Json privateProfile = {};
  bool detailsLoading = true;
  String? detailsError;
  bool get human =>
      (privateProfile['accountType'] ?? widget.profile['type'] ?? 'human') ==
      'human';
  @override
  void initState() {
    super.initState();
    loadDetails();
  }

  Future<void> loadDetails() async {
    setState(() => detailsLoading = true);
    try {
      final data = await panel.get('/account/list');
      if (!mounted) return;
      setState(() {
        privateProfile = optionalObject(data['profile']);
        for (final e in contacts.entries) {
          e.value.text = (privateProfile[e.key] ?? '').toString();
        }
        detailsError = null;
      });
    } catch (e) {
      if (mounted) setState(() => detailsError = userFacingError(e));
    } finally {
      if (mounted) setState(() => detailsLoading = false);
    }
  }

  Future<void> pickDate() async {
    final current = DateTime.tryParse(contacts['founded']!.text);
    final last = DateTime.now();
    final value = await showDatePicker(
      context: context,
      initialDate:
          current != null && !current.isAfter(last) && current.year >= 1900
          ? current
          : last,
      firstDate: DateTime(1900),
      lastDate: last,
    );
    if (value != null)
      contacts['founded']!.text =
          value.year.toString() +
          '-' +
          value.month.toString().padLeft(2, '0') +
          '-' +
          value.day.toString().padLeft(2, '0');
  }

  late final name = TextEditingController(
    text: '${widget.profile['name'] ?? ''}',
  );
  late final bio = TextEditingController(
    text: '${widget.profile['bio'] ?? ''}',
  );
  late final links = {
    for (final key in ['email', 'website', 'instagram', 'youtube'])
      key: TextEditingController(
        text:
            '${(widget.profile['links'] is Map ? widget.profile['links'] as Map : const {})[key] ?? ''}',
      ),
  };
  final previews = <String, String>{};
  final form = GlobalKey<FormState>();
  final Map<String, String> media = {};
  bool busy = false;
  @override
  void dispose() {
    if (widget.accountApi == null) panel.dispose();
    for (final c in contacts.values) {
      c.dispose();
    }
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
    if (detailsLoading ||
        detailsError != null ||
        busy ||
        !(form.currentState?.validate() ?? false))
      return;
    setState(() => busy = true);
    try {
      await panel.act(
        'account',
        'profile',
        values: {
          'name': name.text.trim(),
          for (final key in ['email', 'phone', 'founded', 'address'])
            key: contacts[key]!.text.trim(),
        },
      );
      await panel.act(
        'account',
        'bio',
        values: {
          'shortIntro': contacts['shortIntro']!.text.trim(),
          'biography': bio.text,
        },
      );
      final updated = object(
        await widget.api.post('/me', {
          'name': name.text.trim(),
          'bio': bio.text,
          ...media,
        }),
      );
      if (mounted)
        await context
            .read<AuthSession?>()
            ?.updateProfile(number(updated['id']), {
              ...updated,
              'email': contacts['email']!.text.trim(),
              'phone': contacts['phone']!.text.trim(),
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
      absorbing: busy || detailsLoading,
      child: Form(
        key: form,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            if (detailsLoading) const LinearProgressIndicator(),
            if (detailsError != null)
              TextButton(onPressed: loadDetails, child: Text(detailsError!)),
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
            for (final field in [
              ('email', 'ایمیل', 'Email'),
              ('phone', 'شماره تماس', 'Phone number'),
              (
                'founded',
                human ? 'تاریخ تولد' : 'تاریخ تأسیس',
                human ? 'Date of birth' : 'Establishment date',
              ),
              ('address', 'نشانی', 'Address'),
              ('shortIntro', 'معرفی کوتاه', 'Short introduction'),
            ])
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: TextFormField(
                  controller: contacts[field.$1],
                  readOnly: field.$1 == 'founded',
                  onTap: field.$1 == 'founded' ? pickDate : null,
                  keyboardType: field.$1 == 'email'
                      ? TextInputType.emailAddress
                      : field.$1 == 'phone'
                      ? TextInputType.phone
                      : TextInputType.text,
                  maxLines: ['address', 'shortIntro'].contains(field.$1)
                      ? 3
                      : 1,
                  maxLength: field.$1 == 'shortIntro' ? 500 : null,
                  decoration: InputDecoration(
                    labelText: socialText(context, field.$2, field.$3),
                    suffixIcon: field.$1 == 'founded'
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () => contacts['founded']!.clear(),
                          )
                        : null,
                  ),
                  validator: (v) =>
                      field.$1 == 'email' &&
                          v != null &&
                          v.isNotEmpty &&
                          !RegExp(
                            r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
                          ).hasMatch(v.trim())
                      ? socialText(
                          context,
                          'ایمیل معتبر وارد کنید.',
                          'Enter a valid email address.',
                        )
                      : null,
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
                  keyboardType: e.key == 'email'
                      ? TextInputType.emailAddress
                      : TextInputType.url,
                  textDirection: TextDirection.ltr,
                  maxLength: 500,
                  decoration: InputDecoration(
                    labelText: e.key == 'email'
                        ? socialText(context, 'ایمیل عمومی', 'Public email')
                        : e.key,
                    hintText: e.key == 'email' ? null : 'https://',
                    border: const OutlineInputBorder(),
                    counterText: '',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return null;
                    if (e.key == 'email')
                      return RegExp(
                            r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
                          ).hasMatch(value.trim())
                          ? null
                          : socialText(
                              context,
                              'ایمیل معتبر وارد کنید.',
                              'Enter a valid email address.',
                            );
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
              onPressed: busy || detailsLoading || detailsError != null
                  ? null
                  : save,
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
            userFacingError(snapshot.error ?? ''),
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
