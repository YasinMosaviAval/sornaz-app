import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sornaz/components/home_top_bar.dart';
import 'package:sornaz/components/main_tabs.dart';
import 'package:sornaz/components/join_community.dart';
import 'package:sornaz/screens/Authentication/providers/auth_session.dart';
import 'package:sornaz/screens/Home/ui/components/app_drawer.dart';

import 'social_api.dart';
import 'social_direct.dart';
import 'social_widgets.dart';

/// Uses the existing conversation implementation as the release's third tab.
class ChatTabPage extends StatelessWidget {
  const ChatTabPage({super.key});

  @override
  Widget build(BuildContext context) {
    if (MainTabsScope.maybeOf(context) == null) {
      return const MainTabs(initialIndex: 2, initialChild: ChatTabPage());
    }
    final token = context.watch<AuthSession>().token;
    if (token == null || token.isEmpty) {
      return SocialScaffold(
        tabIndex: 2,
        title: socialText(context, 'گفتگو', 'Conversations'),
        appBar: const HomeTopBar(),
        drawer: const AppDrawer(),
        body: const JoinCommunity(),
      );
    }
    return _ActiveChat(key: ValueKey(token), token: token);
  }
}

class _ActiveChat extends StatefulWidget {
  const _ActiveChat({super.key, required this.token});
  final String token;

  @override
  State<_ActiveChat> createState() => _ActiveChatState();
}

class _ActiveChatState extends State<_ActiveChat> {
  late final SocialApi api = SocialApi(widget.token);

  @override
  void dispose() {
    api.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => DirectPage(api: api, tabIndex: 2);
}
