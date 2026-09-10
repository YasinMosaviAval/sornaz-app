import 'package:flutter/material.dart';
import 'social_api.dart';
import 'social_widgets.dart';
import 'social_profile.dart';

class CommunityPage extends StatefulWidget {
  const CommunityPage({super.key, required this.api});
  final SocialApi api;
  @override
  State<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage> {
  late final data = widget.api.get('/community');
  @override
  Widget build(BuildContext context) => SocialScaffold(
    title: socialText(context, 'جامعه سرناز', 'Sornaz community'),
    body: FutureBuilder(
      future: data,
      builder: (context, snapshot) {
        if (snapshot.hasError) return const SocialEmpty('اطلاعات دریافت نشد.');
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());
        final people = objects(snapshot.data);
        return ListView.builder(
          itemCount: people.length,
          itemBuilder: (_, i) => ListTile(
            leading: SocialAvatar(api: widget.api, user: people[i]),
            title: Text('${people[i]['name']}'),
            onTap: () => socialPush(
              context,
              ProfilePage(api: widget.api, userId: number(people[i]['id'])),
            ),
          ),
        );
      },
    ),
  );
}
