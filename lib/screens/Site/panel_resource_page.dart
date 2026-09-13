import 'dart:async';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:sornaz/screens/Authentication/providers/auth_session.dart';
import 'package:sornaz/components/join_community.dart';
import '../Social/social_api.dart';
import '../Social/social_widgets.dart';
import 'panel_api.dart';
import 'panel_form.dart';
import 'panel_presentation.dart';
import 'panel_voice.dart';

String panelLabel(BuildContext context, Json item) =>
    Localizations.localeOf(context).languageCode == 'fa'
    ? '${item['label'] ?? ''}'
    : '${item['en'] ?? item['label'] ?? ''}';

class PanelResourcePage extends StatefulWidget {
  const PanelResourcePage({
    super.key,
    required this.api,
    required this.section,
    this.params = const {},
  });
  final PanelApi api;
  final Json section;
  final Map<String, String> params;
  @override
  State<PanelResourcePage> createState() => _PanelResourcePageState();
}

class _PanelResourcePageState extends State<PanelResourcePage> {
  Json data = {}, filters = {};
  bool loading = true, busy = false;
  Object? error;
  String query = '';
  int page = 1, generation = 0;
  Timer? searchTimer;
  @override
  void dispose() {
    searchTimer?.cancel();
    generation++;
    super.dispose();
  }

  final selected = <String>{};
  String get section => '${widget.section['key']}';
  Json get actions => optionalObject(widget.section['actions']);
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final request = ++generation;
    try {
      final value = await widget.api.get('/$section/list', {
        ...widget.params,
        for (final entry in filters.entries)
          if (entry.value != null && '${entry.value}'.isNotEmpty)
            entry.key: '${entry.value}',
        if (!widget.params.containsKey('page')) 'page': '$page',
        'perPage': '50',
        if (query.trim().isNotEmpty) ...{
          'q': query.trim(),
          'search': query.trim(),
        },
      });
      for (final option
          in widget.section['optionActions'] as List? ?? const []) {
        value.addAll(await widget.api.get('/$section/$option', widget.params));
      }
      if (mounted && request == generation) {
        setState(() {
          data = value;
          error = null;
          selected.clear();
        });
      }
    } catch (e) {
      if (mounted && request == generation) setState(() => error = e);
    } finally {
      if (mounted && request == generation) setState(() => loading = false);
    }
  }

  bool available(String key, Json record) {
    if (key == 'list' || !actions.containsKey(key)) return false;
    final action = optionalObject(actions[key]);
    if (section == 'classroom-categories' &&
        optionalObject(data['permissions'])[key == 'delete'
                ? 'canDeleteCategory'
                : 'canUpdateCategory'] ==
            false) {
      return false;
    }
    if (action['row'] != true) return false;
    if (section == 'chat') return key == 'details';
    if (record['readOnly'] == true || record['read_only'] == true) return false;
    if (record['canManage'] == false &&
        ![
          'vote',
          'download-media',
          'download-backup',
          'file',
          'details',
          'messages',
        ].contains(key)) {
      return false;
    }
    if (key == 'update' && record['canEdit'] == false ||
        key == 'delete' && record['canDelete'] == false ||
        key == 'status' &&
            (record['canChangeStatus'] == false ||
                optionalObject(data['permissions'])['isReceptionist'] ==
                    true)) {
      return false;
    }
    if (section == 'account') {
      return false; // Account collections have explicit scoped actions below.
    }
    if (section == 'chat') {
      return [
        'rename',
        'avatar',
        'members',
        'leave',
        'delete',
        'details',
      ].contains(key);
    }
    if (section == 'terms' && key.startsWith('cancel') ||
        section == 'terms' && key == 'restore') {
      return false;
    }
    if (section == 'finance' && ['pay', 'offline'].contains(key)) return false;
    return true;
  }

  Future<void> perform(
    String key, [
    Json record = const {},
    Map<String, String> extra = const {},
  ]) async {
    if (busy) return;
    final action = optionalObject(actions[key]);
    if (action.isEmpty) return;
    if (section == 'chat' && key == 'details') {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PanelGroupDetails(
            api: widget.api,
            section: widget.section,
            id: '${record['id']}',
          ),
        ),
      );
      if (mounted) await load();
      return;
    }
    final params = {
      'id': '${record['id'] ?? record['sessionId'] ?? ''}',
      ...widget.params,
      if (record['value'] != null) 'value': '${record['value']}',
      ...extra,
    };
    final fields = action['fields'] is List
        ? objects(action['fields'])
        : <Json>[];
    var initial = <String, dynamic>{...record, ...widget.params};
    if (section == 'account' && action['row'] != true) {
      initial = {...optionalObject(data['profile'])};
    }
    if (key == 'privacy') initial = {...optionalObject(initial['privacy'])};
    if (section == 'settings') initial = {...data};
    if ([
          'availabilities',
          'member-schedules',
          'availability-exceptions',
        ].contains(section) &&
        initial['timeLabel'] is String) {
      final range = (initial['timeLabel'] as String).split('-');
      if (range.length == 2) {
        initial['ranges'] = [
          {
            'start': range[0],
            'end': range[1],
            'status': initial['status'] ?? 'فعال',
          },
        ];
      }
    }
    if (initial.containsKey('status_code')) {
      initial['status'] = initial['status_code'];
    }
    if (initial.containsKey('statusCode')) {
      initial['status'] = initial['statusCode'];
    }
    if (section == 'polls' && key == 'update' && initial['options'] is List) {
      initial['options'] = (initial['options'] as List)
          .map((v) => v is Map ? '${v['label']}' : v)
          .toList();
    }
    PanelFormResult? result;
    if (fields.isNotEmpty) {
      result = await Navigator.of(context).push<PanelFormResult>(
        MaterialPageRoute(
          builder: (_) => PanelFormPage(
            title: '${action['label']}',
            fields: fields,
            data: {
              ...data,
              if (section == 'polls') 'options': record['options'],
              if (section == 'schedules') 'attendance': record['attendance'],
            },
            initial: key == 'create' ? {...widget.params} : initial,
          ),
        ),
      );
      if (result == null || !mounted) return;
    } else if (action['method'] != 'GET') {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('${action['label']}'),
          content: Text(panelTitle(record)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(socialText(context, 'خیر', 'No')),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(socialText(context, 'بلی', 'Yes')),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
    }
    setState(() => busy = true);
    try {
      if (action['download'] == true) {
        await widget.api.download(
          section,
          key,
          params,
          '${record['name'] ?? record['filename'] ?? 'download'}',
        );
      } else if (action['method'] == 'GET') {
        final detail = await widget.api.get('/$section/$key', params);
        if (mounted) {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => Scaffold(
                appBar: AppBar(title: Text('${action['label']}')),
                body: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: PanelDataView(value: detail),
                ),
              ),
            ),
          );
        }
      } else {
        final response = await widget.api.act(
          section,
          key,
          values: result?.values ?? {},
          params: params,
          files: result?.files ?? {},
        );
        final paymentUrl =
            response['paymentUrl'] ??
            response['redirectUrl'] ??
            response['url'];
        if (['pay'].contains(key) && paymentUrl is String) {
          final uri = Uri.tryParse(paymentUrl);
          if (uri != null && uri.scheme == 'https') {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        }
        await load();
      }
    } catch (e) {
      if (mounted) socialError(context, e);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Widget recordCard(
    Json row, {
    List<String>? only,
    Map<String, String> extra = const {},
  }) {
    final rowActions =
        only ?? actions.keys.where((key) => available(key, row)).toList();
    final id = '${row['id']}';
    return Card(
      color: selected.contains(id)
          ? Theme.of(context).colorScheme.primaryContainer
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListTile(
            title: Text(panelTitle(row)),
            subtitle: Text(
              [
                '${row['summary'] ?? row['lastMessage'] ?? row['body'] ?? row['timeLabel'] ?? ''}',
                '${row['status'] ?? ''}',
              ].where((s) => s.isNotEmpty).join('\n'),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            onLongPress: row['id'] == null
                ? null
                : () => setState(() {
                    selected.contains(id)
                        ? selected.remove(id)
                        : selected.add(id);
                  }),
            trailing: rowActions.isEmpty
                ? null
                : PopupMenuButton<String>(
                    onSelected: (key) => perform(key, row, extra),
                    itemBuilder: (_) => [
                      for (final key in rowActions)
                        if (actions.containsKey(key))
                          PopupMenuItem(
                            value: key,
                            child: Text('${actions[key]['label']}'),
                          ),
                    ],
                  ),
            onTap: () async {
              if (selected.isNotEmpty) {
                setState(() {
                  selected.contains(id)
                      ? selected.remove(id)
                      : selected.add(id);
                });
                return;
              }
              if (widget.section['detail'] is Map) {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => PanelResourcePage(
                      api: widget.api,
                      section: optionalObject(widget.section['detail']),
                      params: {'page': id},
                    ),
                  ),
                );
                await load();
                return;
              }
              if (section == 'chat') {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => PanelConversationPage(
                      api: widget.api,
                      section: widget.section,
                      conversation: row,
                    ),
                  ),
                );
                await load();
                return;
              }
              await showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                builder: (context) => DraggableScrollableSheet(
                  expand: false,
                  initialChildSize: .7,
                  builder: (context, scroll) => ListView(
                    controller: scroll,
                    padding: const EdgeInsets.all(20),
                    children: [
                      Text(
                        panelTitle(row),
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      PanelDataView(value: row),
                      if (section == 'terms')
                        for (final session
                            in (row['sessions'] is List
                                ? objects(row['sessions'])
                                : <Json>[]))
                          Card(
                            child: Column(
                              children: [
                                PanelDataView(value: session),
                                Wrap(
                                  children: [
                                    for (final key in [
                                      'cancel',
                                      'cancel-approve',
                                      'cancel-reject',
                                      'restore',
                                    ])
                                      if (actions.containsKey(key))
                                        TextButton(
                                          onPressed: () {
                                            Navigator.pop(context);
                                            perform(key, row, {
                                              'sessionId':
                                                  '${session['id'] ?? session['sessionId']}',
                                            });
                                          },
                                          child: Text(
                                            '${actions[key]['label']}',
                                          ),
                                        ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                      if (section == 'finance')
                        for (final installment
                            in (row['installments'] is List
                                ? objects(row['installments'])
                                : <Json>[]))
                          Card(
                            child: Column(
                              children: [
                                PanelDataView(value: installment),
                                Wrap(
                                  children: [
                                    for (final key in ['pay', 'offline'])
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(context);
                                          perform(key, row, {
                                            'invoiceId': '${row['id']}',
                                            'installmentId':
                                                '${installment['id']}',
                                          });
                                        },
                                        child: Text('${actions[key]['label']}'),
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
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthSession?>();
    if (auth != null && auth.token != widget.api.token) {
      return const Scaffold(body: JoinCommunity());
    }
    final dynamic collection = panelValue(
      data,
      '${widget.section['rows'] ?? ''}',
    );
    final rows = collection is List
        ? collection.whereType<Map>().map(optionalObject).toList()
        : data['items'] is List
        ? objects(data['items'])
        : <Json>[];
    final filtered = rows
        .where(
          (row) =>
              optionalObject(
                widget.section['where'],
              ).entries.every((e) => row[e.key] == e.value) &&
              !optionalObject(
                widget.section['exclude'],
              ).entries.any((e) => row[e.key] == e.value) &&
              row.values
                  .where((v) => v is String || v is num)
                  .join(' ')
                  .toLowerCase()
                  .contains(query.toLowerCase()),
        )
        .toList();
    return Scaffold(
      appBar: AppBar(
        title: Text(panelLabel(context, widget.section)),
        actions: [
          if (filtered.isNotEmpty)
            IconButton(
              tooltip: socialText(
                context,
                'خروجی فهرست نمایش‌داده‌شده',
                'Export displayed records',
              ),
              icon: const Icon(Icons.file_download_outlined),
              onPressed: () async {
                try {
                  await exportPanelRows(section, filtered);
                } catch (e) {
                  if (mounted) socialError(this.context, e);
                }
              },
            ),
          if (filtered.isNotEmpty || data['stats'] is Map)
            IconButton(
              tooltip: 'PDF',
              icon: const Icon(Icons.picture_as_pdf_outlined),
              onPressed: () async {
                final exportRows = filtered.isEmpty
                    ? [optionalObject(data['stats'])]
                    : filtered;
                final labels = {
                  for (final key in exportRows.expand((row) => row.keys))
                    key: panelDataLabel(context, key),
                };
                final title = panelLabel(context, widget.section);
                final rtl = Directionality.of(context) == TextDirection.rtl;
                try {
                  await exportPanelPdf(
                    title,
                    exportRows,
                    rtl: rtl,
                    labels: labels,
                  );
                } catch (e) {
                  if (mounted) socialError(this.context, e);
                }
              },
            ),
          if (widget.section['filters'] is List)
            IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: () async {
                final result = await Navigator.of(context)
                    .push<PanelFormResult>(
                      MaterialPageRoute(
                        builder: (_) => PanelFormPage(
                          title: socialText(context, 'فیلترها', 'Filters'),
                          fields: objects(widget.section['filters']),
                          data: data,
                          initial: filters,
                        ),
                      ),
                    );
                if (result != null && mounted) {
                  setState(() {
                    filters = result.values;
                    page = 1;
                  });
                  await load();
                }
              },
            ),
          if (filters.isNotEmpty)
            IconButton(
              tooltip: socialText(context, 'حذف فیلترها', 'Clear filters'),
              icon: const Icon(Icons.filter_alt_off),
              onPressed: () {
                setState(() {
                  filters = {};
                  page = 1;
                });
                load();
              },
            ),
          IconButton(onPressed: load, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
          ? SocialEmpty(
              socialText(
                context,
                'اطلاعات دریافت نشد. دوباره تلاش کنید.',
                'Could not load data. Please retry.',
              ),
              onRetry: load,
            )
          : RefreshIndicator(
              onRefresh: load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (busy) const LinearProgressIndicator(),
                  if (collection is List)
                    TextField(
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.search),
                        hintText: socialText(context, 'جستجو', 'Search'),
                      ),
                      onChanged: (v) {
                        setState(() {
                          query = v;
                          page = 1;
                        });
                        searchTimer?.cancel();
                        searchTimer = Timer(
                          const Duration(milliseconds: 400),
                          load,
                        );
                      },
                    ),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final entry in actions.entries)
                        if (entry.key != 'list' &&
                            entry.value['row'] == false &&
                            entry.value['hidden'] != true &&
                            !(section == 'account' &&
                                ['document', 'backup'].contains(entry.key) &&
                                optionalObject(
                                      data['profile'],
                                    )['accountType'] !=
                                    'academy') &&
                            !(section == 'account' &&
                                entry.key == 'merge' &&
                                optionalObject(data['merges'])['eligible'] ==
                                    false) &&
                            !(section == 'classroom-categories' &&
                                entry.key == 'create' &&
                                optionalObject(
                                      data['permissions'],
                                    )['canSetType'] ==
                                    false) &&
                            !(entry.key == 'create' &&
                                (data['can_create_branch'] == false ||
                                    section == 'classroom-types' &&
                                        optionalObject(
                                              data['permissions'],
                                            )['canCreate'] ==
                                            false)))
                          ActionChip(
                            label: Text('${entry.value['label']}'),
                            onPressed: busy ? null : () => perform(entry.key),
                          ),
                    ],
                  ),
                  if (page > 1 ||
                      (num.tryParse('${data['total'] ?? 0}') ?? 0) >
                          page *
                              (num.tryParse('${data['perPage'] ?? 50}') ?? 50))
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: page > 1
                              ? () {
                                  setState(() => page--);
                                  load();
                                }
                              : null,
                          child: Text(socialText(context, 'قبلی', 'Previous')),
                        ),
                        Text('$page'),
                        TextButton(
                          onPressed:
                              (num.tryParse('${data['total'] ?? 0}') ?? 0) >
                                  page *
                                      (num.tryParse(
                                            '${data['perPage'] ?? 50}',
                                          ) ??
                                          50)
                              ? () {
                                  setState(() => page++);
                                  load();
                                }
                              : null,
                          child: Text(socialText(context, 'بعدی', 'Next')),
                        ),
                      ],
                    ),
                  if (selected.isNotEmpty)
                    Row(
                      children: [
                        Text('${selected.length}'),
                        IconButton(
                          onPressed: () => setState(selected.clear),
                          icon: const Icon(Icons.close),
                        ),
                        if (actions.containsKey('delete'))
                          IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () async {
                              for (final row
                                  in rows
                                      .where(
                                        (r) => selected.contains('${r['id']}'),
                                      )
                                      .toList()) {
                                if (available('delete', row)) {
                                  await perform('delete', row);
                                }
                              }
                              if (mounted) setState(selected.clear);
                            },
                          ),
                      ],
                    ),
                  if (section == 'account') ...[
                    PanelProfileHeader(
                      profile: optionalObject(data['profile']),
                    ),
                    PanelDataView(value: data['profile']),
                    for (final pair in [
                      ('documents', ['download-media', 'delete-media']),
                      ('devices', ['end-session']),
                      ('merges.requests', ['cancel-merge', 'decide-merge']),
                    ]) ...[
                      Text(panelDataLabel(context, pair.$1)),
                      for (final row
                          in (panelValue(data, pair.$1) is List
                              ? objects(panelValue(data, pair.$1))
                              : <Json>[]))
                        recordCard(row, only: pair.$2),
                    ],
                    if (data['backup'] is Map)
                      recordCard(
                        optionalObject(data['backup']),
                        only: ['download-backup'],
                      ),
                    PanelDataView(
                      value: {
                        'loginHistory': data['loginHistory'],
                        'securityAlerts': data['securityAlerts'],
                      },
                    ),
                  ] else if (['dashboard', 'reports'].contains(section)) ...[
                    PanelStatistics(stats: optionalObject(data['stats'])),
                    const SizedBox(height: 16),
                    PanelDataView(
                      value: {...data}
                        ..remove('stats')
                        ..remove('branches'),
                    ),
                  ] else if (rows.isNotEmpty) ...[
                    for (final row in filtered) recordCard(row),
                  ] else if (collection is List)
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        socialText(
                          context,
                          'موردی ثبت نشده است.',
                          'No records yet.',
                        ),
                      ),
                    )
                  else
                    PanelDataView(value: data),
                ],
              ),
            ),
    );
  }
}

String panelDataLabel(BuildContext context, String key) {
  const labels = {
    'profile': 'مشخصات',
    'name': 'نام',
    'title': 'عنوان',
    'course_title': 'دوره',
    'term_title': 'ترم',
    'classroom_title': 'کلاس',
    'requested_date': 'تاریخ',
    'start_time': 'زمان شروع',
    'end_time': 'زمان پایان',
    'timeLabel': 'ساعت',
    'day': 'روز',
    'repeatPeriod': 'تکرار',
    'timezone': 'منطقه زمانی',
    'balance': 'موجودی امتیاز',
    'rules': 'قوانین',
    'recent': 'تازه‌ترین‌ها',
    'body': 'متن',
    'summary': 'خلاصه',
    'description': 'توضیحات',
    'status': 'وضعیت',
    'email': 'ایمیل',
    'phone': 'تماس',
    'address': 'نشانی',
    'biography': 'درباره من',
    'shortIntro': 'معرفی کوتاه',
    'type': 'نوع',
    'date': 'تاریخ',
    'amount': 'مبلغ',
    'cost': 'شهریه',
    'startDate': 'شروع',
    'endDate': 'پایان',
    'startTime': 'زمان شروع',
    'endTime': 'زمان پایان',
    'branchName': 'شعبه',
    'organizationName': 'آموزشگاه',
    'stats': 'آمار',
    'activeStudents': 'هنرجویان فعال',
    'todayClasses': 'کلاس‌های امروز',
    'monthlyIncome': 'درآمد ماهانه',
    'attendanceRate': 'درصد حضور',
    'pendingPayments': 'پرداخت‌های معوق',
    'absencesToday': 'غیبت‌های امروز',
    'newMessages': 'پیام‌های جدید',
    'urgentAlerts': 'هشدارهای مهم',
    'newStudentsWeek': 'هنرجویان جدید هفته',
    'pointsAwarded': 'امتیازهای اهداشده',
    'recentPayments': 'پرداخت‌های اخیر',
    'recentDeposits': 'واریزی‌های اخیر',
    'unreadMessages': 'پیام‌های خوانده‌نشده',
    'recentRegistrations': 'ثبت‌نام‌های اخیر',
    'upcomingHolidays': 'تعطیلات پیش رو',
    'urgentItems': 'هشدارها',
    'actionItems': 'نیازمند اقدام',
    'documents': 'اسناد',
    'devices': 'دستگاه‌ها',
    'merges.requests': 'درخواست‌های ادغام',
    'loginHistory': 'تاریخچه ورود',
    'securityAlerts': 'هشدارهای امنیتی',
    'sessions': 'جلسه‌ها',
    'installments': 'اقساط',
    'teacher': 'مدرس',
    'student': 'هنرجو',
    'capacity': 'ظرفیت',
    'privacy': 'حریم خصوصی',
    'showPublicProfile': 'نمایش عمومی پروفایل',
    'current': 'نشست فعلی',
    'lastActive': 'آخرین فعالیت',
    'location': 'مکان',
    'founded': 'تاریخ تأسیس',
    'members': 'اعضا',
  };
  return Localizations.localeOf(context).languageCode == 'fa'
      ? labels[key] ?? key.replaceAll('_', ' ')
      : key
            .replaceAll('_', ' ')
            .replaceAllMapped(
              RegExp(r'([a-z])([A-Z])'),
              (m) => '${m[1]} ${m[2]}',
            );
}

class PanelDataView extends StatelessWidget {
  const PanelDataView({super.key, required this.value});
  final dynamic value;
  @override
  Widget build(BuildContext context) {
    if (value == null) return const SizedBox();
    if (value is List) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final row in value)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: PanelDataView(value: row),
              ),
            ),
        ],
      );
    }
    if (value is Map) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final entry in (value as Map).entries)
            if (![
                  'id',
                  'csrf_token',
                  'success',
                  'permissions',
                  'catalog',
                  'staff_catalog',
                  'organizations',
                  'version',
                  'avatarUrl',
                  'coverUrl',
                  'password',
                ].contains('${entry.key}') &&
                !'${entry.key}'.startsWith('can') &&
                !RegExp(r'(_id|_by|_at|Id)$').hasMatch('${entry.key}') &&
                entry.value != null &&
                '${entry.value}'.isNotEmpty)
              entry.value is Map || entry.value is List
                  ? ExpansionTile(
                      title: Text(panelDataLabel(context, '${entry.key}')),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: PanelDataView(value: entry.value),
                        ),
                      ],
                    )
                  : Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: Text(
                        '${panelDataLabel(context, '${entry.key}')}: ${entry.value is bool ? (entry.value ? socialText(context, 'بلی', 'Yes') : socialText(context, 'خیر', 'No')) : entry.value}',
                      ),
                    ),
        ],
      );
    }
    return SelectableText('$value');
  }
}

class PanelConversationPage extends StatefulWidget {
  const PanelConversationPage({
    super.key,
    required this.api,
    required this.section,
    required this.conversation,
  });
  final PanelApi api;
  final Json section, conversation;
  @override
  State<PanelConversationPage> createState() => _PanelConversationPageState();
}

class _PanelConversationPageState extends State<PanelConversationPage> {
  final text = TextEditingController();
  List<Json> messages = [];
  Timer? timer;
  PlatformFile? attachment;
  bool sending = false, loading = true, fetching = false;
  Object? error;
  String get id => '${widget.conversation['id']}';
  Json get actions => optionalObject(widget.section['actions']);
  @override
  void initState() {
    super.initState();
    load();
    timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted &&
          ModalRoute.of(context)?.isCurrent == true &&
          WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed) {
        load();
      }
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    text.dispose();
    super.dispose();
  }

  Future<void> load() async {
    if (fetching) return;
    fetching = true;
    try {
      // Read every server page: the legacy endpoint caps its first batch at 200.
      final result = <Json>[];
      var after = 0;
      while (mounted) {
        final data = await widget.api.get('/chat/messages', {
          'id': id,
          'after': '$after',
        });
        final batch = objects(data['messages'] ?? []);
        result.addAll(batch);
        final next = batch.isEmpty
            ? after
            : int.tryParse('${batch.last['id']}') ?? after;
        if (batch.length < (after == 0 ? 200 : 100) || next <= after) break;
        after = next;
      }
      if (mounted) {
        setState(() {
          messages = result;
          error = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => error = e);
    } finally {
      fetching = false;
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> send() async {
    if (sending || text.text.trim().isEmpty && attachment == null) return;
    setState(() => sending = true);
    try {
      await widget.api.act(
        'chat',
        'send',
        params: {'id': id},
        values: {'body': text.text.trim()},
        files: {'file': ?attachment},
      );
      if (!mounted) return;
      text.clear();
      setState(() => attachment = null);
      await load();
    } catch (e) {
      if (mounted) socialError(context, e);
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  Future<void> messageAction(String action, Json row) async {
    try {
      if (action == 'file') {
        await widget.api.download('chat', 'file', {
          'id': '${row['id']}',
        }, '${row['file']?['name'] ?? 'download'}');
        return;
      }
      final definition = optionalObject(actions[action]);
      final fields = objects(definition['fields'] ?? []);
      Json values = {};
      if (fields.isNotEmpty) {
        final options = action == 'forward'
            ? await widget.api.get('/chat/list')
            : <String, dynamic>{};
        if (!mounted) return;
        final result = await Navigator.of(context).push<PanelFormResult>(
          MaterialPageRoute(
            builder: (_) => PanelFormPage(
              title: '${definition['label']}',
              fields: fields,
              data: options,
              initial: action == 'edit-message'
                  ? {'body': row['body']}
                  : const {},
            ),
          ),
        );
        if (result == null || !mounted) return;
        values = result.values;
      } else if (action == 'delete-message') {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(
              socialText(context, 'پیام حذف شود؟', 'Delete message?'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(socialText(context, 'خیر', 'No')),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(socialText(context, 'بلی', 'Yes')),
              ),
            ],
          ),
        );
        if (confirmed != true || !mounted) return;
      }
      await widget.api.act(
        'chat',
        action,
        params: {'id': '${row['id']}'},
        values: values,
      );
      await load();
    } catch (e) {
      if (mounted) socialError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthSession?>();
    if (auth != null && auth.token != widget.api.token) {
      return const Scaffold(body: JoinCommunity());
    }
    return Scaffold(
      appBar: AppBar(title: Text(panelTitle(widget.conversation))),
      body: Column(
        children: [
          if (loading) const LinearProgressIndicator(),
          if (error != null)
            TextButton(
              onPressed: load,
              child: Text(
                socialText(
                  context,
                  'ارتباط برقرار نشد؛ تلاش دوباره',
                  'Connection failed; retry',
                ),
              ),
            ),
          Expanded(
            child: ListView.builder(
              reverse: true,
              padding: const EdgeInsets.all(12),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final row = messages[messages.length - 1 - index];
                return Card(
                  child: ListTile(
                    title: Text('${row['sender'] ?? ''}'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${row['body'] ?? ''}'),
                        if ('${row['file']?['mime'] ?? ''}'.startsWith(
                          'audio/',
                        ))
                          PanelVoicePlayback(
                            key: ValueKey(row['id']),
                            api: widget.api,
                            messageId: '${row['id']}',
                          ),
                        if (row['file'] != null) Text('${row['file']['name']}'),
                        Text(
                          '${row['createdAt'] ?? ''}${row['edited'] == true ? ' • ✎' : ''}',
                        ),
                        if ((row['likes'] as num? ?? 0) > 0)
                          Text(
                            '♥ ${row['likes']}',
                            style: TextStyle(
                              color: row['liked'] == true
                                  ? Theme.of(context).colorScheme.primary
                                  : null,
                            ),
                          ),
                      ],
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (action) => messageAction(action, row),
                      itemBuilder: (_) => [
                        for (final action in [
                          'like',
                          'forward',
                          if (row['mine'] == true) ...[
                            'edit-message',
                            'delete-message',
                          ],
                          if (row['file'] != null) 'file',
                        ])
                          if (actions.containsKey(action))
                            PopupMenuItem(
                              value: action,
                              child: Text('${actions[action]['label']}'),
                            ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          if (attachment != null)
            ListTile(
              dense: true,
              title: Text(attachment!.name),
              trailing: IconButton(
                onPressed: sending
                    ? null
                    : () => setState(() => attachment = null),
                icon: const Icon(Icons.close),
              ),
            ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  IconButton(
                    tooltip: socialText(context, 'پیوست فایل', 'Attach file'),
                    icon: const Icon(Icons.attach_file),
                    onPressed: sending
                        ? null
                        : () async {
                            final picked = await FilePicker.platform.pickFiles(
                              withData: false,
                            );
                            if (mounted && picked != null) {
                              setState(() => attachment = picked.files.single);
                            }
                          },
                  ),
                  PanelVoiceButton(
                    enabled: !sending && attachment == null,
                    onRecorded: (file) => setState(() => attachment = file),
                  ),
                  Expanded(
                    child: TextField(
                      controller: text,
                      minLines: 1,
                      maxLines: 5,
                      decoration: InputDecoration(
                        hintText: socialText(context, 'پیام', 'Message'),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: sending ? null : send,
                    icon: sending
                        ? const CircularProgressIndicator()
                        : const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PanelGroupDetails extends StatefulWidget {
  const PanelGroupDetails({
    super.key,
    required this.api,
    required this.section,
    required this.id,
  });
  final PanelApi api;
  final Json section;
  final String id;
  @override
  State<PanelGroupDetails> createState() => _PanelGroupDetailsState();
}

class _PanelGroupDetailsState extends State<PanelGroupDetails> {
  Json data = {};
  bool loading = true, busy = false;
  Object? error;
  Json get actions => optionalObject(widget.section['actions']);
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final value = await widget.api.get('/chat/details', {'id': widget.id});
      if (mounted) {
        setState(() {
          data = value;
          error = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => error = e);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> perform(String key, [Json member = const {}]) async {
    if (busy) return;
    final action = optionalObject(actions[key]);
    final fields = objects(action['fields'] ?? []);
    PanelFormResult? result;
    if (fields.isNotEmpty) {
      result = await Navigator.of(context).push<PanelFormResult>(
        MaterialPageRoute(
          builder: (_) => PanelFormPage(
            title: '${action['label']}',
            fields: fields,
            data: {'users': data['availableUsers'] ?? []},
            initial: key == 'rename' ? {'title': data['title']} : const {},
          ),
        ),
      );
      if (result == null || !mounted) return;
    } else {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('${action['label']}'),
          content: Text(panelTitle(member.isEmpty ? data : member)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(socialText(context, 'خیر', 'No')),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(socialText(context, 'بلی', 'Yes')),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
    }
    setState(() => busy = true);
    try {
      await widget.api.act(
        'chat',
        key,
        params: {
          'id': widget.id,
          if (member.isNotEmpty) 'userId': '${member['id']}',
        },
        values: result?.values ?? {},
        files: result?.files ?? {},
      );
      if (!mounted) return;
      if (key == 'leave' || key == 'delete') {
        Navigator.pop(context);
        return;
      }
      await load();
    } catch (e) {
      if (mounted) socialError(context, e);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthSession?>();
    if (auth != null && auth.token != widget.api.token) {
      return const Scaffold(body: JoinCommunity());
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(
          socialText(context, 'اطلاعات گفتگو', 'Conversation details'),
        ),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
          ? SocialEmpty(
              socialText(
                context,
                'اطلاعات دریافت نشد.',
                'Could not load details.',
              ),
              onRetry: load,
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (busy) const LinearProgressIndicator(),
                Text(
                  panelTitle(data),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final key in [
                      if (data['canManage'] == true) ...[
                        'rename',
                        'avatar',
                        'members',
                      ],
                      if (data['type'] == 'group') 'leave',
                      if (data['canDelete'] == true) 'delete',
                    ])
                      if (actions.containsKey(key))
                        ActionChip(
                          label: Text('${actions[key]['label']}'),
                          onPressed: busy ? null : () => perform(key),
                        ),
                  ],
                ),
                for (final member in objects(data['members'] ?? []))
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.person_outline),
                      title: Text(panelTitle(member)),
                      subtitle: Text('${member['roleLabel'] ?? ''}'),
                      trailing:
                          data['canManage'] == true &&
                              member['isMe'] != true &&
                              actions.containsKey('remove-member')
                          ? IconButton(
                              tooltip: socialText(
                                context,
                                'حذف عضو',
                                'Remove member',
                              ),
                              icon: const Icon(Icons.person_remove_outlined),
                              onPressed: busy
                                  ? null
                                  : () => perform('remove-member', member),
                            )
                          : null,
                    ),
                  ),
              ],
            ),
    );
  }
}
