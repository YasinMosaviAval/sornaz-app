import 'package:provider/provider.dart';
import 'package:sornaz/screens/Authentication/providers/auth_session.dart';
import '../Site/panel_api.dart';
import '../Site/panel_resource_page.dart';
import 'package:sornaz/helpers/user_facing_error.dart';
import 'package:sornaz/helpers/app_translations.dart';
import 'package:sornaz/components/app_text.dart';
import 'package:flutter/material.dart';
import 'social_api.dart';
import 'social_widgets.dart';
import 'social_profile.dart';
import 'social_courses.dart';
import 'social_activity.dart';
import 'learning_widgets.dart';

/// The same native account page is used by bottom navigation and the admin drawer.
class AccountDashboardBody extends StatefulWidget {
  const AccountDashboardBody({super.key, required this.api, this.accountApi});
  final PanelApi? accountApi;
  final SocialApi api;
  @override
  State<AccountDashboardBody> createState() => _AccountDashboardBodyState();
}

class _AccountDashboardBodyState extends State<AccountDashboardBody> {
  late final accountApi =
      widget.accountApi ??
      PanelApi(
        widget.api.token,
        isCurrentAccount: () =>
            mounted &&
            (context.read<AuthSession?>()?.token ?? widget.api.token) ==
                widget.api.token,
      );
  Json? section;
  Object? error;
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final catalog = objects((await accountApi.get(''))['sections']);
      final account = catalog.firstWhere((item) => item['key'] == 'account');
      if (mounted)
        setState(() {
          section = account;
          error = null;
        });
    } catch (failure) {
      if (mounted) setState(() => error = failure);
    }
  }

  @override
  void dispose() {
    if (widget.accountApi == null) accountApi.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => section != null
      ? PanelResourcePage(api: accountApi, section: section!, embedded: true)
      : error != null
      ? SocialEmpty(
          socialText(
            context,
            'اطلاعات حساب دریافت نشد. دوباره تلاش کنید.',
            'Could not load your account. Please retry.',
          ),
          onRetry: load,
        )
      : const Center(child: CircularProgressIndicator());
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
      if (mounted) setState(() => error = userFacingError(e));
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
      if (mounted) setState(() => error = userFacingError(e));
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
        : ListTileTheme.merge(
            titleTextStyle: Theme.of(context).textTheme.bodyMedium,
            subtitleTextStyle: Theme.of(context).textTheme.bodySmall,
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    socialText(context, 'حساب کاربری', 'Account'),
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
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
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    socialText(context, 'دنبال‌کنندگان', 'Following'),
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
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
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    socialText(context, 'فعالیت‌ها', 'Activity'),
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
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
          ),
  );
}
