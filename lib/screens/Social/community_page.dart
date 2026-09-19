import 'package:flutter/material.dart';
import 'social_api.dart';
import 'social_profile.dart';

class CommunityPage extends StatelessWidget {
  const CommunityPage({super.key, required this.api});
  final SocialApi api;
  @override
  Widget build(BuildContext context) => PeoplePage(api: api, community: true);
}
