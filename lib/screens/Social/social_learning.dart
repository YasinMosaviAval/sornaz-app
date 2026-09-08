import 'package:sornaz/helpers/app_translations.dart';
import 'package:sornaz/components/app_text.dart';
import 'package:flutter/material.dart';
import 'social_api.dart';
import 'social_widgets.dart';
import 'social_profile.dart';
import 'social_courses.dart';
import 'social_activity.dart';
import 'social_downloads.dart';
import 'learning_widgets.dart';

class AccountDashboardBody extends StatefulWidget {
  const AccountDashboardBody({super.key, required this.api});
  final SocialApi api;
  @override
  State<AccountDashboardBody> createState() => _AccountDashboardBodyState();
}

class _AccountDashboardBodyState extends State<AccountDashboardBody> {
  Json? data;
  String? error;
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final result = object(await widget.api.get('/dashboard'));
      if (mounted)
        setState(() {
          data = result;
          error = null;
        });
    } catch (e) {
      if (mounted) setState(() => error = '$e');
    }
  }

  Future<void> open(Widget page) async {
    await socialPush(context, page);
    if (mounted) await load();
  }

  @override
  Widget build(BuildContext context) {
    if (error != null) return SocialEmpty(error!, onRetry: load);
    if (data == null) return const Center(child: CircularProgressIndicator());
    final profile = object(data!['profile']);
    final courses = objects(data!['courses']);
    final active = courses.where((c) => number(c['progress']) < 100).toList();
    final finished = courses
        .where((c) => number(c['progress']) == 100)
        .toList();
    return RefreshIndicator(
      onRefresh: load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          Center(
            child: SocialAvatar(api: widget.api, user: profile, size: 104),
          ),
          const SizedBox(height: 14),
          AppText(
            '${profile['name']}',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
          ),
          AppText(
            '@${profile['username']}',
            textAlign: TextAlign.center,
            style: TextStyle(color: Theme.of(context).hintColor),
          ),
          const SizedBox(height: 14),
          AppText(
            '${profile['bio'] ?? ''}',
            textAlign: TextAlign.center,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () =>
                      open(EditProfilePage(api: widget.api, profile: profile)),
                  child: AppText(
                    socialText(context, 'ویرایش پروفایل', 'Edit profile'),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => open(
                    ProfilePage(api: widget.api, userId: number(profile['id'])),
                  ),
                  child: AppText(
                    socialText(context, 'پروفایل عمومی', 'Public profile'),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          for (final item in [
            (
              Icons.bookmark_border,
              'ذخیره‌شده‌ها',
              'Saved',
              SavedLibraryPage(api: widget.api),
            ),
            (
              Icons.download_outlined,
              'دانلودها',
              'Downloads',
              DownloadsPage(api: widget.api),
            ),
            (
              Icons.notifications_none,
              'تنظیمات اعلان',
              'Notification settings',
              NotificationSettingsPage(api: widget.api),
            ),
          ])
            Card(
              elevation: 0,
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: Icon(item.$1),
                title: AppText(socialText(context, item.$2, item.$3)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => open(item.$4),
              ),
            ),
          LearningHeading(
            socialText(context, 'پیشرفت یادگیری', 'Learning progress'),
            onMore: () => open(LearningProgressPage(api: widget.api)),
          ),
          if (active.isEmpty)
            AppText(
              socialText(
                context,
                'برای شروع یادگیری یک دوره انتخاب کنید.',
                'Choose a course to start learning.',
              ),
            ),
          for (final course in active.take(2))
            LearningCourseTile(
              api: widget.api,
              course: course,
              showProgress: true,
              onTap: () => open(
                CourseDetailPage(api: widget.api, id: number(course['id'])),
              ),
            ),
          LearningHeading(
            socialText(context, 'دوره‌های تکمیل‌شده', 'Finished courses'),
          ),
          if (finished.isEmpty)
            AppText(
              socialText(
                context,
                'با تکمیل درس‌ها، دوره‌ها اینجا نمایش داده می‌شوند.',
                'Completed courses will appear here.',
              ),
            ),
          for (final course in finished)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.check_circle, color: Color(0xff4f9771)),
              title: AppText('${course['title']}'),
              onTap: () => open(
                CourseDetailPage(api: widget.api, id: number(course['id'])),
              ),
            ),
          LearningHeading(socialText(context, 'دستاوردها', 'Achievements')),
          LayoutBuilder(
            builder: (context, box) => Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final badge in [
                  (
                    'اولین درس',
                    'First lesson',
                    number(data!['completed_lessons']) >= 1,
                    Icons.school_outlined,
                  ),
                  (
                    'ده درس',
                    'Ten lessons',
                    number(data!['completed_lessons']) >= 10,
                    Icons.auto_stories_outlined,
                  ),
                  (
                    'اولین دوره',
                    'First course',
                    finished.isNotEmpty,
                    Icons.workspace_premium_outlined,
                  ),
                  (
                    'سه دوره',
                    'Three courses',
                    finished.length >= 3,
                    Icons.emoji_events_outlined,
                  ),
                ])
                  SizedBox(
                    width: (box.maxWidth - 12) / 2,
                    child: Card(
                      elevation: 0,
                      margin: EdgeInsets.zero,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Icon(
                              badge.$4,
                              size: 40,
                              color: badge.$3
                                  ? const Color(0xffd3ae32)
                                  : Theme.of(context).disabledColor,
                            ),
                            const SizedBox(height: 12),
                            AppText(
                              socialText(context, badge.$1, badge.$2),
                              textAlign: TextAlign.center,
                            ),
                            AppText(
                              badge.$3
                                  ? socialText(context, 'به دست آمد', 'Earned')
                                  : socialText(
                                      context,
                                      'هنوز تکمیل نشده',
                                      'Not earned yet',
                                    ),
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          OutlinedButton.icon(
            onPressed: () => open(CoursesPage(api: widget.api, mode: 'manage')),
            icon: const Icon(Icons.add),
            label: AppText(
              socialText(
                context,
                'ساخت و مدیریت دوره',
                'Create and manage courses',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class LearningProgressPage extends StatelessWidget {
  const LearningProgressPage({super.key, required this.api});
  final SocialApi api;
  @override
  Widget build(BuildContext context) => SocialScaffold(
    title: socialText(context, 'پیشرفت یادگیری', 'Learning progress'),
    body: LearningList(api: api),
  );
}

class LearningList extends StatefulWidget {
  const LearningList({super.key, required this.api});
  final SocialApi api;
  @override
  State<LearningList> createState() => _LearningListState();
}

class _LearningListState extends State<LearningList> {
  late Future<dynamic> future = widget.api.get('/dashboard');
  @override
  Widget build(BuildContext context) => FutureBuilder(
    future: future,
    builder: (context, s) {
      if (s.hasError)
        return SocialEmpty(
          '${s.error}',
          onRetry: () => setState(() => future = widget.api.get('/dashboard')),
        );
      if (!s.hasData) return const Center(child: CircularProgressIndicator());
      final rows = objects(object(s.data)['courses']);
      return RefreshIndicator(
        onRefresh: () async {
          setState(() => future = widget.api.get('/dashboard'));
          await future;
        },
        child: ListView(
          padding: const EdgeInsets.all(24),
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            if (rows.isEmpty) const SocialEmpty('هنوز دوره‌ای تهیه نکرده‌اید.'),
            for (final c in rows)
              LearningCourseTile(
                api: widget.api,
                course: c,
                showProgress: true,
                onTap: () async {
                  await socialPush(
                    context,
                    CourseDetailPage(api: widget.api, id: number(c['id'])),
                  );
                  if (mounted)
                    setState(() => future = widget.api.get('/dashboard'));
                },
              ),
          ],
        ),
      );
    },
  );
}

class SavedLibraryPage extends StatefulWidget {
  const SavedLibraryPage({super.key, required this.api});
  final SocialApi api;
  @override
  State<SavedLibraryPage> createState() => _SavedLibraryPageState();
}

class _SavedLibraryPageState extends State<SavedLibraryPage> {
  Json? data;
  String? error;
  bool busy = false;
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final d = object(await widget.api.get('/bookmarks'));
      if (mounted)
        setState(() {
          data = d;
          error = null;
        });
    } catch (e) {
      if (mounted) setState(() => error = '$e');
    }
  }

  Future<void> remove(String kind, int id) async {
    setState(() => busy = true);
    try {
      await widget.api.post('/bookmarks', {
        'kind': kind,
        'id': '$id',
        'active': '0',
      });
      await load();
    } catch (e) {
      if (mounted) socialError(context, e);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => SocialScaffold(
    title: socialText(context, 'ذخیره‌شده‌ها', 'Saved'),
    body: DefaultTabController(
      length: 3,
      child: Column(
        children: [
          TabBar(
            tabs: [
              Tab(text: socialText(context, 'دوره‌ها', 'Courses')),
              Tab(text: socialText(context, 'نویسندگان', 'Authors')),
              Tab(text: socialText(context, 'پست‌ها', 'Posts')),
            ],
          ),
          Expanded(
            child: error != null
                ? SocialEmpty(error!, onRetry: load)
                : data == null
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    children: [
                      for (final kind in ['courses', 'authors'])
                        RefreshIndicator(
                          onRefresh: load,
                          child: ListView(
                            padding: const EdgeInsets.all(24),
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              if (objects(data![kind]).isEmpty)
                                SocialEmpty(
                                  socialText(
                                    context,
                                    'هنوز چیزی ذخیره نکرده‌اید.',
                                    'Nothing saved yet.',
                                  ),
                                ),
                              for (final row in objects(data![kind])) ...[
                                if (kind == 'courses')
                                  LearningCourseTile(
                                    api: widget.api,
                                    course: row,
                                    trailing: IconButton(
                                      tooltip: 'حذف نشان'.translate(context),
                                      onPressed: busy
                                          ? null
                                          : () => remove(
                                              'course',
                                              number(row['id']),
                                            ),
                                      icon: const Icon(Icons.bookmark),
                                    ),
                                  )
                                else
                                  ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    leading: SocialAvatar(
                                      api: widget.api,
                                      user: row,
                                      size: 48,
                                    ),
                                    title: AppText('${row['name']}'),
                                    subtitle: AppText('@${row['username']}'),
                                    trailing: IconButton(
                                      tooltip: 'حذف نشان'.translate(context),
                                      onPressed: busy
                                          ? null
                                          : () => remove(
                                              'author',
                                              number(row['id']),
                                            ),
                                      icon: const Icon(Icons.bookmark),
                                    ),
                                    onTap: () => socialPush(
                                      context,
                                      ProfilePage(
                                        api: widget.api,
                                        userId: number(row['id']),
                                      ),
                                    ),
                                  ),
                                const Divider(),
                              ],
                            ],
                          ),
                        ),
                      Center(
                        child: FilledButton.icon(
                          onPressed: () => socialPush(
                            context,
                            SavedPostsPage(api: widget.api),
                          ),
                          icon: const Icon(Icons.grid_on),
                          label: AppText(
                            socialText(
                              context,
                              'نمایش پست‌های ذخیره‌شده',
                              'View saved posts',
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    ),
  );
}

class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key, required this.api});
  final SocialApi api;
  @override
  State<NotificationSettingsPage> createState() =>
      _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  Json? settings;
  String? error;
  bool busy = false;
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final s = object(await widget.api.get('/settings'));
      if (mounted)
        setState(() {
          settings = s;
          error = null;
        });
    } catch (e) {
      if (mounted) setState(() => error = '$e');
    }
  }

  Future<void> change(String key, bool value) async {
    setState(() => busy = true);
    try {
      final s = object(
        await widget.api.post('/settings', {key: value ? '1' : '0'}),
      );
      if (mounted) setState(() => settings = s);
    } catch (e) {
      if (mounted) socialError(context, e);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => SocialScaffold(
    title: socialText(context, 'تنظیمات اعلان', 'Notifications'),
    actions: [
      IconButton(
        tooltip: 'اعلان‌های دریافتی'.translate(context),
        onPressed: () =>
            socialPush(context, NotificationsPage(api: widget.api)),
        icon: const Icon(Icons.inbox_outlined),
      ),
    ],
    body: error != null
        ? SocialEmpty(error!, onRetry: load)
        : settings == null
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(24),
            children: [
              LearningHeading(socialText(context, 'حساب کاربری', 'Account')),
              Card(
                elevation: 0,
                child: SwitchListTile(
                  title: AppText(
                    socialText(context, 'پیام خصوصی', 'Direct messages'),
                  ),
                  subtitle: AppText(
                    socialText(
                      context,
                      'اعلان دریافت پیام جدید',
                      'Notify me about new messages',
                    ),
                  ),
                  value: settings!['message'] == true,
                  onChanged: busy ? null : (v) => change('message', v),
                ),
              ),
              LearningHeading(
                socialText(context, 'دنبال‌کنندگان', 'Following'),
              ),
              Card(
                elevation: 0,
                child: SwitchListTile(
                  title: AppText(
                    socialText(context, 'دنبال‌کننده جدید', 'New followers'),
                  ),
                  value: settings!['follow'] == true,
                  onChanged: busy ? null : (v) => change('follow', v),
                ),
              ),
              LearningHeading(socialText(context, 'فعالیت‌ها', 'Activity')),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: AppText(
                  socialText(context, 'پسندیدن پست‌ها', 'Post likes'),
                ),
                subtitle: AppText(
                  socialText(
                    context,
                    'وقتی کسی پست شما را می‌پسندد',
                    'When someone likes your post',
                  ),
                ),
                value: settings!['like'] == true,
                onChanged: busy ? null : (v) => change('like', v),
              ),
              const Divider(),
              AppText(
                socialText(
                  context,
                  'این تنظیمات برای اعلان‌های داخل اپ است.',
                  'These settings apply to in-app notifications.',
                ),
              ),
              if (busy) const LinearProgressIndicator(),
            ],
          ),
  );
}
