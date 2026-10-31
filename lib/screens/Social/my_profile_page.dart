import 'create_content_button.dart';
import '../../helpers/development_access.dart';
import 'user_panel.dart';
import 'package:sornaz/screens/Players/ui/components/music_playback_entry.dart';
import 'package:sornaz/screens/Players/services/player_settings.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sornaz/components/main_tabs.dart';
import 'package:sornaz/components/home_top_bar.dart';
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
    if (!DevelopmentAccess.watch(context)) {
      return const UserPanelPage(initialTab: 2, mainTabIndex: 5);
    }
    if (MainTabsScope.maybeOf(context) == null) {
      return MainTabs(initialIndex: 5, initialChild: this);
    }
    return MusicPlaybackEntry(
      reason: PlaybackInterruption.stageAndProfile,
      active: MainTabsScope.maybeOf(context)?.index == 5,
      child: _content(context),
    );
  }

  Widget _content(BuildContext context) {
    final auth = context.watch<AuthSession>();
    if (!auth.isAuthenticated) {
      return SocialScaffold(
        tabIndex: 5,
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
  @override
  void dispose() {
    if (widget.api == null) api.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SocialScaffold(
    tabIndex: 5,
    title: socialText(context, 'پروفایل', 'Profile'),
    appBar: HomeTopBar(
      trailingWidget: CreateContentButton(
        api: api,
        onCreated: () => setState(() => revision++),
      ),
    ),
    body: ProfileBody(key: ValueKey(revision), api: api, userId: widget.id),
  );
}
