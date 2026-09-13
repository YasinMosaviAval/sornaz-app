import 'course_resource_file.dart';
import 'package:sornaz/components/app_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'social_api.dart';
import 'social_widgets.dart';
import 'social_courses.dart';
import 'social_profile.dart';
import 'course_browse.dart';
import 'learning_actions.dart';

class CourseExperience extends StatefulWidget {
  const CourseExperience({
    super.key,
    required this.api,
    required this.course,
    required this.refresh,
    required this.openLesson,
    required this.buy,
    required this.buying,
  });
  final SocialApi api;
  final Json course;
  final Future<void> Function() refresh;
  final Future<void> Function(Json) openLesson;
  final Future<void> Function() buy;
  final bool buying;
  @override
  State<CourseExperience> createState() => _CourseExperienceState();
}

class _CourseExperienceState extends State<CourseExperience> {
  int tab = 0;
  bool sending = false;
  final question = TextEditingController();
  int? parent;
  Json get c => widget.course;
  int get id => number(c['id']);
  Json get details => optionalObject(c['details']);
  String t(String fa, String en) => socialText(context, fa, en);
  @override
  void dispose() {
    question.dispose();
    super.dispose();
  }

  Future<bool> action(String name, Map<String, String> data) async {
    if (sending) return false;
    setState(() => sending = true);
    try {
      await widget.api.post('/courses/$id/actions/$name', data);
      await widget.refresh();
      return true;
    } catch (e) {
      if (mounted) socialError(context, e);
      return false;
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  Future<void> review() async {
    final input = TextEditingController();
    int? recommend;
    int score = 5;
    bool busy = false;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, change) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
          child: SizedBox(
            height:
                (MediaQuery.sizeOf(ctx).height * .85 -
                        MediaQuery.viewInsetsOf(ctx).bottom)
                    .clamp(260.0, MediaQuery.sizeOf(ctx).height),
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        ListTile(
                          leading: IconButton(
                            onPressed: busy ? null : () => Navigator.pop(ctx),
                            icon: const Icon(Icons.close),
                          ),
                          title: AppText(
                            t('نظر شما چیست؟', 'What is your review?'),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        AppText(
                          '${c['title']}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        AppText('${optionalObject(c['author'])['name'] ?? ''}'),
                        AppText(
                          '${c['category'] ?? ''} · ${c['lesson_count'] ?? 0} ${t('درس', 'lessons')}',
                        ),
                        const Divider(indent: 20, endIndent: 20),
                        AppText(
                          t(
                            'این دوره را پیشنهاد می‌کنید؟',
                            'Do you recommend this course?',
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            for (final v in [1, 0])
                              Padding(
                                padding: const EdgeInsets.all(6),
                                child: ChoiceChip(
                                  selected: recommend == v,
                                  onSelected: busy
                                      ? null
                                      : (_) => change(() => recommend = v),
                                  avatar: Icon(
                                    v == 1
                                        ? Icons.thumb_up_outlined
                                        : Icons.thumb_down_outlined,
                                  ),
                                  label: AppText(
                                    v == 1 ? t('بله', 'YES') : t('خیر', 'NO'),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            for (int i = 1; i <= 5; i++)
                              IconButton(
                                onPressed: busy
                                    ? null
                                    : () => change(() => score = i),
                                icon: Icon(
                                  i <= score ? Icons.star : Icons.star_border,
                                  color: Theme.of(ctx).colorScheme.primary,
                                ),
                              ),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: TextField(
                            controller: input,
                            maxLines: 4,
                            maxLength: 3000,
                            onChanged: (_) => change(() {}),
                            decoration: InputDecoration(
                              hintText: t(
                                'نظر خود درباره این دوره را بنویسید',
                                'Leave your review for this course',
                              ),
                              border: const OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed:
                          busy || recommend == null || input.text.trim().isEmpty
                          ? null
                          : () async {
                              change(() => busy = true);
                              final saved = await action('review', {
                                'body': input.text.trim(),
                                'score': '$score',
                                'recommend': '$recommend',
                              });
                              if (!ctx.mounted) return;
                              if (saved) {
                                Navigator.pop(ctx);
                                await showDialog<void>(
                                  context: context,
                                  builder: (d) => AlertDialog(
                                    icon: Icon(
                                      Icons.thumb_up_alt_outlined,
                                      size: 64,
                                      color: Theme.of(d).colorScheme.primary,
                                    ),
                                    title: AppText(
                                      t(
                                        'با موفقیت ثبت شد',
                                        'Successfully submitted',
                                      ),
                                    ),
                                    content: AppText(
                                      t(
                                        'از بازخورد ارزشمند شما سپاسگزاریم.',
                                        'Thank you for the valuable feedback.',
                                      ),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(d),
                                        child: AppText(t('بستن', 'Close')),
                                      ),
                                    ],
                                  ),
                                );
                              } else
                                change(() => busy = false);
                            },
                      child: AppText(t('ثبت نظر', 'Submit review')),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    // Wait for the sheet exit transition before releasing its input.
    await Future<void>.delayed(const Duration(milliseconds: 300));
    input.dispose();
  }

  Future<void> report() async {
    final input = TextEditingController();
    final value = await showDialog<String>(
      context: context,
      builder: (d) => AlertDialog(
        title: AppText(t('گزارش مشکل', 'Report an issue')),
        content: TextField(controller: input, maxLines: 4, maxLength: 3000),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(d),
            child: AppText(t('انصراف', 'Cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(d, input.text.trim()),
            child: AppText(t('ارسال', 'Send')),
          ),
        ],
      ),
    );
    if (value != null && value.isNotEmpty) {
      final ok = await action('report', {'body': value});
      if (ok && mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: AppText(t('گزارش ثبت شد.', 'Report submitted.'))),
        );
    }
    await Future<void>.delayed(const Duration(milliseconds: 300));
    input.dispose();
  }

  Future<void> schedule() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 730)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 18, minute: 0),
    );
    if (time == null) return;
    await action('schedule', {
      'starts_at': DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      ).toUtc().toIso8601String(),
    });
  }

  Future<void> share() async {
    await Clipboard.setData(
      ClipboardData(text: 'https://sornaz.com/course-market/courses/$id'),
    );
    if (mounted)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: AppText(t('لینک دوره کپی شد.', 'Course link copied.')),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final author = optionalObject(c['author']);
    final chapters = (c['curriculum'] as List?)?.map(object).toList() ?? [];
    final reviews = (c['reviews'] as List?)?.map(object).toList() ?? [];
    final questions = (c['questions'] as List?)?.map(object).toList() ?? [];
    final rating = optionalObject(c['rating']);
    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            onSubmitted: (value) => socialPush(
              context,
              CoursesPage(api: widget.api, initialQuery: value),
            ),
            decoration: InputDecoration(
              hintText: t(
                'جست‌وجوی دوره، موضوع، مدرس…',
                'Search course, topic, mentor…',
              ),
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                onPressed: () =>
                    socialPush(context, CoursesPage(api: widget.api)),
                icon: const Icon(Icons.tune),
              ),
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        if (number(details['preview_id']) > 0)
          SocialVideo(
            api: widget.api,
            path: widget.api.courseMedia(details['preview_id']),
          )
        else
          SocialImage(
            api: widget.api,
            path: c['cover_id'] == null
                ? null
                : widget.api.courseMedia(c['cover_id']),
            height: 220,
            width: double.infinity,
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    onPressed: sending
                        ? null
                        : () => action('react', {
                            'reaction': number(c['reaction']) == 1 ? '0' : '1',
                          }),
                    icon: Icon(
                      number(c['reaction']) == 1
                          ? Icons.favorite
                          : Icons.favorite_border,
                    ),
                    label: AppText('${c['likes'] ?? 0}'),
                  ),
                  TextButton.icon(
                    onPressed: () => setState(() => tab = 3),
                    icon: const Icon(Icons.chat_bubble_outline),
                    label: AppText('${questions.length}'),
                  ),
                  BookmarkButton(api: widget.api, kind: 'course', id: id),
                  AppText('${c['bookmarks'] ?? 0}'),
                  IconButton(
                    onPressed: share,
                    icon: const Icon(Icons.share_outlined),
                  ),
                ],
              ),
              AppText(
                '${c['title']}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              AppText('${author['name'] ?? ''}'),
              const SizedBox(height: 12),
              AppText(
                number(c['price']) == 0
                    ? t('رایگان', 'Free')
                    : '${c['price']} ${t('تومان', 'IRT')}',
              ),
              if (number(details['original_price']) > number(c['price']))
                AppText(
                  '${details['original_price']}',
                  style: const TextStyle(
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(child: Icon(Icons.school_outlined)),
                title: AppText('${author['name'] ?? ''}'),
                subtitle: AppText(
                  '${c['students'] ?? 0} ${t('هنرجو', 'students')} · ${c['lesson_count'] ?? 0} ${t('درس', 'lessons')} · ★ ${rating['average'] ?? 0} (${rating['count'] ?? 0})',
                ),
                onTap: () => socialPush(
                  context,
                  ProfilePage(api: widget.api, userId: number(author['id'])),
                ),
              ),
              Row(
                children: [
                  for (int i = 0; i < 4; i++)
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => tab = i),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: tab == i
                                    ? Theme.of(context).colorScheme.onSurface
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                          ),
                          child: AppText(
                            [
                              t('درس‌ها', 'Courses'),
                              t('منابع', 'Review'),
                              t('درباره', 'About'),
                              t('پرسش‌وپاسخ', 'Q&A'),
                            ][i],
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: tab == i
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              if (tab == 0) ...[
                for (final chapter in chapters)
                  Card(
                    margin: const EdgeInsets.only(bottom: 2),
                    child: ExpansionTile(
                      title: AppText('${chapter['title']}'),
                      subtitle: AppText(
                        '${(chapter['lessons'] as List).length} ${t('درس', 'lessons')}',
                      ),
                      children: [
                        for (final lesson in objects(chapter['lessons']))
                          ListTile(
                            title: AppText('${lesson['title']}'),
                            leading: Icon(
                              c['access'] == true
                                  ? Icons.play_circle_outline
                                  : Icons.lock_outline,
                            ),
                            trailing: lesson['locked'] == true
                                ? const Icon(Icons.lock)
                                : null,
                            onTap: c['access'] == true
                                ? () => widget.openLesson(lesson)
                                : null,
                          ),
                      ],
                    ),
                  ),
                Wrap(
                  spacing: 8,
                  children: [
                    TextButton.icon(
                      onPressed: sending
                          ? null
                          : () => action('react', {'reaction': '1'}),
                      icon: const Icon(Icons.thumb_up_outlined),
                      label: AppText(t('پسندیدن', 'Like')),
                    ),
                    TextButton.icon(
                      onPressed: sending
                          ? null
                          : () => action('react', {'reaction': '-1'}),
                      icon: const Icon(Icons.thumb_down_outlined),
                      label: AppText(t('نپسندیدن', 'Dislike')),
                    ),
                    TextButton.icon(
                      onPressed: report,
                      icon: const Icon(Icons.flag_outlined),
                      label: AppText(t('گزارش مشکل', 'Report an issue')),
                    ),
                    TextButton.icon(
                      onPressed: share,
                      icon: const Icon(Icons.share_outlined),
                      label: AppText(t('اشتراک‌گذاری', 'Share')),
                    ),
                  ],
                ),
                AppText(
                  t('دوره‌های مرتبط', 'Related courses'),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                for (final row in (c['related'] as List? ?? []).map(object))
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: CourseCard(
                      api: widget.api,
                      course: row,
                      onTap: () => socialPush(
                        context,
                        CourseDetailPage(
                          api: widget.api,
                          id: number(row['id']),
                        ),
                      ),
                    ),
                  ),
                Card(
                  child: ListTile(
                    title: AppText('★ ${rating['average'] ?? 0}'),
                    subtitle: AppText(
                      '${rating['count'] ?? 0} ${t('نظر', 'reviews')}',
                    ),
                    trailing: IconButton(
                      onPressed: review,
                      icon: const Icon(Icons.edit_outlined),
                    ),
                  ),
                ),
              ],
              if (tab == 1) ...[
                AppText(
                  t(
                    'منابع و فایل‌های قابل دانلود',
                    'Resources & downloadable files',
                  ),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                if (c['access'] != true)
                  AppText(
                    t(
                      'برای مشاهده منابع ابتدا دوره را تهیه کنید.',
                      'Enroll to access course resources.',
                    ),
                  ),
                for (final r in (c['resources'] as List? ?? []).map(object))
                  if (number(r['media_id']) > 0)
                    CourseResourceFile(
                      api: widget.api,
                      courseId: id,
                      resource: r,
                    )
                  else
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.description_outlined),
                        title: AppText('${r['title']}'),
                        subtitle: AppText('${r['type'] ?? ''}'),
                        trailing: const Icon(Icons.open_in_new),
                        onTap: () async {
                          final url = Uri.tryParse('${r['url'] ?? ''}');
                          if (url != null && url.scheme == 'https')
                            await launchUrl(
                              url,
                              mode: LaunchMode.externalApplication,
                            );
                        },
                      ),
                    ),
                if (c['access'] == true)
                  DownloadCourseButton(api: widget.api, courseId: id),
              ],
              if (tab == 2) ...[
                AppText(
                  t('خلاصه', 'Summary'),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                AppText('${chapters.length} ${t('فصل', 'sections')}'),
                AppText('${c['lesson_count'] ?? 0} ${t('درس', 'lectures')}'),
                AppText(
                  '${(number(c['duration_seconds']) / 3600).toStringAsFixed(1)} ${t('ساعت', 'hours')}',
                ),
                if (details['language'] != null)
                  AppText('${details['language']}'),
                const SizedBox(height: 16),
                AppText(
                  t('توضیحات', 'Description'),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                AppText('${c['description']}', textAlign: TextAlign.justify),
                if (details['summary'] != null)
                  AppText(
                    '${socialText(context, 'fa', 'en') == 'en' ? details['summary_en'] ?? details['summary'] : details['summary']}',
                    textAlign: TextAlign.justify,
                  ),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText(
                          t(
                            'زمان یادگیری را برنامه‌ریزی کنید',
                            'Schedule learning time',
                          ),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        AppText(
                          t(
                            'برای یادگیری این دوره زمان مشخصی انتخاب کنید.',
                            'Choose a time to study this course.',
                          ),
                        ),
                        if (optionalObject(c['schedule'])['starts_at'] != null)
                          AppText(
                            '${optionalObject(c['schedule'])['starts_at']}',
                          ),
                        FilledButton(
                          onPressed: schedule,
                          child: AppText(t('شروع کنید', 'Get started')),
                        ),
                      ],
                    ),
                  ),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: AppText(t('مدرس دوره', 'Course instructor')),
                  subtitle: AppText(
                    '${author['name'] ?? ''}\n${author['bio'] ?? ''}',
                  ),
                  trailing: TextButton(
                    onPressed: () => socialPush(
                      context,
                      ProfilePage(
                        api: widget.api,
                        userId: number(author['id']),
                      ),
                    ),
                    child: AppText(t('مشاهده پروفایل', 'View profile')),
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: AppText(
                        t('نظرات', 'Reviews'),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    TextButton(
                      onPressed: review,
                      child: AppText(t('ثبت نظر', 'Write a review')),
                    ),
                  ],
                ),
                if (reviews.isEmpty)
                  AppText(t('هنوز نظری ثبت نشده است.', 'No reviews yet.')),
                for (final r in reviews)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const CircleAvatar(
                      child: Icon(Icons.person_outline),
                    ),
                    title: AppText('${r['author']} · ★ ${r['score']}'),
                    subtitle: AppText('${r['body']}'),
                    trailing: Icon(
                      number(r['recommend']) == 1
                          ? Icons.thumb_up_outlined
                          : Icons.thumb_down_outlined,
                    ),
                  ),
              ],
              if (tab == 3) ...[
                if (questions.isEmpty)
                  AppText(
                    t('اولین پرسش را مطرح کنید.', 'Ask the first question.'),
                  ),
                for (final q in questions)
                  Padding(
                    padding: EdgeInsetsDirectional.only(
                      start: q['parent_id'] == null ? 0 : 24,
                    ),
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const CircleAvatar(
                        child: Icon(Icons.person_outline),
                      ),
                      title: AppText('${q['author']}'),
                      subtitle: AppText('${q['body']}'),
                      onTap: () => setState(() => parent = number(q['id'])),
                    ),
                  ),
                if (parent != null)
                  InputChip(
                    label: AppText(
                      t('در حال پاسخ به پرسش', 'Replying to a question'),
                    ),
                    onDeleted: () => setState(() => parent = null),
                  ),
                TextField(
                  controller: question,
                  maxLength: 3000,
                  minLines: 1,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: t('پرسشی مطرح کنید…', 'Ask something…'),
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      onPressed: sending
                          ? null
                          : () async {
                              if (question.text.trim().isEmpty) return;
                              final ok = await action('question', {
                                'body': question.text.trim(),
                                'parent_id': '${parent ?? 0}',
                              });
                              if (ok && mounted) {
                                question.clear();
                                setState(() => parent = null);
                              }
                            },
                      icon: const Icon(Icons.send_outlined),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              if (c['access'] != true)
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: widget.buying ? null : widget.buy,
                    child: AppText(
                      widget.buying
                          ? t('در حال اتصال…', 'Connecting…')
                          : t('ثبت‌نام در دوره', 'Enroll'),
                    ),
                  ),
                ),
              if (tab == 0) ...[
                for (int score = 5; score >= 1; score--)
                  Row(
                    children: [
                      AppText('$score ★'),
                      const SizedBox(width: 10),
                      Expanded(
                        child: LinearProgressIndicator(
                          value:
                              ((c['rating_distribution'] as List? ?? [])
                                          .where(
                                            (row) =>
                                                number(row['score']) == score,
                                          )
                                          .fold<int>(
                                            0,
                                            (sum, row) =>
                                                sum + number(row['count']),
                                          ) /
                                      (number(rating['count']) == 0
                                          ? 1
                                          : number(rating['count'])))
                                  .clamp(0.0, 1.0),
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                  ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    for (final direction in ['previous', 'next'])
                      OutlinedButton(
                        onPressed: c['${direction}_id'] == null
                            ? null
                            : () => socialPush(
                                context,
                                CourseDetailPage(
                                  api: widget.api,
                                  id: number(c['${direction}_id']),
                                ),
                              ),
                        child: AppText(
                          direction == 'previous'
                              ? t('قبلی', 'Previous')
                              : t('بعدی', 'Next'),
                        ),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 20),
            ],
          ),
        ),
      ],
    );
  }
}
