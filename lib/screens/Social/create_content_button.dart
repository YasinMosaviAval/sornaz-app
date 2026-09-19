import 'package:flutter/material.dart';
import 'social_api.dart';
import 'social_widgets.dart';
import 'social_publish.dart';
import 'social_courses.dart';

class CreateContentButton extends StatelessWidget {
  const CreateContentButton({super.key, required this.api, this.onCreated});
  final SocialApi api;
  final VoidCallback? onCreated;
  @override
  Widget build(BuildContext context) => IconButton(
    key: const ValueKey('create-content'),
    tooltip: socialText(context, 'ساخت محتوا', 'Create content'),
    icon: const Icon(Icons.add),
    onPressed: () async {
      final kind = await showModalBottomSheet<String>(
        context: context,
        builder: (c) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final item in [
                ('post', Icons.grid_on_outlined, 'پست جدید', 'New post'),
                ('story', Icons.add_circle_outline, 'استوری جدید', 'New story'),
                ('course', Icons.school_outlined, 'دوره جدید', 'New course'),
              ])
                ListTile(
                  leading: Icon(item.$2),
                  title: Text(socialText(c, item.$3, item.$4)),
                  onTap: () => Navigator.pop(c, item.$1),
                ),
            ],
          ),
        ),
      );
      if (kind == null || !context.mounted) return;
      await socialPush(
        context,
        kind == 'course'
            ? CourseEditorPage(api: api)
            : PublishPage(api: api, kind: kind),
      );
      if (context.mounted) onCreated?.call();
    },
  );
}
