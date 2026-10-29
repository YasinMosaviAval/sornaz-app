import 'package:flutter/material.dart';
import '../../components/app_bar.dart';
import '../../helpers/app_appearance.dart';
import '../Social/social_widgets.dart';
import 'practice_repository.dart';

class MusicPracticeManagePage extends StatefulWidget {
  const MusicPracticeManagePage({super.key, required this.repository});
  final MusicPracticeRepository repository;
  @override
  State<MusicPracticeManagePage> createState() =>
      _MusicPracticeManagePageState();
}

class _MusicPracticeManagePageState extends State<MusicPracticeManagePage> {
  PracticeJson? catalog, plans;
  String? error;
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final c = await widget.repository.catalog(manage: true),
          p = await widget.repository.request('plans');
      if (mounted) {
        setState(() {
          catalog = c;
          plans = p;
          error = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    }
  }

  List<PracticeJson> rows(String key) =>
      ((key == 'plans' ? plans : catalog)?[key] as List? ?? [])
          .map((x) => Map<String, dynamic>.from(x as Map))
          .toList();
  String title(PracticeJson row) =>
      row[Localizations.localeOf(context).languageCode == 'en'
              ? 'titleEn'
              : 'titleFa']
          .toString();
  Future<void> edit(String kind, [PracticeJson? item]) async {
    await socialPush(
      context,
      MusicPracticeEditPage(
        repository: widget.repository,
        catalog: catalog!,
        kind: kind,
        item: item,
      ),
    );
    if (mounted) await load();
  }

  Future<void> publish(String kind, PracticeJson item) async {
    try {
      await widget.repository.request('publish', {
        'kind': kind,
        'id': item['id'],
        'version': item['version'],
        'published': item['published'] != true,
      });
      if (mounted) await load();
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final caps = Map<String, dynamic>.from(
      catalog?['capabilities'] as Map? ?? {},
    );
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: SornazAppBar(
          title: socialText(context, 'مدیریت آزمون‌ها', 'Manage tests'),
          actions: [
            IconButton(
              tooltip: socialText(context, 'به‌روزرسانی', 'Refresh'),
              onPressed: load,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        body: Column(
          children: [
            TabBar(
              tabs: [
                Tab(text: socialText(context, 'بخش‌ها', 'Sections')),
                Tab(text: socialText(context, 'آزمون‌ها', 'Tests')),
                Tab(text: socialText(context, 'اشتراک‌ها', 'Subscriptions')),
              ],
            ),
            if (error != null)
              Padding(padding: const EdgeInsets.all(12), child: Text(error!)),
            if (catalog == null)
              const LinearProgressIndicator()
            else
              Expanded(
                child: TabBarView(
                  children: [
                    ListView(
                      padding: const EdgeInsets.all(12),
                      children: [
                        if (caps['create'] == true)
                          FilledButton.icon(
                            onPressed: () => edit('nodes'),
                            icon: const Icon(Icons.add),
                            label: Text(
                              socialText(context, 'افزودن بخش', 'Add section'),
                            ),
                          ),
                        for (final node in rows('nodes'))
                          ListTile(
                            title: Text(
                              '${'—' * ((node['depth'] as int) - 1)} ${title(node)}',
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  node['published'] == true
                                      ? socialText(
                                          context,
                                          'منتشرشده',
                                          'Published',
                                        )
                                      : socialText(
                                          context,
                                          'پیش‌نویس',
                                          'Draft',
                                        ),
                                ),
                                if (caps['publish'] == true &&
                                    node['canManage'] == true)
                                  TextButton.icon(
                                    onPressed: () => publish('node', node),
                                    icon: Icon(
                                      node['published'] == true
                                          ? Icons.visibility_off_outlined
                                          : Icons.publish_outlined,
                                    ),
                                    label: Text(
                                      node['published'] == true
                                          ? socialText(
                                              context,
                                              'توقف انتشار',
                                              'Unpublish',
                                            )
                                          : socialText(
                                              context,
                                              'انتشار',
                                              'Publish',
                                            ),
                                    ),
                                  ),
                              ],
                            ),
                            trailing:
                                caps['edit'] == true &&
                                    node['canManage'] == true
                                ? IconButton(
                                    tooltip: socialText(
                                      context,
                                      'ویرایش',
                                      'Edit',
                                    ),
                                    icon: const Icon(Icons.edit_outlined),
                                    onPressed: () => edit('nodes', node),
                                  )
                                : null,
                          ),
                      ],
                    ),
                    ListView(
                      padding: const EdgeInsets.all(12),
                      children: [
                        if (caps['create'] == true)
                          FilledButton.icon(
                            onPressed: () => edit('exams'),
                            icon: const Icon(Icons.add),
                            label: Text(
                              socialText(context, 'افزودن آزمون', 'Add test'),
                            ),
                          ),
                        for (final exam in rows('exams'))
                          ListTile(
                            title: Text(title(exam)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${exam['stageCount']} ${socialText(context, 'مرحله', 'stages')} · ${exam['audience']}',
                                ),
                                if (caps['publish'] == true)
                                  TextButton.icon(
                                    onPressed: () => publish('exam', exam),
                                    icon: Icon(
                                      exam['published'] == true
                                          ? Icons.visibility_off_outlined
                                          : Icons.publish_outlined,
                                    ),
                                    label: Text(
                                      exam['published'] == true
                                          ? socialText(
                                              context,
                                              'توقف انتشار',
                                              'Unpublish',
                                            )
                                          : socialText(
                                              context,
                                              'انتشار',
                                              'Publish',
                                            ),
                                    ),
                                  ),
                                if (caps['approvePlans'] == true)
                                  TextButton.icon(
                                    onPressed: () => edit('shares', exam),
                                    icon: const Icon(Icons.percent),
                                    label: Text(
                                      socialText(
                                        context,
                                        'سهم درآمد',
                                        'Revenue share',
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            trailing: caps['edit'] == true
                                ? IconButton(
                                    tooltip: socialText(
                                      context,
                                      'ویرایش',
                                      'Edit',
                                    ),
                                    icon: const Icon(Icons.edit_outlined),
                                    onPressed: () => edit('exams', exam),
                                  )
                                : null,
                          ),
                      ],
                    ),
                    ListView(
                      padding: const EdgeInsets.all(12),
                      children: [
                        if (caps['create'] == true)
                          FilledButton.icon(
                            onPressed: () => edit('plans/propose'),
                            icon: const Icon(Icons.add),
                            label: Text(
                              socialText(
                                context,
                                'پیشنهاد اشتراک',
                                'Propose subscription',
                              ),
                            ),
                          ),
                        for (final plan in rows('plans'))
                          ListTile(
                            title: Text(plan['title'].toString()),
                            subtitle: Text(
                              '${plan['amount']} ${socialText(context, 'تومان', 'toman')} · ${plan['days']} ${socialText(context, 'روز', 'days')} · ${plan['status']}',
                            ),
                            trailing: Wrap(
                              children: [
                                if (plan['teacher_id'].toString() ==
                                    '${widget.repository.userId}')
                                  IconButton(
                                    tooltip: socialText(
                                      context,
                                      'ویرایش پیشنهاد',
                                      'Edit proposal',
                                    ),
                                    icon: const Icon(Icons.edit_outlined),
                                    onPressed: () =>
                                        edit('plans/propose', plan),
                                  ),
                                if (caps['approvePlans'] == true)
                                  IconButton(
                                    tooltip: socialText(
                                      context,
                                      'تعیین سهم و تأیید',
                                      'Set share and approve',
                                    ),
                                    icon: const Icon(Icons.verified_outlined),
                                    onPressed: () =>
                                        edit('plans/approve', plan),
                                  ),
                              ],
                            ),
                          ),
                        for (final row in (plans?['revenue'] as List? ?? []))
                          ListTile(
                            title: Text('${row['amount']} IRT'),
                            subtitle: Text(
                              '${socialText(context, 'سهم ثبت‌شده', 'Recorded share')} · ${row['beneficiary']} · #${row['order_id']}',
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class MusicPracticeEditPage extends StatefulWidget {
  const MusicPracticeEditPage({
    super.key,
    required this.repository,
    required this.catalog,
    required this.kind,
    this.item,
  });
  final MusicPracticeRepository repository;
  final PracticeJson catalog;
  final String kind;
  final PracticeJson? item;
  @override
  State<MusicPracticeEditPage> createState() => _MusicPracticeEditPageState();
}

class _MusicPracticeEditPageState extends State<MusicPracticeEditPage> {
  final key = GlobalKey<FormState>();
  final fields = <String, TextEditingController>{};
  final selectedNames = <int, String>{};
  final questions = <Map<String, TextEditingController>>[];
  late int parent;
  late String engine, audience, direction, status;
  late bool published, variableRoot;
  bool saving = false;
  String? error;
  PracticeJson get old => widget.item ?? {};
  TextEditingController controller(String name, Object? initial) =>
      fields.putIfAbsent(
        name,
        () => TextEditingController(text: initial?.toString() ?? ''),
      );
  double get proposedShare {
    if (old['exam_id'] != null) {
      final exams = (widget.catalog['exams'] as List).where(
        (e) => e['id'].toString() == old['exam_id'].toString(),
      );
      if (exams.isNotEmpty) {
        return double.parse(exams.first['teacherBps'].toString()) / 100;
      }
    }
    return double.parse((old['teacher_bps'] ?? 8000).toString()) / 100;
  }

  @override
  void initState() {
    super.initState();
    final config = Map<String, dynamic>.from(old['config'] as Map? ?? {}),
        nodes = widget.catalog['nodes'] as List;
    parent =
        (old['nodeId'] ??
                old['parentId'] ??
                (old['exam_id'] == null
                    ? null
                    : int.parse(old['exam_id'].toString())) ??
                (widget.kind == 'exams' && nodes.isNotEmpty
                    ? nodes.first['id']
                    : 0))
            as int;
    engine = config['kind']?.toString() ?? 'interval';
    audience = old['audience']?.toString() ?? 'public';
    direction = config['direction']?.toString() ?? 'ascending';
    variableRoot = config['variableRoot'] == true;
    published = old['published'] == true;
    status = 'approved';
    for (final q in config['questions'] as List? ?? []) {
      addQuestion(Map<String, dynamic>.from(q as Map));
    }
  }

  void addQuestion([PracticeJson q = const {}]) {
    questions.add({
      for (final entry in <String, Object?>{
        'promptFa': q['promptFa'],
        'promptEn': q['promptEn'],
        'choices': (q['choices'] as List? ?? []).join('\n'),
        'correct': q['correct'] ?? 0,
        'beats': (q['beats'] as List? ?? [1, 1]).join(','),
        'bpm': q['bpm'] ?? 80,
      }.entries)
        entry.key: TextEditingController(text: entry.value?.toString() ?? ''),
    });
  }

  @override
  void dispose() {
    for (final c in fields.values) {
      c.dispose();
    }
    for (final q in questions) {
      for (final c in q.values) {
        c.dispose();
      }
    }
    super.dispose();
  }

  Widget input(
    String name,
    String fa,
    String en,
    Object? initial, {
    bool number = false,
    int lines = 1,
    bool required = true,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      controller: controller(name, initial),
      readOnly:
          name == 'teacherPercent' &&
          widget.kind == 'plans/approve' &&
          old['exam_id'] != null,
      keyboardType: number
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.multiline,
      maxLines: lines,
      style: Theme.of(context).textTheme.bodyMedium,
      decoration: InputDecoration(labelText: socialText(context, fa, en)),
      validator: (v) => required && (v == null || v.trim().isEmpty)
          ? socialText(
              context,
              'این فیلد الزامی است.',
              'This field is required.',
            )
          : null,
    ),
  );
  Widget dropdown(
    String label,
    String value,
    List<(String, String)> options,
    ValueChanged<String> change,
  ) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(labelText: label),
      items: [
        for (final o in options)
          DropdownMenuItem(
            value: o.$1,
            child: Text(o.$2, overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: (v) {
        if (v != null) setState(() => change(v));
      },
    ),
  );
  int integer(String name) => int.parse(fields[name]!.text.trim());
  Widget userPicker() {
    final selected = controller(
      'userIds',
      (old['userIds'] as List? ?? []).join(','),
    );
    for (final user in old['users'] as List? ?? []) {
      selectedNames.putIfAbsent(
        int.parse(user['id'].toString()),
        () => user['username'].toString(),
      );
    }
    final ids = selected.text
        .split(',')
        .map((s) => int.tryParse(s.trim()))
        .whereType<int>()
        .toSet();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Autocomplete<PracticeJson>(
          optionsBuilder: (value) async {
            final query = value.text.trim();
            if (query.length < 2) return const <PracticeJson>[];
            try {
              final result = await widget.repository.request(
                'people?q=${Uri.encodeQueryComponent(query)}',
              );
              return (result['users'] as List)
                  .map((u) => Map<String, dynamic>.from(u as Map))
                  .toList();
            } catch (e) {
              if (mounted) setState(() => error = e.toString());
              return const <PracticeJson>[];
            }
          },
          displayStringForOption: (user) => '@${user['username']}',
          onSelected: (user) => setState(() {
            final id = int.parse(user['id'].toString());
            ids.add(id);
            selectedNames[id] = user['username'].toString();
            selected.text = ids.join(',');
          }),
          fieldViewBuilder: (context, search, focus, submitted) =>
              TextFormField(
                controller: search,
                focusNode: focus,
                onFieldSubmitted: (_) => submitted(),
                decoration: InputDecoration(
                  labelText: socialText(
                    context,
                    'جست‌وجوی نام کاربری مخاطبان',
                    'Search audience usernames',
                  ),
                ),
              ),
        ),
        Wrap(
          spacing: 8,
          children: ids
              .map(
                (id) => InputChip(
                  label: Text(
                    selectedNames[id] == null
                        ? '#$id'
                        : '@${selectedNames[id]}',
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: appRadius(context),
                  ),
                  onDeleted: () => setState(() {
                    ids.remove(id);
                    selected.text = ids.join(',');
                  }),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  String text(String name) => fields[name]!.text.trim();
  Future<void> save() async {
    if (saving || !key.currentState!.validate()) return;
    setState(() => saving = true);
    try {
      final body = <String, dynamic>{
        'id': int.tryParse((old['id'] ?? 0).toString()) ?? 0,
        if (old['version'] != null)
          'version': int.parse(old['version'].toString()),
      };
      if (widget.kind == 'nodes') {
        body.addAll({
          'parentId': parent,
          'slug': text('slug'),
          'titleFa': text('titleFa'),
          'titleEn': text('titleEn'),
          'position': integer('position'),
          'published': published,
        });
      } else if (widget.kind == 'exams') {
        PracticeJson config;
        if (engine == 'interval') {
          config = {
            'kind': engine,
            'quarterSteps': text(
              'quarterSteps',
            ).split(',').map((s) => int.parse(s.trim())).toList(),
            'direction': direction,
            'variableRoot': variableRoot,
          };
        } else {
          config = {
            'kind': engine,
            'questions': [
              for (final q in questions)
                {
                  'promptFa': q['promptFa']!.text.trim(),
                  'promptEn': q['promptEn']!.text.trim(),
                  'choices': q['choices']!.text
                      .split('\n')
                      .where((s) => s.trim().isNotEmpty)
                      .toList(),
                  'correct': int.parse(q['correct']!.text),
                  if (engine == 'rhythm')
                    'beats': q['beats']!.text
                        .split(',')
                        .map((s) => double.parse(s.trim()))
                        .toList(),
                  if (engine == 'rhythm') 'bpm': int.parse(q['bpm']!.text),
                },
            ],
          };
        }
        body.addAll({
          'nodeId': parent,
          'titleFa': text('titleFa'),
          'titleEn': text('titleEn'),
          'position': integer('position'),
          'stageCount': integer('stageCount'),
          'requiredWins': integer('requiredWins'),
          'published': published,
          'audience': audience,
          'userIds': text('userIds')
              .split(',')
              .where((s) => s.trim().isNotEmpty)
              .map((s) => int.parse(s.trim()))
              .toList(),
          'config': config,
        });
      } else if (widget.kind == 'plans/propose') {
        body.addAll({
          'examId': parent,
          'title': text('title'),
          'amount': integer('amount'),
          'days': integer('days'),
        });
      } else if (widget.kind == 'shares') {
        body.addAll({
          'shareVersion': old['shareVersion'],
          'teacherBps': (double.parse(text('teacherPercent')) * 100).round(),
        });
      } else {
        body.addAll({
          'teacherBps': (double.parse(text('teacherPercent')) * 100).round(),
          'status': status,
        });
      }
      await widget.repository.request(widget.kind, body);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final caps = Map<String, dynamic>.from(
          widget.catalog['capabilities'] as Map,
        ),
        nodes = (widget.catalog['nodes'] as List)
            .map((n) => Map<String, dynamic>.from(n as Map))
            .toList(),
        config = Map<String, dynamic>.from(old['config'] as Map? ?? {}),
        en = Localizations.localeOf(context).languageCode == 'en';
    return Scaffold(
      appBar: SornazAppBar(
        title: socialText(context, 'ویرایش آزمون‌ها', 'Edit tests'),
        actions: [
          IconButton(
            tooltip: socialText(context, 'ذخیره', 'Save'),
            onPressed: saving ? null : save,
            icon: const Icon(Icons.save_outlined),
          ),
        ],
      ),
      body: Form(
        key: key,
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            if (saving) const LinearProgressIndicator(),
            if (error != null) Text(error!),
            if (widget.kind == 'nodes' || widget.kind == 'exams') ...[
              input('titleFa', 'عنوان فارسی', 'Persian title', old['titleFa']),
              input(
                'titleEn',
                'عنوان انگلیسی',
                'English title',
                old['titleEn'],
              ),
              input(
                'position',
                'ترتیب',
                'Order',
                old['position'] ?? 0,
                number: true,
              ),
              dropdown(
                socialText(context, 'بخش والد', 'Parent section'),
                '$parent',
                [
                  if (widget.kind == 'nodes')
                    ('0', socialText(context, 'سطح اول', 'First level')),
                  for (final node in nodes)
                    if (widget.kind != 'nodes' ||
                        (node['depth'] as int) < 3 && node['id'] != old['id'])
                      (
                        '${node['id']}',
                        (en ? node['titleEn'] : node['titleFa']).toString(),
                      ),
                ],
                (v) => parent = int.parse(v),
              ),
              SwitchListTile(
                title: Text(socialText(context, 'انتشار', 'Published')),
                value: published,
                onChanged: caps['publish'] == true
                    ? (v) => setState(() => published = v)
                    : null,
              ),
            ],
            if (widget.kind == 'nodes')
              input(
                'slug',
                'نشانی کوتاه انگلیسی',
                'Short English address',
                old['slug'],
              ),
            if (widget.kind == 'exams') ...[
              input(
                'stageCount',
                'تعداد مراحل',
                'Number of stages',
                old['stageCount'] ?? 5,
                number: true,
              ),
              input(
                'requiredWins',
                'پاسخ درست پیاپی برای هر مرحله',
                'Consecutive correct answers per stage',
                old['requiredWins'] ?? 10,
                number: true,
              ),
              dropdown(socialText(context, 'مخاطبان', 'Audience'), audience, [
                ('public', socialText(context, 'عمومی', 'Public')),
                (
                  'users',
                  socialText(
                    context,
                    'کاربران منتخب / هنرجویان شخصی',
                    'Selected users / personal students',
                  ),
                ),
                (
                  'students',
                  socialText(
                    context,
                    'هنرجویان فعال مدرس',
                    'Teacher’s active students',
                  ),
                ),
                (
                  'subscribers',
                  socialText(context, 'مشترکان مدرس', 'Teacher’s subscribers'),
                ),
              ], (v) => audience = v),
              userPicker(),
              dropdown(
                socialText(context, 'نوع تمرین', 'Practice type'),
                engine,
                [
                  (
                    'interval',
                    socialText(context, 'تشخیص فاصله', 'Interval recognition'),
                  ),
                  (
                    'choice',
                    socialText(context, 'چندگزینه‌ای', 'Multiple choice'),
                  ),
                  (
                    'rhythm',
                    socialText(context, 'تشخیص ریتم', 'Rhythm recognition'),
                  ),
                ],
                (v) => engine = v,
              ),
              if (engine == 'interval') ...[
                input(
                  'quarterSteps',
                  'فاصله‌ها با واحد ربع‌پرده و ویرگول',
                  'Quarter-tone distances separated by commas',
                  (config['quarterSteps'] as List? ?? [14, 24]).join(','),
                ),
                dropdown(socialText(context, 'جهت', 'Direction'), direction, [
                  ('ascending', socialText(context, 'بالارونده', 'Ascending')),
                  (
                    'descending',
                    socialText(context, 'پایین‌رونده', 'Descending'),
                  ),
                ], (v) => direction = v),
                SwitchListTile(
                  title: Text(
                    socialText(
                      context,
                      'نت پایهٔ متغیر',
                      'Variable starting note',
                    ),
                  ),
                  value: variableRoot,
                  onChanged: (v) => setState(() => variableRoot = v),
                ),
              ] else ...[
                for (final q in questions)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          for (final field in [
                            'promptFa',
                            'promptEn',
                            'choices',
                            'correct',
                            if (engine == 'rhythm') ...['beats', 'bpm'],
                          ])
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: TextFormField(
                                controller: q[field],
                                maxLines: field == 'choices' ? 4 : 1,
                                style: Theme.of(context).textTheme.bodyMedium,
                                decoration: InputDecoration(
                                  labelText: switch (field) {
                                    'promptFa' => socialText(
                                      context,
                                      'پرسش فارسی',
                                      'Persian question',
                                    ),
                                    'promptEn' => socialText(
                                      context,
                                      'پرسش انگلیسی',
                                      'English question',
                                    ),
                                    'choices' => socialText(
                                      context,
                                      'گزینه‌ها؛ هر گزینه در یک سطر',
                                      'Choices, one per line',
                                    ),
                                    'correct' => socialText(
                                      context,
                                      'شماره گزینهٔ درست (از صفر)',
                                      'Correct choice index (starting at zero)',
                                    ),
                                    'beats' => socialText(
                                      context,
                                      'کشش ضرب‌ها با ویرگول',
                                      'Beat lengths, comma-separated',
                                    ),
                                    _ => socialText(
                                      context,
                                      'ضرب در دقیقه',
                                      'Beats per minute',
                                    ),
                                  },
                                ),
                                validator: (v) => v == null || v.trim().isEmpty
                                    ? socialText(context, 'الزامی', 'Required')
                                    : null,
                              ),
                            ),
                          IconButton(
                            tooltip: socialText(
                              context,
                              'حذف پرسش',
                              'Remove question',
                            ),
                            onPressed: () => setState(() {
                              questions.remove(q);
                              for (final c in q.values) {
                                c.dispose();
                              }
                            }),
                            icon: const Icon(Icons.delete_outline),
                          ),
                        ],
                      ),
                    ),
                  ),
                OutlinedButton.icon(
                  onPressed: () => setState(() => addQuestion()),
                  icon: const Icon(Icons.add),
                  label: Text(
                    socialText(context, 'افزودن پرسش', 'Add question'),
                  ),
                ),
              ],
            ],
            if (widget.kind == 'plans/propose') ...[
              dropdown(
                socialText(context, 'نوع خرید', 'Purchase type'),
                '$parent',
                [
                  (
                    '0',
                    socialText(
                      context,
                      'اشتراک ویژه؛ همه آزمون‌های مدرس',
                      'VIP subscription; all teacher tests',
                    ),
                  ),
                  for (final exam in (widget.catalog['exams'] as List).map(
                    (e) => Map<String, dynamic>.from(e as Map),
                  ))
                    (
                      '${exam['id']}',
                      (en ? exam['titleEn'] : exam['titleFa']).toString(),
                    ),
                ],
                (v) => parent = int.parse(v),
              ),
              input('title', 'عنوان پلن', 'Plan title', old['title']),
              input(
                'amount',
                'مبلغ به تومان',
                'Amount in toman',
                old['amount'] ?? 1000,
                number: true,
              ),
              input(
                'days',
                'مدت اشتراک ویژه به روز؛ خرید تکی دائمی است',
                'VIP duration in days; individual purchases are permanent',
                old['days'] ?? 30,
                number: true,
              ),
            ],
            if (widget.kind == 'shares')
              input(
                'teacherPercent',
                'سهم مدرس؛ باقی سهم سرناز است',
                'Teacher share; the remainder belongs to Sornaz',
                (old['teacherBps'] ?? 8000) / 100,
                number: true,
              ),
            if (widget.kind == 'plans/approve') ...[
              Text('${old['title']} · ${old['amount']} · ${old['days']}'),
              input(
                'teacherPercent',
                'سهم مدرس، درصد',
                'Teacher share, percent',
                proposedShare,
                number: true,
              ),
              dropdown(
                socialText(context, 'تصمیم مدیر', 'Administrator decision'),
                status,
                [
                  (
                    'approved',
                    socialText(context, 'تأیید فروش', 'Approve sales'),
                  ),
                  (
                    'rejected',
                    socialText(
                      context,
                      'رد / توقف فروش',
                      'Reject / stop sales',
                    ),
                  ),
                ],
                (v) => status = v,
              ),
            ],
            FilledButton(
              onPressed: saving ? null : save,
              child: Text(socialText(context, 'ذخیره', 'Save')),
            ),
          ],
        ),
      ),
    );
  }
}
