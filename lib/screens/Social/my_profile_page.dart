import 'package:sornaz/components/app_text.dart';
import 'social_publish.dart';
import 'social_courses.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sornaz/components/main_tabs.dart';
import 'package:sornaz/components/home_top_bar.dart';
import 'package:sornaz/components/account_avatar.dart';
import 'package:sornaz/components/join_community.dart';
import 'package:sornaz/screens/Authentication/providers/auth_session.dart';
import 'social_api.dart';
import 'social_profile.dart';
import 'social_widgets.dart';

class MyProfilePage extends StatelessWidget {
  const MyProfilePage({super.key, this.api});
  final SocialApi? api;
  @override
  Widget build(BuildContext context) {
    if (MainTabsScope.maybeOf(context) == null) {
      return MainTabs(initialIndex: 4, initialChild: this);
    }
    final auth = context.watch<AuthSession>();
    if (!auth.isAuthenticated) {
      return SocialScaffold(
        tabIndex: 4,
        appBar: const HomeTopBar(),
        title: socialText(context, 'پروفایل', 'Profile'),
        body: const JoinCommunity(),
      );
    }
    return _MyProfile(
      key: ValueKey(auth.token),
      token: auth.token!,
      id: auth.user!.id,
      api: api,
    );
  }
}

class _MyProfile extends StatefulWidget {
  const _MyProfile({
    super.key,
    required this.token,
    required this.id,
    this.api,
  });
  final SocialApi? api;
  final String token;
  final int id;
  @override
  State<_MyProfile> createState() => _MyProfileState();
}

class _MyProfileState extends State<_MyProfile> {
  late final api = widget.api ?? SocialApi(widget.token);
  int revision = 0;
  Future<void> create() async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final item in [
              ('post', Icons.grid_on_outlined, 'پست جدید'),
              ('story', Icons.add_circle_outline, 'استوری جدید'),
              ('course', Icons.school_outlined, 'دوره جدید'),
            ])
              ListTile(
                leading: Icon(item.$2),
                title: AppText(item.$3),
                onTap: () => Navigator.pop(context, item.$1),
              ),
          ],
        ),
      ),
    );
    if (!mounted || choice == null) return;
    await socialPush(
      context,
      choice == 'course'
          ? CourseEditorPage(api: api)
          : PublishPage(api: api, kind: choice),
    );
    if (mounted) setState(() => revision++);
  }

  @override
  void dispose() {
    if (widget.api == null) api.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SocialScaffold(
    tabIndex: 4,
    title: socialText(context, 'پروفایل', 'Profile'),
    appBar: HomeTopBar(
      leadingWidget: Padding(
        padding: const EdgeInsets.all(8),
        child: AccountAvatar(
          avatar: context.watch<AuthSession>().user?.avatar,
          token: widget.token,
        ),
      ),
    ),
    body: ProfileBody(key: ValueKey(revision), api: api, userId: widget.id),
    floatingActionButton: FloatingActionButton(
      onPressed: create,
      tooltip: socialText(context, 'ساخت محتوا', 'Create content'),
      child: const Icon(Icons.add),
    ),
  );
}
