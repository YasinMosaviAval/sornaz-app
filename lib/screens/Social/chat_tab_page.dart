import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../components/home_top_bar.dart';
import '../../components/main_tabs.dart';
import '../../components/join_community.dart';
import '../Authentication/providers/auth_session.dart';
import '../Home/ui/components/app_drawer.dart';
import 'social_api.dart';
import 'social_direct.dart';
import 'social_widgets.dart';

/// The release's third destination; no development feed is instantiated here.
class ChatTabPage extends StatelessWidget {
  const ChatTabPage({super.key});
  @override
  Widget build(BuildContext context) {
    if (MainTabsScope.maybeOf(context) == null) {
      return const MainTabs(initialIndex: 2, initialChild: ChatTabPage());
    }
    final auth = context.watch<AuthSession?>();
    final token = auth?.isAuthenticated == true ? auth!.token : null;
    if (token == null || token.isEmpty)
      return SocialScaffold(
        tabIndex: 2,
        title: socialText(context, 'گفتگو', 'Conversations'),
        appBar: const HomeTopBar(),
        drawer: const AppDrawer(),
        body: const JoinCommunity(),
      );
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
  late final api = SocialApi(widget.token);
  @override
  void dispose() {
    api.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => DirectPage(api: api, tabIndex: 2);
}
