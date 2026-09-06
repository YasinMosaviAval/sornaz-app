import 'package:flutter/material.dart';
import 'social_api.dart';
import 'social_widgets.dart';
import 'social_courses.dart';

class LearningHeading extends StatelessWidget {
  const LearningHeading(this.title, {super.key, this.onMore});
  final String title;
  final VoidCallback? onMore;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 16),
    child: Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
        if (onMore != null)
          TextButton(
            onPressed: onMore,
            child: Text(socialText(context, 'مشاهده همه', 'View all')),
          ),
      ],
    ),
  );
}

class LearningCourseTile extends StatelessWidget {
  const LearningCourseTile({
    super.key,
    required this.api,
    required this.course,
    this.trailing,
    this.onTap,
    this.showProgress = false,
  });
  final SocialApi api;
  final Json course;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool showProgress;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap:
        onTap ??
        () => socialPush(
          context,
          CourseDetailPage(api: api, id: number(course['id'])),
        ),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SocialImage(
              api: api,
              path: course['cover_id'] == null
                  ? null
                  : api.courseMedia(course['cover_id']),
              width: 80,
              height: 86,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${course['title']}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 7),
                Text(
                  showProgress
                      ? '${number(course['completed'])} / ${number(course['lesson_count'])} ${socialText(context, 'درس', 'lessons')}'
                      : number(course['price']) == 0
                      ? socialText(context, 'رایگان', 'Free')
                      : '${course['price']} ${socialText(context, 'تومان', 'IRT')}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).hintColor,
                  ),
                ),
                if (showProgress) ...[
                  const SizedBox(height: 10),
                  LinearProgressIndicator(
                    value: number(course['progress']) / 100,
                    minHeight: 5,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${number(course['progress'])}%',
                    style: const TextStyle(fontSize: 11),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    ),
  );
}
