import 'package:sornaz/components/bottom_nav.dart';
import 'course_metadata_editor.dart';
import 'package:sornaz/helpers/app_translations.dart';
import 'package:sornaz/components/app_text.dart';
import 'course_browse.dart';
import 'course_experience.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'social_api.dart';
import 'social_widgets.dart';
import 'social_edit_dialog.dart';
import 'learning_actions.dart';

class CoursesPage extends StatelessWidget {
  const CoursesPage({
    super.key,
    required this.api,
    this.mode = 'catalog',
    this.initialQuery = '',
  });
  final SocialApi api;
  final String mode;
  final String initialQuery;
  @override
  Widget build(BuildContext context) => SocialScaffold(
    title: mode == 'manage'
        ? 'مدیریت دوره‌ها'
        : mode == 'library'
        ? 'خریدهای من'
        : 'دوره‌های آموزشی',
    body: CoursesBody(api: api, initialMode: mode, initialQuery: initialQuery),
  );
}

class CoursesBody extends StatefulWidget {
  const CoursesBody({
    super.key,
    required this.api,
    this.owner,
    this.embedded = false,
    this.initialMode = 'catalog',
    this.initialQuery = '',
  });
  final SocialApi api;
  final int? owner;
  final bool embedded;
  final String initialMode;
  final String initialQuery;
  @override
  State<CoursesBody> createState() => _CoursesBodyState();
}

class _CoursesBodyState extends State<CoursesBody> {
  List<Json>? items;
  String? error;
  late String mode = widget.initialMode;
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final rows = objects(
        await widget.api.get(
          '/courses?mode=$mode${widget.owner == null ? '' : '&owner=${widget.owner}'}',
        ),
      );
      if (mounted)
        setState(() {
          items = rows;
          error = null;
        });
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    if (mode == 'catalog' && items != null)
      return CourseBrowse(
        initialQuery: widget.initialQuery,
        api: widget.api,
        items: items!,
        refresh: load,
        embedded: widget.embedded,
        open: (row) => socialPush(
          context,
          CourseDetailPage(api: widget.api, id: number(row['id'])),
        ),
      );
    final children = <Widget>[
      if (widget.owner == null)
        Padding(
          padding: const EdgeInsets.all(16),
          child: Wrap(
            spacing: 8,
            children: [
              for (final m in [
                ('catalog', 'فروشگاه'),
                ('library', 'خریدهای من'),
                ('manage', 'دوره‌های من'),
              ])
                ChoiceChip(
                  label: AppText(m.$2),
                  selected: mode == m.$1,
                  onSelected: (_) {
                    setState(() {
                      mode = m.$1;
                      items = null;
                    });
                    load();
                  },
                ),
            ],
          ),
        ),
      if (mode == 'manage')
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: FilledButton.icon(
            onPressed: () async {
              await socialPush(context, CourseEditorPage(api: widget.api));
              if (mounted) load();
            },
            icon: const Icon(Icons.add),
            label: const AppText('ساخت دوره جدید'),
          ),
        ),
      if (error != null)
        SocialEmpty(error!, onRetry: load)
      else if (items == null)
        const Padding(
          padding: EdgeInsets.all(32),
          child: Center(child: CircularProgressIndicator()),
        )
      else if (items!.isEmpty)
        const SocialEmpty('هنوز دوره‌ای در این بخش نیست.')
      else
        for (final c in items!)
          Card(
            clipBehavior: Clip.antiAlias,
            margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: InkWell(
              onTap: () async {
                await socialPush(
                  context,
                  mode == 'manage'
                      ? CourseEditorPage(api: widget.api, id: number(c['id']))
                      : CourseDetailPage(api: widget.api, id: number(c['id'])),
                );
                if (mounted) load();
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SocialImage(
                    api: widget.api,
                    path: c['cover_id'] == null
                        ? null
                        : widget.api.courseMedia(c['cover_id']),
                    height: 190,
                    width: double.infinity,
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (mode == 'manage')
                          Chip(
                            label: AppText(
                              c['status'] == 'published'
                                  ? 'منتشرشده'
                                  : 'پیش‌نویس',
                            ),
                          ),
                        AppText(
                          '${c['title']}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        AppText(
                          '${c['description']}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: AppText(
                                number(c['price']) == 0
                                    ? 'رایگان'
                                    : '${c['price']} تومان',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            AppText(
                              mode == 'manage' ? 'ویرایش دوره' : 'مشاهده دوره',
                            ),
                            const Icon(Icons.chevron_right),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
      const SizedBox(height: 80),
    ];
    if (widget.embedded) return Column(children: children);
    return RefreshIndicator(
      onRefresh: load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: children,
      ),
    );
  }
}

class CourseDetailPage extends StatefulWidget {
  const CourseDetailPage({super.key, required this.api, required this.id});
  final SocialApi api;
  final int id;
  @override
  State<CourseDetailPage> createState() => _CourseDetailPageState();
}

class _CourseDetailPageState extends State<CourseDetailPage>
    with WidgetsBindingObserver {
  Json? course;
  String? error;
  bool buying = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) load();
  }

  Future<void> load() async {
    try {
      final c = object(await widget.api.get('/courses/${widget.id}'));
      if (mounted)
        setState(() {
          course = c;
          error = null;
        });
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    }
  }

  Future<void> openLesson(Json lesson) async {
    if (lesson['locked'] == true) {
      final result = await showDialog<List<String>>(
        context: context,
        builder: (_) => const SocialEditDialog(
          title: 'رمز اختصاصی درس',
          labels: ['رمز درس'],
          values: [''],
          passwordOnly: true,
        ),
      );
      if (result == null || !mounted) return;
      try {
        final data = object(
          await widget.api.post(
            '/courses/${widget.id}/lessons/${lesson['post_id']}/unlock',
            {'password': result.first},
          ),
        );
        if (mounted) setState(() => course = data);
      } catch (e) {
        if (mounted) socialError(context, e);
      }
      return;
    }
    await socialPush(
      context,
      LessonPage(
        api: widget.api,
        courseId: widget.id,
        lesson: lesson,
        files: objects(course!['files']),
      ),
    );
  }

  Future<void> buy() async {
    setState(() => buying = true);
    try {
      final result = object(await widget.api.post('/courses/${widget.id}/buy'));
      final url = '${result['redirectUrl']}';
      if (url.startsWith('/')) {
        await load();
      } else {
        final target = Uri.parse(url);
        if (target.scheme != 'https' ||
            !['www.zarinpal.com', 'sandbox.zarinpal.com'].contains(target.host))
          throw const SocialException('آدرس درگاه معتبر نیست.');
        if (!await launchUrl(target, mode: LaunchMode.externalApplication))
          throw const SocialException('درگاه باز نشد.');
      }
    } catch (e) {
      if (mounted) socialError(context, e);
    } finally {
      if (mounted) setState(() => buying = false);
    }
  }

  @override
  Widget build(BuildContext context) => SocialScaffold(
    title: socialText(context, 'دوره آموزشی', 'Course'),
    bottom: const BottomNavBarWidget(selectedIndex: 2),
    actions: [BookmarkButton(api: widget.api, kind: 'course', id: widget.id)],
    body: error != null
        ? SocialEmpty(error!, onRetry: load)
        : course == null
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: load,
            child: CourseExperience(
              api: widget.api,
              course: course!,
              refresh: load,
              openLesson: openLesson,
              buy: buy,
              buying: buying,
            ),
          ),
  );
}

class LessonPage extends StatelessWidget {
  const LessonPage({
    super.key,
    required this.api,
    required this.lesson,
    required this.files,
    this.courseId,
  });
  final SocialApi api;
  final Json lesson;
  final List<Json> files;
  final int? courseId;
  @override
  Widget build(BuildContext context) => SocialScaffold(
    title: '${lesson['title']}',
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        if ('${lesson['text']}'.isNotEmpty) AppText('${lesson['text']}'),
        const SizedBox(height: 20),
        for (final id in lesson['media'] as List) ...[
          if (files.any(
            (f) =>
                number(f['id']) == number(id) &&
                '${f['mime']}'.startsWith('video/'),
          ))
            SocialVideo(
              api: api,
              path: api.courseMedia(id),
              title: '${lesson['title']}',
            )
          else
            SocialImage(
              api: api,
              path: api.courseMedia(id),
              width: double.infinity,
              fit: BoxFit.contain,
            ),
          const SizedBox(height: 20),
        ],
        if (courseId != null)
          LessonProgressControl(
            api: api,
            courseId: courseId!,
            postId: number(lesson['post_id']),
          ),
      ],
    ),
  );
}

class CourseEditorPage extends StatefulWidget {
  const CourseEditorPage({super.key, required this.api, this.id});
  final SocialApi api;
  final int? id;
  @override
  State<CourseEditorPage> createState() => _CourseEditorPageState();
}

class _CourseEditorPageState extends State<CourseEditorPage> {
  final title = TextEditingController(),
      description = TextEditingController(),
      price = TextEditingController(text: '0');
  Json course = {
    'id': 0,
    'version': 0,
    'cover_id': null,
    'curriculum': <Json>[],
    'status': 'draft',
  };
  bool loading = false, busy = false, dirty = false;
  String? error;
  List<Json> get chapters => objects(course['curriculum']);
  @override
  void initState() {
    super.initState();
    for (final c in [title, description, price]) {
      c.addListener(changed);
    }
    if (widget.id != null) load();
  }

  void changed() {
    if (mounted && !loading) setState(() => dirty = true);
  }

  @override
  void dispose() {
    title.dispose();
    description.dispose();
    price.dispose();
    super.dispose();
  }

  Future<void> load() async {
    setState(() => loading = true);
    try {
      final result = object(await widget.api.get('/courses/${widget.id}/edit'));
      if (!mounted) return;
      course = result;
      title.text = '${result['title']}';
      description.text = '${result['description']}';
      price.text = '${result['price']}';
      setState(() => dirty = false);
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Json payload(String status) => {
    ...course,
    'title': title.text.trim(),
    'description': description.text.trim(),
    'price': price.text.trim(),
    'status': status,
  };
  Future<void> save(String status) async {
    if (title.text.trim().isEmpty || int.tryParse(price.text) == null) {
      socialError(
        context,
        const SocialException('عنوان و قیمت صحیح وارد کنید.'),
      );
      return;
    }
    setState(() => busy = true);
    try {
      final id = number(course['id']);
      final result = object(
        await widget.api.post('/courses${id == 0 ? '' : '/$id'}', {
          'payload': jsonEncode(payload(status)),
        }),
      );
      if (mounted)
        setState(() {
          course = result;
          dirty = false;
        });
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: AppText(
              status == 'published'
                  ? 'دوره برای فروش منتشر شد.'
                  : 'پیش‌نویس ذخیره شد.',
            ),
          ),
        );
    } catch (e) {
      if (mounted) socialError(context, e);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> upload({Json? lesson}) async {
    if (title.text.trim().isEmpty) {
      socialError(
        context,
        const SocialException('ابتدا عنوان دوره را وارد کنید.'),
      );
      return;
    }
    final selected = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: lesson == null
          ? ['jpg', 'jpeg', 'png', 'webp']
          : ['jpg', 'jpeg', 'png', 'webp', 'mp4', 'webm'],
    );
    if (selected == null || !mounted) return;
    setState(() => busy = true);
    try {
      if (number(course['id']) == 0) {
        final minimal = {...payload('draft'), 'curriculum': <Json>[]};
        final saved = object(
          await widget.api.post('/courses', {'payload': jsonEncode(minimal)}),
        );
        course['id'] = saved['id'];
        course['version'] = saved['version'];
      }
      final result = await widget.api.upload(
        selected.files.single,
        courseId: number(course['id']),
      );
      if (!mounted) return;
      setState(() {
        if (lesson == null) {
          course['cover_id'] = result['id'];
        } else {
          (lesson['media'] as List).add(result['id']);
        }
        dirty = true;
      });
    } catch (e) {
      if (mounted) socialError(context, e);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> addChapter() async {
    final result = await showDialog<List<String>>(
      context: context,
      builder: (_) => const SocialEditDialog(
        title: 'فصل جدید',
        labels: ['عنوان فصل'],
        values: [''],
      ),
    );
    if (result == null || !mounted) return;
    setState(() {
      (course['curriculum'] as List).add({
        'title': result.first,
        'lessons': <Json>[],
      });
      dirty = true;
    });
  }

  Future<void> editLesson(Json chapter, [Json? lesson]) async {
    final values = await showDialog<List<String>>(
      context: context,
      builder: (_) => SocialEditDialog(
        title: lesson == null ? 'افزودن درس' : 'ویرایش درس',
        labels: const [
          'عنوان درس',
          'متن و توضیحات',
          'رمز اختصاصی (خالی = بدون تغییر)',
        ],
        values: [
          lesson?['title'] ?? '',
          lesson?['text'] ?? '',
          lesson?['password'] ?? '',
        ],
      ),
    );
    if (values == null || !mounted) return;
    final result = {
      'title': values[0],
      'text': values[1],
      'media': lesson?['media'] ?? <int>[],
      'password': values[2],
    };
    setState(() {
      if (lesson == null) {
        (chapter['lessons'] as List).add(result);
      } else {
        lesson.addAll(result);
      }
      dirty = true;
    });
  }

  void move(List items, int index, int delta) {
    final target = index + delta;
    if (target < 0 || target >= items.length) return;
    setState(() {
      final item = items.removeAt(index);
      items.insert(target, item);
      dirty = true;
    });
  }

  Future<void> remove(List items, int index) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const AppText('این بخش حذف شود؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const AppText('انصراف'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const AppText('حذف'),
          ),
        ],
      ),
    );
    if (yes == true && mounted)
      setState(() {
        items.removeAt(index);
        dirty = true;
      });
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !busy && !dirty,
    onPopInvokedWithResult: (didPop, _) async {
      if (didPop || busy) return;
      final leave = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const AppText('تغییرات ذخیره نشده‌اند'),
          content: const AppText('بدون ذخیره خارج می‌شوید؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const AppText('ادامه ویرایش'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const AppText('خروج'),
            ),
          ],
        ),
      );
      if (leave == true && context.mounted) {
        setState(() => dirty = false);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) Navigator.pop(context);
        });
      }
    },
    child: SocialScaffold(
      title: 'استودیوی ساخت دوره',
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
          ? SocialEmpty(error!, onRetry: load)
          : AbsorbPointer(
              absorbing: busy,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  if (number(course['id']) > 0)
                    OutlinedButton.icon(
                      onPressed: () => socialPush(
                        context,
                        CourseMetadataEditor(
                          api: widget.api,
                          id: number(course['id']),
                        ),
                      ),
                      icon: const Icon(Icons.tune),
                      label: AppText(
                        socialText(
                          context,
                          'جزئیات تکمیلی دوره',
                          'Course details',
                        ),
                      ),
                    ),
                  TextField(
                    controller: title,
                    maxLength: 180,
                    decoration: InputDecoration(
                      labelText: 'عنوان دوره'.translate(context),
                    ),
                  ),
                  TextField(
                    controller: description,
                    maxLength: 20000,
                    maxLines: 4,
                    decoration: InputDecoration(
                      labelText: 'معرفی دوره و پیش‌نیازها'.translate(context),
                    ),
                  ),
                  TextField(
                    controller: price,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'قیمت به تومان (صفر = رایگان)'.translate(
                        context,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (course['cover_id'] != null)
                    SocialImage(
                      api: widget.api,
                      path: widget.api.courseMedia(course['cover_id']),
                      height: 150,
                      width: double.infinity,
                    ),
                  OutlinedButton.icon(
                    onPressed: () => upload(),
                    icon: const Icon(Icons.image_outlined),
                    label: const AppText('انتخاب تصویر جلد'),
                  ),
                  const Divider(height: 32),
                  const AppText(
                    'فصل‌ها و درس‌ها',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                  ),
                  for (
                    var ci = 0;
                    ci < (course['curriculum'] as List).length;
                    ci++
                  )
                    chapterWidget(object(course['curriculum'][ci]), ci),
                  OutlinedButton.icon(
                    onPressed: addChapter,
                    icon: const Icon(Icons.add),
                    label: const AppText('افزودن فصل'),
                  ),
                  const SizedBox(height: 24),
                  if (busy) ...[
                    const LinearProgressIndicator(),
                    const AppText('در حال ذخیره یا آپلود…'),
                  ],
                  AppText(
                    dirty ? 'تغییرات ذخیره نشده' : 'اطلاعات ذخیره شده',
                    style: const TextStyle(fontSize: 12),
                  ),
                  OutlinedButton(
                    onPressed: busy ? null : () => save('draft'),
                    child: const AppText('ذخیره پیش‌نویس'),
                  ),
                  FilledButton(
                    onPressed: busy ? null : () => save('published'),
                    child: const AppText('انتشار برای فروش'),
                  ),
                ],
              ),
            ),
    ),
  );
  Widget chapterWidget(Json chapter, int ci) => Card(
    margin: const EdgeInsets.symmetric(vertical: 12),
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText(
            '${ci + 1}. ${chapter['title']}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Row(
            children: [
              IconButton(
                tooltip: 'بالاتر'.translate(context),
                onPressed: () => move(course['curriculum'], ci, -1),
                icon: const Icon(Icons.arrow_upward),
              ),
              IconButton(
                tooltip: 'پایین‌تر'.translate(context),
                onPressed: () => move(course['curriculum'], ci, 1),
                icon: const Icon(Icons.arrow_downward),
              ),
              const Spacer(),
              IconButton(
                tooltip: 'حذف فصل'.translate(context),
                onPressed: () => remove(course['curriculum'], ci),
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
          for (var li = 0; li < (chapter['lessons'] as List).length; li++)
            lessonWidget(chapter, object(chapter['lessons'][li]), li),
          TextButton.icon(
            onPressed: () => editLesson(chapter),
            icon: const Icon(Icons.add),
            label: const AppText('افزودن درس'),
          ),
        ],
      ),
    ),
  );
  Widget lessonWidget(Json chapter, Json lesson, int li) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(
      border: Border.all(color: Theme.of(context).dividerColor),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: AppText('${lesson['title']}'),
          subtitle: AppText(
            '${lesson['text']}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          onTap: () => editLesson(chapter, lesson),
        ),
        Wrap(
          children: [
            IconButton(
              tooltip: 'بالاتر'.translate(context),
              onPressed: () => move(chapter['lessons'], li, -1),
              icon: const Icon(Icons.arrow_upward),
            ),
            IconButton(
              tooltip: 'پایین‌تر'.translate(context),
              onPressed: () => move(chapter['lessons'], li, 1),
              icon: const Icon(Icons.arrow_downward),
            ),
            IconButton(
              tooltip: 'حذف درس'.translate(context),
              onPressed: () => remove(chapter['lessons'], li),
              icon: const Icon(Icons.delete_outline),
            ),
            TextButton.icon(
              onPressed: () => upload(lesson: lesson),
              icon: const Icon(Icons.attach_file),
              label: const AppText('آپلود تصویر / ویدیو'),
            ),
          ],
        ),
        for (final id in List.of(lesson['media']))
          InputChip(
            label: AppText('فایل $id'),
            onDeleted: () {
              setState(() {
                (lesson['media'] as List).remove(id);
                dirty = true;
              });
            },
          ),
      ],
    ),
  );
}
