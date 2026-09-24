import '../Social/media_picker.dart';
import 'chat_message_bubble.dart';
import 'chat_cache.dart';
import 'chat_media.dart';
import 'package:sornaz/components/scroll_aware_scaffold.dart';
import 'package:sornaz/components/app_top_bar_direction.dart';
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
import 'panel_list_item.dart';
import 'panel_gallery.dart';
import 'package:sornaz/components/media_dialogs.dart';

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
    this.accountArea,
  });
  final String? accountArea;
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
  bool searchOpen = false;
  final searchInput = TextEditingController();
  int page = 1, generation = 0;
  Timer? searchTimer;
  @override
  void dispose() {
    searchInput.dispose();
    searchTimer?.cancel();
    generation++;
    super.dispose();
  }

  final selected = <String>{};
  String get section => '${widget.section['key']}';
  Json get actions {
    final all = optionalObject(widget.section['actions']);
    final area = widget.accountArea;
    if (area == null) return all;
    final keys = <String>{
      'list',
      area,
      if (area == 'documents') ...[
        'document',
        'download-media',
        'delete-media',
        'backup',
        'download-backup',
      ],
      if (area == 'devices') 'end-session',
      if (area == 'merges.requests') ...['cancel-merge', 'decide-merge'],
    };
    return Map.fromEntries(all.entries.where((e) => keys.contains(e.key)));
  }

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load({bool refresh = false}) async {
    final request = ++generation;
    try {
      final value = await (refresh ? widget.api.refresh : widget.api.get)(
        '/$section/list',
        {
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
        },
      );
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
            fields: [
              for (final field in fields.where(
                (f) =>
                    !(section == 'gallery' &&
                        widget.params.containsKey('collection') &&
                        f['key'] == 'collection'),
              ))
                if (section == 'gallery' && field['type'] == 'file')
                  {
                    ...field,
                    'mediaPicker': true,
                    'imagesOnly': [
                      'cover',
                      'logo',
                    ].contains(widget.params['collection']),
                  }
                else if (field['key'] == 'founded' &&
                    optionalObject(data['profile'])['accountType'] == 'human')
                  {...field, 'label': 'تاریخ تولد', 'en': 'Date of birth'}
                else
                  field,
            ],
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
              builder: (_) => ScrollAwareScaffold(
                appBar: AppTopBarDirection(
                  child: AppBar(title: Text('${action['label']}')),
                ),
                body: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(vertical: 16),
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
      if (result != null)
        for (final file in result.files.values) {
          await releasePickedMedia(file);
        }
      if (mounted) setState(() => busy = false);
    }
  }

  void searchChanged(String value) {
    setState(() {
      query = value;
      page = 1;
    });
    searchTimer?.cancel();
    searchTimer = Timer(const Duration(milliseconds: 400), load);
  }

  Widget recordRow(
    Json row, {
    List<String>? only,
    Map<String, String> extra = const {},
  }) {
    final rowActions =
        only ?? actions.keys.where((key) => available(key, row)).toList();
    final id = '${row['id']}';
    return PanelListItem(
      color: selected.contains(id)
          ? Theme.of(context).colorScheme.primaryContainer
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListTile(
            contentPadding: const EdgeInsetsDirectional.only(start: 24, end: 8),
            leading: Icon(
              selected.contains(id)
                  ? Icons.check_circle
                  : Icons.view_list_outlined,
            ),
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
                          PanelListItem(
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
                          PanelListItem(
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
      return const ScrollAwareScaffold(body: JoinCommunity());
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
    final pageActions = actions.entries
        .where(
          (entry) =>
              entry.key != 'list' &&
              entry.value['row'] == false &&
              entry.value['hidden'] != true &&
              !(section == 'account' &&
                  ['document', 'backup'].contains(entry.key) &&
                  optionalObject(data['profile'])['accountType'] !=
                      'academy') &&
              !(section == 'account' &&
                  entry.key == 'merge' &&
                  optionalObject(data['merges'])['eligible'] == false) &&
              !(section == 'classroom-categories' &&
                  entry.key == 'create' &&
                  optionalObject(data['permissions'])['canSetType'] == false) &&
              !(entry.key == 'create' &&
                  (data['can_create_branch'] == false ||
                      section == 'classroom-types' &&
                          optionalObject(data['permissions'])['canCreate'] ==
                              false)),
        )
        .toList();
    bool isAdd(MapEntry<String, dynamic> e) =>
        ['create', 'add', 'document', 'upload'].contains(e.key) ||
        '${e.value['label']}'.startsWith('افزودن');
    final additions = pageActions.where(isAdd).toList();
    final toolbar = <IconButton>[
      for (final e in pageActions.where((e) => !isAdd(e)))
        IconButton(
          tooltip: '${e.value['label']}',
          icon: const Icon(Icons.tune),
          onPressed: busy ? null : () => perform(e.key),
        ),
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
              await exportPanelPdf(title, exportRows, rtl: rtl, labels: labels);
            } catch (e) {
              if (mounted) socialError(this.context, e);
            }
          },
        ),
      if (widget.section['filters'] is List)
        IconButton(
          tooltip: socialText(context, 'فیلترها', 'Filters'),
          icon: const Icon(Icons.filter_list),
          onPressed: () async {
            final result = await Navigator.of(context).push<PanelFormResult>(
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
      IconButton(
        tooltip: socialText(context, 'به‌روزرسانی', 'Refresh'),
        onPressed: load,
        icon: const Icon(Icons.refresh),
      ),
    ];
    return ScrollAwareScaffold(
      appBar: AppTopBarDirection(
        child: AppBar(
          title: searchOpen
              ? TextField(
                  controller: searchInput,
                  autofocus: true,
                  onChanged: searchChanged,
                  decoration: InputDecoration(
                    hintText: socialText(context, 'جستجو', 'Search'),
                    border: InputBorder.none,
                  ),
                )
              : Text(
                  panelLabel(context, widget.section),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
          actions: [
            if (!searchOpen &&
                !loading &&
                error == null &&
                additions.length == 1)
              IconButton(
                tooltip: '${additions.single.value['label']}',
                icon: const Icon(Icons.add),
                onPressed: busy ? null : () => perform(additions.single.key),
              ),
            if (!searchOpen &&
                !loading &&
                error == null &&
                additions.length > 1)
              PopupMenuButton<String>(
                icon: const Icon(Icons.add),
                tooltip: socialText(context, 'افزودن', 'Add'),
                onSelected: perform,
                enabled: !busy,
                itemBuilder: (_) => [
                  for (final e in additions)
                    PopupMenuItem(
                      value: e.key,
                      child: Text('${e.value['label']}'),
                    ),
                ],
              ),
            if (collection is List || data['items'] is List || query.isNotEmpty)
              IconButton(
                tooltip: socialText(
                  context,
                  searchOpen ? 'بستن جستجو' : 'جستجو',
                  searchOpen ? 'Close search' : 'Search',
                ),
                icon: Icon(searchOpen ? Icons.close : Icons.search),
                onPressed: () {
                  setState(() => searchOpen = !searchOpen);
                  if (!searchOpen && query.isNotEmpty) {
                    searchInput.clear();
                    searchChanged('');
                  }
                },
              ),
            if (!searchOpen)
              PopupMenuButton<VoidCallback>(
                tooltip: socialText(context, 'گزینه‌های بیشتر', 'More options'),
                onSelected: (action) => action(),
                itemBuilder: (_) => [
                  for (final button in toolbar)
                    PopupMenuItem(
                      value: button.onPressed,
                      enabled: button.onPressed != null,
                      child: Row(
                        children: [
                          button.icon,
                          const SizedBox(width: 12),
                          Flexible(child: Text(button.tooltip ?? '')),
                        ],
                      ),
                    ),
                ],
              ),
          ],
        ),
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
              onRefresh: () => load(refresh: true),
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 16),
                children: [
                  if (busy) const LinearProgressIndicator(),
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
                  if (section == 'gallery' && filtered.isNotEmpty)
                    PanelGallery(
                      api: widget.api,
                      rows: filtered,
                      fields: objects(
                        optionalObject(actions['update'])['fields'] ?? [],
                      ),
                      data: data,
                      canEdit: actions.containsKey('update'),
                      canDelete: actions.containsKey('delete'),
                      onChanged: () => load(refresh: true),
                    )
                  else if (section == 'account') ...[
                    if (widget.accountArea == null) ...[
                      PanelProfileHeader(
                        profile: optionalObject(data['profile']),
                      ),
                      PanelDataView(value: data['profile']),
                    ],
                    if (widget.accountArea == 'privacy')
                      PanelDataView(
                        value: optionalObject(data['profile'])['privacy'],
                      ),
                    for (final pair in [
                      ('documents', ['download-media', 'delete-media']),
                      ('devices', ['end-session']),
                      ('merges.requests', ['cancel-merge', 'decide-merge']),
                    ])
                      if (widget.accountArea == null ||
                          widget.accountArea == pair.$1) ...[
                        for (final row
                            in (panelValue(data, pair.$1) is List
                                ? objects(panelValue(data, pair.$1))
                                : <Json>[]))
                          recordRow(row, only: pair.$2),
                        if (panelValue(data, pair.$1) is! List ||
                            (panelValue(data, pair.$1) as List).isEmpty)
                          Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              socialText(
                                context,
                                'موردی برای نمایش وجود ندارد.',
                                'No records to display.',
                              ),
                            ),
                          ),
                      ],
                    if ((widget.accountArea == null ||
                            widget.accountArea == 'documents') &&
                        data['backup'] is Map)
                      recordRow(
                        optionalObject(data['backup']),
                        only: ['download-backup'],
                      ),
                    if (widget.accountArea == null ||
                        widget.accountArea == 'loginHistory')
                      PanelDataView(value: data['loginHistory']),
                    if (widget.accountArea == null ||
                        widget.accountArea == 'securityAlerts')
                      PanelDataView(value: data['securityAlerts']),
                  ] else if (['dashboard', 'reports'].contains(section)) ...[
                    PanelStatistics(stats: optionalObject(data['stats'])),
                    const SizedBox(height: 16),
                    PanelDataView(
                      value: {...data}
                        ..remove('stats')
                        ..remove('branches'),
                    ),
                  ] else if (rows.isNotEmpty) ...[
                    for (final row in filtered) recordRow(row),
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
            PanelListItem(
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
    this.sendText,
  });
  final Future<Json> Function(String body)? sendText;
  final PanelApi api;
  final Json section, conversation;
  @override
  State<PanelConversationPage> createState() => _PanelConversationPageState();
}

class _PanelConversationPageState extends State<PanelConversationPage> {
  final text = TextEditingController();
  final composerFocus = FocusNode();
  Json? editing, replying;
  final selectedMessages = <int>{};
  List<double> voiceLevels = [];
  bool recordingVoice = false;
  Future<void> persist() =>
      ChatCache.write(widget.api.token, 'conversation:$id', messages);
  final scroll = ScrollController();
  void scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && scroll.hasClients)
        scroll.jumpTo(scroll.position.maxScrollExtent);
    });
  }

  List<Json> messages = [];
  PlatformFile? attachment;
  bool sending = false, loading = true, fetching = false;
  Object? error;
  bool hasMore = false;
  int historyCursor = 0;
  final pendingMessages = <int>{};
  String get id => '${widget.conversation['id']}';
  Json get actions => optionalObject(widget.section['actions']);
  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void dispose() {
    composerFocus.dispose();
    scroll.dispose();
    text.dispose();
    super.dispose();
  }

  Future<void> load({bool nextPage = false, bool refresh = false}) async {
    if (fetching) return;
    fetching = true;
    var haveSnapshot = messages.isNotEmpty;
    try {
      if (messages.isEmpty) {
        final saved = await ChatCache.read(
          widget.api.token,
          'conversation:$id',
        );
        if (mounted && saved is List) {
          haveSnapshot = true;
          setState(() {
            messages = objects(saved);
            loading = false;
          });
        }
      }
      // One batch per explicit action; never drain the entire history automatically.
      final after = nextPage ? historyCursor : 0;
      final data = await (refresh ? widget.api.refresh : widget.api.get)(
        '/chat/messages',
        {'id': id, 'after': '$after'},
      );
      final batch = objects(data['messages'] ?? []);
      // The aggregate includes local successful edits/deletions and later pages.
      // A stale response snapshot must never overwrite it while offline.
      if (data['_offline'] == true && haveSnapshot) {
        error = null;
        hasMore = false;
        return;
      }
      final result =
          <int, Json>{
              if (nextPage || data['_offline'] == true || batch.length == 200)
                for (final message in messages)
                  if (nextPage ||
                      data['_offline'] == true ||
                      number(message['id']) > number(batch.last['id']))
                    number(message['id']): message,
              for (final message in batch) number(message['id']): message,
            }.values.toList()
            ..sort((a, b) => number(a['id']).compareTo(number(b['id'])));
      if (batch.isNotEmpty) historyCursor = number(batch.last['id']);
      hasMore =
          batch.length == (after == 0 ? 200 : 100) &&
          number(batch.last['id']) > after;
      if (mounted) {
        setState(() {
          messages = result;
          scrollToEnd();
          error = null;
        });
      }
      await persist();
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
      if (editing != null) {
        final target = editing!;
        await widget.api.act(
          'chat',
          'edit-message',
          params: {'id': '${target['id']}'},
          values: {'body': text.text.trim()},
        );
        if (!mounted) return;
        setState(() {
          target['body'] = text.text.trim();
          target['edited'] = true;
          editing = null;
          text.clear();
        });
        await persist();
        return;
      }
      final sent =
          attachment == null && replying == null && widget.sendText != null
          ? await widget.sendText!(text.text.trim())
          : await widget.api.act(
              'chat',
              'send',
              params: {'id': id},
              values: {
                'body': text.text.trim(),
                if (replying != null) 'replyTo': replying!['id'],
              },
              files: {'file': ?attachment},
            );
      if (!mounted) return;
      text.clear();
      setState(() {
        attachment = null;
        replying = null;
      });
      final sentId = number(sent['id']);
      if (sentId > 0) {
        final result = await widget.api.get('/chat/messages', {
          'id': id,
          'after': '${sentId - 1}',
        });
        if (mounted)
          setState(() {
            final merged = <int, Json>{
              for (final m in messages) number(m['id']): m,
              for (final m in objects(result['messages'] ?? []))
                number(m['id']): m,
            };
            scrollToEnd();
            messages = merged.values.toList()
              ..sort((a, b) => number(a['id']).compareTo(number(b['id'])));
          });
      }
      await persist();
    } catch (e) {
      if (mounted) socialError(context, e);
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  Future<void> messageAction(String action, Json row) async {
    if (action == 'edit-message' || action == 'reply') {
      setState(() {
        editing = action == 'edit-message' ? row : null;
        replying = action == 'reply' ? row : null;
        attachment = null;
        if (editing != null) {
          text.text = '${row['body'] ?? ''}';
          text.selection = TextSelection.collapsed(offset: text.text.length);
        }
      });
      composerFocus.requestFocus();
      return;
    }
    final messageId = number(row['id']);
    if (pendingMessages.contains(messageId)) return;
    setState(() => pendingMessages.add(messageId));
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
        final confirmed = await confirmMediaDelete(
          context,
          socialText(context, 'پیام حذف شود؟', 'Delete message?'),
        );
        if (confirmed != true || !mounted) return;
      }
      final updated = await widget.api.act(
        'chat',
        action,
        params: {'id': '${row['id']}'},
        values: values,
      );
      if (mounted)
        setState(() {
          if (action == 'delete-message')
            messages.removeWhere((m) => m['id'] == row['id']);
          if (action == 'edit-message') {
            row['body'] = values['body'];
            row['edited'] = true;
          }
          if (action == 'like') row.addAll(updated);
        });
      await persist();
    } catch (e) {
      if (mounted) socialError(context, e);
    } finally {
      if (mounted) setState(() => pendingMessages.remove(messageId));
    }
  }

  Future<void> bulkAction(String action) async {
    if (sending) return;
    final rows = messages
        .where((m) => selectedMessages.contains(number(m['id'])))
        .toList();
    Json values = {};
    try {
      if (action == 'forward') {
        final options = await widget.api.get('/chat/list');
        if (!mounted) return;
        final result = await Navigator.push<PanelFormResult>(
          context,
          MaterialPageRoute(
            builder: (_) => PanelFormPage(
              title: socialText(context, 'ارسال پیام‌ها', 'Forward messages'),
              fields: objects(
                optionalObject(actions['forward'])['fields'] ?? [],
              ),
              data: options,
            ),
          ),
        );
        if (result == null) return;
        values = result.values;
      } else {
        if (rows.any((r) => r['mine'] != true)) return;
        final yes = await confirmMediaDelete(
          context,
          socialText(
            context,
            'پیام‌های انتخاب‌شده حذف شوند؟',
            'Delete selected messages?',
          ),
        );
        if (yes != true) return;
      }
      if (!mounted) return;
      setState(() => sending = true);
      for (final row in rows) {
        await widget.api.act(
          'chat',
          action,
          params: {'id': '${row['id']}'},
          values: values,
        );
        if (!mounted) return;
        setState(() {
          selectedMessages.remove(number(row['id']));
          if (action == 'delete-message') messages.remove(row);
        });
        await persist();
      }
    } catch (e) {
      if (mounted) socialError(context, e);
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthSession?>();
    if (auth != null && auth.token != widget.api.token) {
      return const ScrollAwareScaffold(body: JoinCommunity());
    }
    return ScrollAwareScaffold(
      appBar: AppTopBarDirection(
        child: AppBar(
          title: Text(panelTitle(widget.conversation)),
          actions: [
            if (selectedMessages.isNotEmpty) ...[
              Text('${selectedMessages.length}'),
              if (actions.containsKey('forward'))
                IconButton(
                  onPressed: () => bulkAction('forward'),
                  icon: const Icon(Icons.forward),
                ),
              if (actions.containsKey('delete-message') &&
                  messages
                      .where((m) => selectedMessages.contains(number(m['id'])))
                      .every((m) => m['mine'] == true))
                IconButton(
                  onPressed: () => bulkAction('delete-message'),
                  icon: const Icon(Icons.delete_outline),
                ),
              IconButton(
                onPressed: () => setState(selectedMessages.clear),
                icon: const Icon(Icons.close),
              ),
            ],
            if (widget.conversation['type'] == 'group' &&
                actions.containsKey('details'))
              IconButton(
                tooltip: socialText(
                  context,
                  'اطلاعات گفتگو',
                  'Conversation details',
                ),
                icon: const Icon(Icons.group_outlined),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => PanelGroupDetails(
                      api: widget.api,
                      section: widget.section,
                      id: id,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
      body: Column(
        children: [
          if (loading) const LinearProgressIndicator(),
          if (hasMore)
            TextButton(
              key: const ValueKey('panel-more-messages'),
              onPressed: fetching ? null : () => load(nextPage: true),
              child: Text(
                socialText(
                  context,
                  'نمایش پیام‌های بیشتر',
                  'Load more messages',
                ),
              ),
            ),
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
              controller: scroll,
              padding: const EdgeInsets.all(12),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final row = messages[index];
                final position = index;
                final day = messageDay(row);
                return Column(
                  children: [
                    if (day.isNotEmpty &&
                        (position == 0 ||
                            messageDay(messages[position - 1]) != day))
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Center(
                          child: Text(
                            day,
                            key: ValueKey('chat-day-$day'),
                            style: Theme.of(context).textTheme.labelMedium,
                          ),
                        ),
                      ),
                    ChatMessageBubble(
                      showSender: widget.conversation['type'] == 'group',
                      selected: selectedMessages.contains(number(row['id'])),
                      selectionMode: selectedMessages.isNotEmpty,
                      onLongPress: () => setState(() {
                        final mid = number(row['id']);
                        if (!selectedMessages.remove(mid))
                          selectedMessages.add(mid);
                      }),
                      message: row,
                      actions: actions,
                      busy: pendingMessages.contains(number(row['id'])),
                      onAction: (action) => messageAction(action, row),
                      attachment: ChatMedia(
                        key: ValueKey('chat-media-${row['id']}'),
                        api: widget.api,
                        message: row,
                        onDownload: () => messageAction('file', row),
                      ),
                    ),
                  ],
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (editing != null || replying != null)
                    ListTile(
                      dense: true,
                      leading: Icon(
                        editing != null ? Icons.edit_outlined : Icons.reply,
                      ),
                      title: Text(
                        '${(editing ?? replying)!['body'] ?? ''}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => setState(() {
                          if (editing != null) text.clear();
                          editing = null;
                          replying = null;
                        }),
                      ),
                    ),
                  Row(
                    children: [
                      IconButton(
                        tooltip: socialText(
                          context,
                          'پیوست فایل',
                          'Attach file',
                        ),
                        icon: const Icon(Icons.attach_file),
                        onPressed: sending || editing != null || recordingVoice
                            ? null
                            : () async {
                                final picked = await FilePicker.platform
                                    .pickFiles(withData: false);
                                if (mounted && picked != null) {
                                  setState(
                                    () => attachment = picked.files.single,
                                  );
                                }
                              },
                      ),
                      PanelVoiceButton(
                        enabled:
                            !sending && editing == null && attachment == null,
                        onRecorded: (file) => setState(() => attachment = file),
                        onRecording: (active) => setState(() {
                          recordingVoice = active;
                          if (!active) voiceLevels = [];
                        }),
                        onAmplitude: (value) => setState(() {
                          voiceLevels = [...voiceLevels, value];
                          if (voiceLevels.length > 45) voiceLevels.removeAt(0);
                        }),
                      ),
                      Expanded(
                        child: recordingVoice
                            ? SizedBox(
                                height: 36,
                                child: CustomPaint(
                                  painter: VoiceMessageWaveform(
                                    voiceLevels,
                                    Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              )
                            : TextField(
                                controller: text,
                                focusNode: composerFocus,
                                minLines: 1,
                                maxLines: 5,
                                decoration: InputDecoration(
                                  hintText: socialText(
                                    context,
                                    'پیام',
                                    'Message',
                                  ),
                                ),
                              ),
                      ),
                      IconButton(
                        onPressed: sending || recordingVoice ? null : send,
                        icon: sending
                            ? const CircularProgressIndicator()
                            : const Icon(Icons.send),
                      ),
                    ],
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
            data: {
              'users': data['availableUsers'] ?? [],
              'people': data['availableUsers'] ?? [],
            },
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
      return const ScrollAwareScaffold(body: JoinCommunity());
    }
    return ScrollAwareScaffold(
      appBar: AppTopBarDirection(
        child: AppBar(
          title: Text(
            socialText(context, 'اعضای گفتگو', 'Conversation members'),
          ),
          actions: [
            if (data['canManage'] == true && actions.containsKey('members'))
              IconButton(
                tooltip: socialText(context, 'افزودن عضو', 'Add member'),
                onPressed: busy ? null : () => perform('members'),
                icon: const Icon(Icons.person_add_alt),
              ),
          ],
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
                for (final member in objects(data['members'] ?? []))
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundImage: member['avatar'] == null
                            ? null
                            : NetworkImage(
                                Uri.parse(
                                  SocialApi.base,
                                ).resolve('${member['avatar']}').toString(),
                                headers: widget.api.headers,
                              ),
                        child: member['avatar'] == null
                            ? const Icon(Icons.person_outline)
                            : null,
                      ),
                      title: Text(panelTitle(member)),
                      subtitle: Text('${member['roleLabel'] ?? ''}'),
                      trailing:
                          data['canManage'] == true &&
                              member['isMe'] != true &&
                              member['role'] != 'admin' &&
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
