import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sornaz/screens/Authentication/providers/auth_session.dart';
import 'package:sornaz/components/bottom_nav.dart';
import 'social_api.dart';
import 'social_widgets.dart';
import 'social_courses.dart';

class CourseCatalogPage extends StatelessWidget {
  const CourseCatalogPage({super.key});
  @override
  Widget build(BuildContext context) {
    final token = context.watch<AuthSession?>()?.token ?? '';
    return _Catalog(key: ValueKey(token), token: token);
  }
}

class _Catalog extends StatefulWidget {
  const _Catalog({super.key, required this.token});
  final String token;
  @override
  State<_Catalog> createState() => _CatalogState();
}

class _CatalogState extends State<_Catalog> {
  late final api = SocialApi(widget.token);
  @override
  void dispose() {
    api.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SocialScaffold(
    title: socialText(context, 'دوره‌ها', 'Courses'),
    body: CoursesBody(api: api),
    bottom: const BottomNavBarWidget(selectedIndex: 2),
  );
}
