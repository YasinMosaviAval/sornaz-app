import 'package:sornaz/helpers/app_appearance.dart';
import '../Social/media_picker.dart';
import 'branches_page.dart';
import 'chat_message_bubble.dart';
import 'chat_cache.dart';
import 'chat_media.dart';
import 'panel_ui.dart';
import 'panel_access_badges.dart';
import 'panel_national_holiday_settings.dart';
import 'panel_term_attendance.dart';
import 'branch_style.dart';
import 'branch_export.dart';
import 'package:sornaz/components/app_top_bar_direction.dart';
import 'package:sornaz/components/expanding_search_bar.dart';
import 'dart:async';
import 'dart:convert';
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
import 'dart:math';
import 'panel_form_contract.dart';
import 'panel_presentation.dart';
import 'panel_table_contract.dart';
import 'panel_filter_contract.dart';
import 'panel_voice.dart';
import 'panel_list_item.dart';
import 'panel_gallery.dart';
import 'panel_organization_filter.dart';
import 'panel_finance.dart';
import 'panel_parity.dart';
import 'panel_schedule_week.dart';
import 'panel_schedule_contract.dart';
import 'panel_schedule_cancellation.dart';
import 'panel_dashboard.dart';
import 'panel_tracking.dart';
import 'panel_caption.dart';
import 'panel_web_contracts.dart';
import 'panel_page_guidance.dart';
import 'panel_section_card.dart';
import 'panel_account.dart';
import 'site_api.dart';
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
  State<PanelResourcePage> createState() => _PanelTabsState();
}

class _PanelTabsState extends State<PanelResourcePage>
    with SingleTickerProviderStateMixin {
  late final TabController controller;
  bool get gallery => [
    'gallery',
    'my-gallery',
  ].contains(widget.section['resourceKey'] ?? widget.section['key']);
  List<Json> get pageTabs => gallery
      ? [
          for (final category in panelGalleryCategories)
            {
              ...widget.section,
              'key': '${widget.section['key']}-${category.$1}',
              'resourceKey':
                  widget.section['resourceKey'] ?? widget.section['key'],
              'label': category.$2,
              'en': category.$3,
              'where': {'category': category.$1},
              'initialParams': {...widget.params, 'collection': category.$1},
            },
        ]
      : objects(widget.section['pageTabs'] ?? []);
  @override
  void initState() {
    super.initState();
    final tabs = pageTabs;
    final initial = tabs.indexWhere(
      (tab) => gallery
          ? optionalObject(tab['where'])['category'] ==
                (widget.params['collection'] ??
                    optionalObject(widget.section['where'])['category'] ??
                    'cover')
          : tab['key'] == widget.section['key'],
    );
    controller = TabController(
      length: tabs.isEmpty ? 1 : tabs.length,
      initialIndex: initial < 0 ? 0 : initial,
      vsync: this,
    );
    controller.addListener(changed);
  }

  void changed() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    controller.removeListener(changed);
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tabs = pageTabs;
    final initial = tabs.indexWhere(
      (tab) => tab['key'] == widget.section['key'],
    );
    final index = controller.index;
    final section = tabs.isEmpty ? widget.section : tabs[index];
    return _PanelResourceContent(
      key: ValueKey(gallery ? widget.section['key'] : section['key']),
      api: widget.api,
      section: section,
      titleSection: gallery
          ? {...widget.section, 'label': 'گالری', 'en': 'Gallery'}
          : widget.section,
      params: !gallery && index == (initial < 0 ? 0 : initial)
          ? widget.params
          : optionalObject(
              section['initialParams'],
            ).map((k, v) => MapEntry(k, '$v')),
      accountArea: widget.accountArea,
      tabs: tabs.length < 2
          ? null
          : TabBar(
              controller: controller,
              isScrollable: tabs.length > 3,
              tabAlignment: tabs.length > 3 ? TabAlignment.start : null,
              labelPadding: tabs.length > 3
                  ? const EdgeInsets.symmetric(horizontal: 12)
                  : EdgeInsets.zero,
              labelStyle: Theme.of(context).textTheme.labelLarge,
              tabs: [
                for (final tab in tabs) Tab(text: panelLabel(context, tab)),
              ],
            ),
    );
  }
}

class _PanelResourceContent extends StatefulWidget {
  const _PanelResourceContent({
    super.key,
    required this.api,
    required this.section,
    required this.titleSection,
    required this.params,
    this.accountArea,
    this.tabs,
  });
  final PanelApi api;
  final Json section;
  final Json titleSection;
  final Map<String, String> params;
  final String? accountArea;
  final Widget? tabs;
  @override
  State<_PanelResourceContent> createState() => _PanelResourcePageState();
}

class _PanelResourcePageState extends State<_PanelResourceContent>
    with WidgetsBindingObserver {
  Map<String, String> get scheduleOrganizations => {
    '': socialText(context, 'همه', 'All'),
    ...panelOrganizationOptions(
      data,
      objects(data['schedules'] ?? []),
      fa: Localizations.localeOf(context).languageCode == 'fa',
      includeFixedScope: true,
    ),
  };
  Widget pendingContent(Widget child) => Column(
    children: [
      if (widget.tabs != null) widget.tabs!,
      if (section == 'schedules')
        DefaultTabController(
          key: ValueKey(
            'schedule-organizations-${scheduleOrganizations.keys.join(',')}-$organizationFilter',
          ),
          length: scheduleOrganizations.length,
          initialIndex: max(
            0,
            scheduleOrganizations.keys.toList().indexOf(organizationFilter),
          ),
          child: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelPadding: const EdgeInsets.symmetric(horizontal: 12),
            labelStyle: Theme.of(context).textTheme.labelLarge,
            onTap: (index) {
              final organization = scheduleOrganizations.keys.elementAt(index);
              if (organizationFilter == organization) return;
              setState(() {
                organizationFilter = organization;
                loading = true;
                page = 1;
                localPage = 1;
              });
              load();
            },
            tabs: [
              for (final label in scheduleOrganizations.values)
                Tab(text: label),
            ],
          ),
        ),
      Expanded(child: child),
    ],
  );

  Json data = {}, filters = {};
  bool loading = true, busy = false;
  Object? error;
  String query = '';
  String organizationFilter = '';
  int page = 1, generation = 0;
  int activeLoads = 0;
  int localPage = 1, pageSize = 10;
  String sortKey = '';
  bool sortAscending = true;
  bool weekly = false;
  final schedulePreferences = PanelSchedulePreferences();
  DateTime? firstScheduleWeek, lastScheduleWeek;
  DateTime weekStart = panelWeekStart(DateTime.now());
  Timer? searchTimer;
  Timer? refreshTimer;
  StreamSubscription<String>? mutationSubscription;
  @override
  void dispose() {
    searchTimer?.cancel();
    refreshTimer?.cancel();
    mutationSubscription?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    generation++;
    super.dispose();
  }

  final selected = <String>{};
  String get section =>
      '${widget.section['resourceKey'] ?? widget.section['key']}';
  bool get gallerySection => section == 'gallery' || section == 'my-gallery';
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
    WidgetsBinding.instance.addObserver(this);
    weekly = section == 'schedules';
    mutationSubscription = widget.api.mutations.listen((resource) {
      if (['branches', 'academies', 'account'].contains(resource) && mounted) {
        unawaited(load(refresh: true));
      }
    });
    if (!['branches', 'branch-types'].contains(section)) load();
    refreshTimer = Timer.periodic(
      const Duration(seconds: 3),
      (_) => refreshVisible(),
    );
  }

  void refreshVisible() {
    final auth = mounted ? context.read<AuthSession?>() : null;
    if (!mounted ||
        (auth != null && auth.token != widget.api.token) ||
        busy ||
        activeLoads > 0 ||
        selected.isNotEmpty ||
        loading ||
        ['branches', 'branch-types'].contains(section) ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.paused ||
        ModalRoute.of(context)?.isCurrent != true)
      return;
    unawaited(load(refresh: true, background: true));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) refreshVisible();
  }

  Future<void> load({bool refresh = false, bool background = false}) async {
    final request = ++generation;
    activeLoads++;
    try {
      final value = weekly && section == 'schedules'
          ? await loadWeek(refresh, background: background)
          : await (background
                ? widget.api.live
                : refresh
                ? widget.api.refresh
                : widget.api.get)('/$section/list', {
              ...widget.params,
              ...panelFilterQuery(
                panelWebFilters(widget.section, data, const []),
                filters,
                organizationFilter,
                section,
              ),
              if (!widget.params.containsKey('page')) 'page': '$page',
              'perPage': sortKey.isEmpty ? '$pageSize' : '100',
              if (section == 'my-points') 'history': '1',
              if (query.trim().isNotEmpty) ...{
                'q': query.trim(),
                'search': query.trim(),
              },
            });
      if (sortKey.isNotEmpty &&
          value['total'] != null &&
          value['perPage'] != null) {
        final path = '${widget.section['rows'] ?? 'items'}';
        final combined = objects(panelValue(value, path) ?? []);
        var next = page + 1;
        // A sort starts at page one and covers the complete authorized result.
        while (combined.length <
            (num.tryParse('${value['total']}') ?? combined.length)) {
          if (!mounted || request != generation) return;
          final response =
              await (refresh
                  ? widget.api.refresh
                  : widget.api.get)('/$section/list', {
                ...widget.params,
                ...panelFilterQuery(
                  panelWebFilters(widget.section, data, const []),
                  filters,
                  organizationFilter,
                  section,
                ),
                'page': '$next',
                'perPage': '100',
                if (query.trim().isNotEmpty) 'q': query.trim(),
                if (query.trim().isNotEmpty) 'search': query.trim(),
              });
          final chunk = objects(panelValue(response, path) ?? []);
          if (chunk.isEmpty)
            throw const SocialException(
              'دریافت همهٔ ردیف‌ها برای مرتب‌سازی کامل نشد.',
            );
          combined.addAll(chunk);
          next++;
        }
        if (path.contains('.'))
          throw const SocialException('مرتب‌سازی این مجموعه در دسترس نیست.');
        value[path] = combined;
        value['total'] = null;
        value['perPage'] = null;
      }
      for (final option
          in widget.section['optionActions'] as List? ?? const []) {
        value.addAll(
          await (background || refresh ? widget.api.live : widget.api.get)(
            '/$section/$option',
            widget.params,
          ),
        );
      }
      value['branchContext'] =
          value['branchContext'] == true ||
          widget.api.branchContext ||
          widget.section['branchContext'] == true;
      if (section == 'terms') {
        final options = await (background || refresh
            ? widget.api.live
            : widget.api.get)('/courses/list');
        value.addAll(panelTermOptionData(value, options));
      }
      if (section == 'finance') {
        var subscriptions = optionalObject(value['subscriptions']);
        if (subscriptions.isEmpty &&
            value['subscriptionUnavailable'] != true &&
            actions.containsKey('subscriptions')) {
          try {
            subscriptions = await widget.api.get('/finance/subscriptions');
          } catch (error) {
            if (error is SocialException && error.status == 401) rethrow;
            value['subscriptionUnavailable'] = true;
          }
        }
        value['subscriptionUnavailable'] = subscriptions.isEmpty;
        value['invoices'] = [
          for (final invoice in objects(value['invoices'] ?? []))
            {
              ...invoice,
              'title': invoice['termName'],
              'type': 'فاکتور ترم',
              'dateIso': invoice['dueDate'],
              'date': invoice['dueDate'],
            },
          ...panelSubscriptionRows(subscriptions),
        ];
        value['subscriptionPlans'] = subscriptions['plans'];
      }
      if (mounted && request == generation) {
        final rowsPath = '${widget.section['rows'] ?? 'items'}';
        final previousRows = panelValue(data, rowsPath);
        final nextRows = panelValue(value, rowsPath);
        final changed =
            background &&
            previousRows != null &&
            jsonEncode(previousRows) != jsonEncode(nextRows);
        setState(() {
          data = value;
          error = null;
          selected.clear();
        });
        if (changed) {
          final before = previousRows is List ? previousRows.length : 0;
          final after = nextRows is List ? nextRows.length : 0;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                socialText(
                  context,
                  after > before
                      ? 'سطر جدید اضافه شد.'
                      : after < before
                      ? 'سطر حذف شد.'
                      : 'تغییرات سطرها اعمال شد.',
                  after > before
                      ? 'A row was added.'
                      : after < before
                      ? 'A row was removed.'
                      : 'Rows were updated.',
                ),
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted &&
          request == generation &&
          (!background ||
              e is SocialException && [401, 403].contains(e.status))) {
        setState(() => error = e);
      }
    } finally {
      activeLoads--;
      if (mounted && request == generation) setState(() => loading = false);
    }
  }

  Future<Json> loadWeek(bool refresh, {bool background = false}) async {
    final combined = <Json>[];
    final requestGeneration = generation;
    final selectedFilters = panelFilterQuery(
      panelWebFilters(widget.section, data, const []),
      filters,
      organizationFilter,
      section,
    );
    final search = query;
    if (actions.containsKey('week-bounds')) {
      final bounds = await widget.api.get('/schedules/week-bounds', {
        if (selectedFilters['branch'] != null)
          'branch': selectedFilters['branch']!,
      });
      if (!mounted || requestGeneration != generation)
        throw const SocialException('درخواست برنامه تغییر کرده است.');
      final first = DateTime.tryParse('${bounds['firstDate']}');
      final last = DateTime.tryParse('${bounds['lastDate']}');
      firstScheduleWeek = first == null ? null : panelWeekStart(first);
      lastScheduleWeek = last == null ? null : panelWeekStart(last);
      if (firstScheduleWeek != null && weekStart.isBefore(firstScheduleWeek!))
        weekStart = firstScheduleWeek!;
      if (lastScheduleWeek != null && weekStart.isAfter(lastScheduleWeek!))
        weekStart = lastScheduleWeek!;
    }
    final start = weekStart;
    Json result = {};
    for (var day = 0; day < 7; day++) {
      var next = 1;
      while (true) {
        if (!mounted || requestGeneration != generation)
          throw const SocialException('درخواست برنامه تغییر کرده است.');
        final response =
            await (background
                ? widget.api.live
                : refresh
                ? widget.api.refresh
                : widget.api.get)('/schedules/list', {
              ...selectedFilters,
              'day': '',
              'date': start
                  .add(Duration(days: day))
                  .toIso8601String()
                  .substring(0, 10),
              'perPage': '100',
              'page': '$next',
              'search': search,
            });
        final chunk = objects(response['schedules'] ?? []);
        combined.addAll(chunk);
        result = response;
        final total = num.tryParse('${response['total']}') ?? chunk.length;
        final actualPageSize = num.tryParse('${response['perPage']}') ?? 100;
        if (next * actualPageSize >= total) break;
        if (chunk.isEmpty)
          throw const SocialException('دریافت برنامهٔ هفتگی کامل نشد.');
        next++;
      }
    }
    return {...result, 'schedules': combined, 'total': null, 'perPage': null};
  }

  bool available(String key, Json record) {
    if (section == 'schedules' && key == 'cancel')
      return panelScheduleCanCancel(record);
    if (section == 'terms' && key == 'available-times') return false;
    final exposed = tableContract['rowActions'];
    if (exposed is List && key != 'status' && !exposed.contains(key)) {
      return false;
    }
    if (key == 'list' || !actions.containsKey(key)) return false;
    final action = optionalObject(actions[key]);
    if (action['hidden'] == true) return false;
    if (action['permissionField'] is String &&
        record[action['permissionField']] == false) {
      return false;
    }
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
    if (['update', 'roles', 'permissions'].contains(key) &&
            record['canEdit'] == false ||
        key == 'delete' &&
            record['canDelete'] == false &&
            !(section == 'lessons' &&
                record['canInspectDependencies'] == true) ||
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
    if (section == 'terms' && key == 'assign-student') {
      if (!['open', 'pending'].contains(record['status_code'])) return false;
      if (record['canAssignStudent'] is bool)
        return record['canAssignStudent'] == true;
      final course = objects(
        data['courses'] ?? [],
      ).where((row) => '${row['id']}' == '${record['courseId']}').firstOrNull;
      final capacity =
          num.tryParse(
            '${record['studentCapacity'] ?? course?['student_capacity'] ?? 1}',
          ) ??
          1;
      return objects(record['students'] ?? []).length < capacity;
    }
    if (section == 'terms' && key == 'attendance')
      return objects(record['students'] ?? []).isNotEmpty;
    if (section == 'terms' && key == 'classroom') {
      return objects(record['students'] ?? []).isNotEmpty &&
          ['open', 'pending', 'ongoing'].contains(record['status_code']);
    }
    if (section == 'finance' && record['invoiceKind'] == 'subscription')
      return false;
    if (section == 'finance' && ['pay', 'offline'].contains(key)) return false;
    return true;
  }

  Future<void> perform(
    String key, [
    Json record = const {},
    Map<String, String> extra = const {},
  ]) async {
    if (busy) return;
    if (section == 'lessons' && key == 'usage') {
      await showLessonUsage(record);
      return;
    }
    if (section == 'lessons' &&
        key == 'delete' &&
        record['canDelete'] == false &&
        record['canInspectDependencies'] == true) {
      await showLessonUsage(record);
      return;
    }
    final action = optionalObject(actions[key]);
    if (action.isEmpty) return;
    if (section == 'schedules' && key == 'cancel') {
      final saved = await showDialog<bool>(
        context: context,
        builder: (_) =>
            PanelScheduleCancellation(api: widget.api, session: record),
      );
      if (saved == true && mounted) await load(refresh: true);
      return;
    }
    if (section == 'terms' && key == 'attendance') {
      await showDialog<void>(
        context: context,
        builder: (_) =>
            PanelTermAttendance(api: widget.api, termId: '${record['id']}'),
      );
      return;
    }
    var formData = {...data};
    if (section == 'terms' && key == 'assign-student') {
      setState(() => busy = true);
      try {
        formData = {
          ...data,
          ...await widget.api.live('/students/list'),
          ...await widget.api.live('/students/options'),
        };
      } catch (error) {
        if (mounted) socialError(context, error);
        return;
      } finally {
        if (mounted) setState(() => busy = false);
      }
      if (!mounted) return;
    }
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
      if (section == 'schedules') 'termId': '${record['termId']}',
    };
    if (action['recordAction'] is String) {
      setState(() => busy = true);
      try {
        record = {
          ...record,
          ...await widget.api.get(
            '/$section/${action['recordAction']}',
            params,
          ),
        };
      } catch (e) {
        if (mounted) socialError(context, e);
        return;
      } finally {
        if (mounted) setState(() => busy = false);
      }
      if (!mounted) return;
    }
    var fields = action['fields'] is List
        ? objects(action['fields'])
        : <Json>[];
    if (section == 'term-discounts' &&
        key == 'update' &&
        (num.tryParse('${record['organizationUserId']}') ?? 0) > 0) {
      fields = [
        for (final field in fields)
          {
            ...field,
            if (field['key'] == 'organizationUserId') 'readOnly': true,
          },
      ];
    }
    if (section == 'terms') fields = panelTermDialogFields(fields);
    if (section == 'terms' && key == 'update') {
      fields = panelTermEditFields(
        fields,
        record,
        canCompleteTeachers:
            optionalObject(data['permissions'])['isReceptionist'] != true,
      );
    }
    if (section == 'posts' &&
        action['formContractVersion'] != 2 &&
        ['create', 'update', 'edit'].contains(key) &&
        !fields.any((field) => field['key'] == 'poll_options')) {
      fields.addAll([
        {
          'key': 'poll_question',
          'label': 'پرسش نظرسنجی',
          'en': 'Poll question',
          'type': 'text',
          'required': false,
        },
        {
          'key': 'poll_options',
          'label': 'گزینه‌های نظرسنجی',
          'en': 'Poll options',
          'type': 'strings',
          'required': false,
          'options': {
            'help': 'برای فعال شدن نظرسنجی حداقل دو گزینه وارد کنید.',
          },
        },
      ]);
    }
    var initial = <String, dynamic>{...record, ...widget.params};
    if (section == 'terms' && key == 'batch') {
      initial['requestKey'] = List.generate(
        16,
        (_) => Random.secure().nextInt(256).toRadixString(16).padLeft(2, '0'),
      ).join();
    }
    if (section == 'account' && action['row'] != true) {
      initial = {...optionalObject(data['profile'])};
    }
    if (key == 'privacy') initial = {...optionalObject(initial['privacy'])};
    if (section == 'settings') initial = {...data};
    if (gallerySection && key == 'create') {
      initial = {...widget.params};
      final owners = objects(data['owners'] ?? []);
      final owner =
          owners
              .where(
                (owner) => organizationFilter == 'academy'
                    ? owner['kind'] == 'academy'
                    : organizationFilter == 'owner:${owner['userId']}',
              )
              .firstOrNull ??
          owners.firstOrNull;
      if (owner != null) initial['ownerId'] = owner['userId'];
    }
    if (action['initialSources'] is List) {
      initial = {
        for (final source in action['initialSources'] as List)
          ...optionalObject(panelValue(data, '$source')),
      };
    }
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
    if (section == 'availability-exceptions' && key != 'create') {
      initial['targetValue'] =
          record['targetValue'] ??
          (record['membershipId'] != null
              ? 'member:${record['membershipId']}'
              : 'organization:${record['organizationUserId']}');
    }
    if (section == 'polls' && key == 'update' && initial['options'] is List) {
      initial['options'] = (initial['options'] as List)
          .map((v) => v is Map ? '${v['label']}' : v)
          .toList();
    }
    PanelFormResult? result;
    Json? submittedResponse;
    formData.addAll({'record': record, 'operation': key});
    if (fields.isNotEmpty) {
      result = await showDialog<PanelFormResult>(
        context: context,
        builder: (_) => PanelFormPage(
          dialog: true,
          lookupMemberUser:
              ((['students', 'members'].contains(section) && key == 'create') ||
                  (section == 'terms' && key == 'assign-student'))
              ? (values, query) async {
                  final course = objects(formData['courses'] ?? [])
                      .where((row) => '${row['id']}' == '${record['courseId']}')
                      .firstOrNull;
                  return widget.api.act(
                    section == 'members' ? 'members' : 'students',
                    'user-lookup',
                    values: {
                      'organizationUserId':
                          values['organizationUserId'] ??
                          course?['organizationUserId'],
                      'query': query,
                    },
                  );
                }
              : null,
          previewStudentSchedule:
              fields.any((field) => field['key'] == 'studentSchedule')
              ? (values) => widget.api.act(
                  'terms',
                  'schedule-preview',
                  params: {'id': '${values['termId'] ?? record['id']}'},
                  values: optionalObject(values['studentSchedule']),
                )
              : null,
          loadOptions:
              section == 'terms' ||
                  fields.any(
                    (field) => RegExp(
                      r'organization|branch|academy|owner',
                      caseSensitive: false,
                    ).hasMatch(jsonEncode(field)),
                  )
              ? () async {
                  final latest = await widget.api.live(
                    '/$section/list',
                    widget.params,
                  );
                  for (final option
                      in widget.section['optionActions'] as List? ?? const []) {
                    latest.addAll(
                      await widget.api.live('/$section/$option', widget.params),
                    );
                  }
                  if (section == 'terms') {
                    latest.addAll(
                      panelTermOptionData(
                        latest,
                        await widget.api.live('/courses/list'),
                      ),
                    );
                  }
                  if (section == 'terms' && key == 'assign-student') {
                    latest.addAll(await widget.api.live('/students/options'));
                  }
                  // Submit and availability callbacks must use the same catalogs
                  // as the open form, including newly created organizations.
                  formData.addAll(latest);
                  return {
                    for (final name in [
                      'organizations',
                      'branches',
                      'academies',
                      'owners',
                      'classrooms',
                      'courses',
                      'members',
                      'staff_catalog',
                      'terms',
                      'currencies',
                      'discounts',
                      'permissions',
                    ])
                      if (latest.containsKey(name)) name: latest[name],
                  };
                }
              : null,
          declaredOnly:
              action['formContractVersion'] == 2 ||
              action['strictFields'] == true,
          title: gallerySection && key == 'create'
              ? panelGalleryAddTitle(
                  widget.params['collection'] ?? 'gallery',
                  fa: Localizations.localeOf(context).languageCode == 'fa',
                )
              : panelLabel(context, action),
          suggestedTitle: gallerySection && key == 'create'
              ? (values) => panelGallerySuggestedTitle(values, {
                  ...data,
                  '_ownerName': context.read<AuthSession?>()?.user?.fullName,
                }, fa: Localizations.localeOf(context).languageCode == 'fa')
              : null,
          submitButtons: objects(action['submitButtons'] ?? []),
          loadBatchTimes: section == 'terms' && key == 'batch'
              ? (values) async {
                  final organization = objects(formData['organizations'] ?? [])
                      .where(
                        (row) =>
                            '${row['user_id']}' ==
                            '${values['organizationUserId']}',
                      )
                      .firstOrNull;
                  if (organization == null || values['weekday'] == null) {
                    return {};
                  }
                  final room = objects(formData['classrooms'] ?? [])
                      .where(
                        (row) => '${row['id']}' == '${values['classroomId']}',
                      )
                      .firstOrNull;
                  final result = await widget.api.get('/terms/available-times', {
                    'branch':
                        '${room?['branchId'] ?? (organization['kind'] == 'branch' ? organization['id'] : 0)}',
                    'academy':
                        '${organization['kind'] == 'academy' ? organization['id'] : organization['academyId'] ?? 0}',
                    'weekday': '${values['weekday']}',
                    'duration': '5',
                  });
                  return result;
                }
              : null,
          onRequestCode:
              section == 'members' &&
                  key == 'create' &&
                  actions.containsKey('registration-otp')
              ? (result) async {
                  await widget.api.act(
                    section,
                    'registration-otp',
                    values: panelDialogPayload(
                      section,
                      key,
                      result.values,
                      formData,
                    ),
                  );
                  if (mounted)
                    ScaffoldMessenger.of(this.context).showSnackBar(
                      SnackBar(
                        content: Text(
                          socialText(
                            this.context,
                            'کد ارسال شد؛ کد را وارد و ثبت‌نام را نهایی کنید.',
                            'Code sent. Enter it to complete registration.',
                          ),
                        ),
                      ),
                    );
                }
              : null,
          onSubmit:
              action['formContractVersion'] == 2 && action['method'] == 'POST'
              ? (result) async {
                  submittedResponse = await widget.api.act(
                    section,
                    key,
                    values: panelDialogPayload(
                      section,
                      key,
                      result.values,
                      formData,
                    ),
                    params: params,
                    files: result.files,
                  );
                }
              : null,
          fields: [
            for (final field in fields)
              if (['finance', 'my-finance'].contains(section) &&
                  [
                    'status',
                    'statusCode',
                    'status_code',
                  ].contains(field['key']))
                panelInvoiceStatusField(field)
              else if (gallerySection && field['type'] == 'file')
                {
                  ...field,
                  'mediaPicker': true,
                  'imagesOnly': [
                    'cover',
                    'logo',
                  ].contains(widget.params['collection']),
                }
              else if (gallerySection && field['key'] == 'collection')
                {
                  ...field,
                  'label': 'نوع رسانه',
                  'en': 'Media type',
                  'readOnly': key == 'create',
                }
              else if (field['key'] == 'founded' &&
                  optionalObject(data['profile'])['accountType'] == 'human')
                {...field, 'label': 'تاریخ تولد', 'en': 'Date of birth'}
              else
                field,
          ],
          data: {
            ...formData,
            'operation': key,
            'record': record,
            if (section == 'polls') 'options': record['options'],
            if (section == 'schedules') 'attendance': record['attendance'],
            if (section == 'schedules')
              'canWriteTeacherNote': record['canWriteTeacherNote'],
          },
          initial: section == 'terms' && key == 'assign-student'
              ? {
                  'organizationUserId': objects(data['courses'] ?? [])
                      .where(
                        (course) =>
                            '${course['id']}' == '${record['courseId']}',
                      )
                      .firstOrNull?['organizationUserId'],
                }
              : key == 'create' && !gallerySection
              ? {...widget.params}
              : initial,
        ),
      );
      if (result == null || !mounted) return;
      if (action['queryFields'] == true) {
        final visibleFields = fields.where(
          (field) => panelFieldVisible(field, {...data, 'record': record}),
        );
        for (final field in visibleFields) {
          final key = '${field['key']}';
          final value = result.values[key];
          if (value != null && '$value'.isNotEmpty) params[key] = '$value';
        }
      }
      for (final entry in optionalObject(action['params']).entries) {
        final value = result.values['${entry.value}'];
        if (value != null) params[entry.key] = '$value';
      }
    } else if (action['method'] != 'GET') {
      final confirmed = await showPanelConfirmation(
        context,
        panelLabel(context, action),
        message: panelTitle(record),
        delete: key.contains('delete') || key.contains('remove'),
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
              builder: (_) => PanelScaffold(
                appBar: AppTopBarDirection(
                  child: AppBar(title: Text('${action['label']}')),
                ),
                body: SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: PanelDataView(value: detail),
                ),
              ),
            ),
          );
        }
      } else {
        final response =
            submittedResponse ??
            await widget.api.act(
              section,
              key,
              values: action['strictFields'] == true
                  ? {
                      for (final field in fields)
                        if (result?.values.containsKey('${field['key']}') ==
                            true)
                          '${field['key']}': result!.values['${field['key']}'],
                    }
                  : action['formContractVersion'] == 2
                  ? panelDialogPayload(
                      section,
                      key,
                      result?.values ?? {},
                      formData,
                    )
                  : result?.values ?? {},
              params: params,
              files: result?.files ?? {},
            );
        final paymentUrl =
            response['paymentUrl'] ??
            response['redirectUrl'] ??
            response['url'];
        if (key == 'chat' &&
            ['waiting-approvals', 'waiting-schedules'].contains(section)) {
          final id = '${response['conversationId'] ?? ''}';
          final catalog = await widget.api.get('');
          final chat = objects(
            catalog['sections'] ?? [],
          ).where((row) => row['key'] == 'chat').firstOrNull;
          final inbox = await widget.api.get('/chat/list');
          final conversation = objects(
            inbox['conversations'] ?? [],
          ).where((row) => '${row['id']}' == id).firstOrNull;
          if (chat == null || conversation == null)
            throw const SocialException('گفتگوی ثبت‌نام در دسترس نیست.');
          if (!mounted) return;
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => PanelConversationPage(
                api: widget.api,
                section: chat,
                conversation: conversation,
              ),
            ),
          );
        }
        if (['pay'].contains(key) && paymentUrl is String) {
          final uri = SiteApi.origin.resolve(paymentUrl);
          if (uri.scheme == 'https') {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        }
        await load();
        if (mounted && section == 'terms' && key == 'assign-student') {
          setState(() => busy = false);
          final updated = objects(
            panelValue(data, '${widget.section['rows'] ?? 'items'}') ?? [],
          ).where((row) => '${row['id']}' == '${record['id']}').firstOrNull;
          await perform(
            'classroom',
            updated ??
                {
                  ...record,
                  'students': [<String, dynamic>{}],
                },
          );
        }
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                socialText(context, 'تغییرات اعمال شد.', 'Changes applied.'),
              ),
            ),
          );
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

  Future<void> showLessonUsage(Json record) async {
    setState(() => busy = true);
    try {
      final usage = await widget.api.get('/lessons/usage', {
        ...widget.params,
        'id': '${record['id']}',
      });
      if (!mounted) return;
      setState(() => busy = false);
      await showDialog<void>(
        context: context,
        builder: (c) => PanelModal(
          title: socialText(c, 'محل‌های استفاده از درس', 'Lesson usage'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final group in const {
                'courses': 'دوره‌ها',
                'contracts': 'قراردادهای اساتید',
              }.entries)
                if (objects(usage[group.key] ?? []).isNotEmpty) ...[
                  Text(
                    '${group.value} (${objects(usage[group.key]).length})',
                    style: Theme.of(c).textTheme.titleSmall,
                  ),
                  for (final row in objects(usage[group.key]))
                    PanelListItem(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              panelTableText(row['title']),
                              style: Theme.of(c).textTheme.labelLarge,
                            ),
                            if (row['teacher'] != null)
                              Text(panelTableText(row['teacher'])),
                            Text(panelTableText(row['organization'])),
                          ],
                        ),
                      ),
                    ),
                ],
              if (objects(usage['courses'] ?? []).isEmpty &&
                  objects(usage['contracts'] ?? []).isEmpty)
                Text(
                  socialText(
                    c,
                    'این درس در دوره یا قراردادی استفاده نشده است.',
                    'This lesson is not used in any course or contract.',
                  ),
                ),
              TextButton(
                onPressed: () => Navigator.pop(c),
                child: Text(socialText(c, 'بستن', 'Close')),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      if (mounted) socialError(context, e);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  void searchChanged(String value) {
    setState(() {
      query = value;
      page = 1;
      localPage = 1;
    });
    searchTimer?.cancel();
    searchTimer = Timer(const Duration(milliseconds: 400), load);
  }

  Future<void> openRecord(Json row) async {
    final id = '${row['id']}';
    if (selected.isNotEmpty) {
      setState(() {
        selected.contains(id) ? selected.remove(id) : selected.add(id);
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
    if (actions['details'] is Map && actions['details']['method'] == 'GET') {
      setState(() => busy = true);
      try {
        row = {
          ...row,
          ...await widget.api.get('/$section/details', {
            ...widget.params,
            'id': id,
          }),
        };
      } catch (e) {
        if (mounted) socialError(context, e);
        return;
      } finally {
        if (mounted) setState(() => busy = false);
      }
      if (!mounted) return;
    }
    await showDialog<void>(
      context: context,
      builder: (context) => PanelModal(
        title: '${tableContract['detailTitle'] ?? panelTitle(row)}',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PanelRecordFields(
              fields: panelTableColumns({
                'columns': panelRecordDetailFields(widget.section),
              }, data),
              row: panelDisplayRow(section, row, data),
              data: {...data, '_section': section},
            ),
            if (section == 'terms')
              for (final session
                  in (row['sessions'] is List
                      ? objects(row['sessions'])
                      : <Json>[]))
                PanelListItem(
                  child: Column(
                    children: [
                      PanelRecordFields(
                        row: session,
                        fields: const [
                          {'key': 'date', 'label': 'تاریخ جلسه'},
                          {'key': 'startTime', 'label': 'ساعت شروع'},
                          {'key': 'endTime', 'label': 'ساعت پایان'},
                          {'key': 'status', 'label': 'وضعیت'},
                          {'key': 'reason', 'label': 'دلیل لغو'},
                        ],
                      ),
                      Wrap(
                        children: [
                          for (final key in [
                            'cancel',
                            'cancel-approve',
                            'cancel-reject',
                            'restore',
                          ])
                            if (actions.containsKey(key) &&
                                panelSessionAction(
                                  key,
                                  session,
                                  optionalObject(data['permissions']),
                                ))
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  perform(key, row, {
                                    'sessionId':
                                        '${session['id'] ?? session['sessionId']}',
                                  });
                                },
                                child: Text('${actions[key]['label']}'),
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
                      PanelRecordFields(
                        row: installment,
                        fields: const [
                          {'key': 'number', 'label': 'شماره قسط'},
                          {'key': 'amount', 'label': 'مبلغ'},
                          {'key': 'dueDate', 'label': 'سررسید'},
                          {'key': 'status', 'label': 'وضعیت'},
                        ],
                      ),
                      Wrap(
                        children: [
                          for (final key in ['pay', 'offline'])
                            if (actions.containsKey(key) &&
                                panelPayableInstallment(row, installment))
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  perform(key, row, {
                                    'invoiceId': '${row['id']}',
                                    'installmentId': '${installment['id']}',
                                  });
                                },
                                child: Text('${actions[key]['label']}'),
                              ),
                        ],
                      ),
                    ],
                  ),
                ),
            Wrap(
              spacing: 8,
              children: [
                if (section == 'schedules')
                  for (final key in ['cancel', 'attendance'])
                    if (actions.containsKey(key) && available(key, row))
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          perform(key, row);
                        },
                        child: Text(
                          panelLabel(context, optionalObject(actions[key])),
                        ),
                      ),
                if (available('update', row))
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      perform('update', row);
                    },
                    child: Text(socialText(context, 'ویرایش', 'Edit')),
                  ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(socialText(context, 'بستن', 'Close')),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Json get tableContract => panelTableContract(widget.section);

  Future<void> changeStatus(Json row, String action) async {
    if (busy || !available(action, row)) return;
    setState(() => busy = true);
    try {
      await widget.api.act(
        section,
        action,
        params: {...widget.params, 'id': '${row['id']}'},
      );
      if (mounted) await load();
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              socialText(context, 'وضعیت به‌روز شد.', 'Status updated.'),
            ),
          ),
        );
    } catch (e) {
      if (mounted) socialError(context, e);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Widget recordTable(List<Json> rows, {int offset = 0}) {
    final contract = tableContract;
    final columns = panelTableColumns(contract, data);
    final effectiveColumns = columns.isEmpty
        ? <Json>[
            {'key': 'title', 'label': socialText(context, 'عنوان', 'Title')},
            if (rows.any((row) => row.containsKey('status')))
              {
                'key': 'status',
                'label': socialText(context, 'وضعیت', 'Status'),
                'action': 'status',
              },
          ]
        : columns;
    final rowActions =
        contract['rowActions'] as List? ??
        ['details', ...actions.keys.where((key) => key != 'status')];
    final showActions =
        contract['showActions'] != false &&
        (contract['actionsPermission'] == null ||
            panelValue(data, '${contract['actionsPermission']}') == true);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        sortAscending: sortAscending,
        sortColumnIndex:
            effectiveColumns.indexWhere((c) => c['key'] == sortKey) < 0
            ? null
            : effectiveColumns.indexWhere((c) => c['key'] == sortKey),
        showCheckboxColumn: false,
        dividerThickness: .2,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border.all(color: branchDivider(context)),
          borderRadius: appRadius(context),
        ),
        border: TableBorder(
          horizontalInside: BorderSide(
            color: branchDivider(context),
            width: .2,
          ),
        ),
        headingRowColor: WidgetStatePropertyAll(branchCanvas(context)),
        columnSpacing: 24,
        dataRowMinHeight: 64,
        dataRowMaxHeight: 90,
        columns: [
          for (final column in effectiveColumns)
            DataColumn(
              label: Text(panelCaption(context, column)),
              onSort: (_, ascending) {
                final serverPaged =
                    data['total'] != null && data['perPage'] != null;
                setState(() {
                  sortKey = '${column['key']}';
                  sortAscending = ascending;
                  page = 1;
                  localPage = 1;
                });
                if (serverPaged) {
                  setState(() => loading = true);
                  load();
                }
              },
            ),
          if (showActions)
            DataColumn(label: Text(socialText(context, 'عملیات', 'Actions'))),
        ],
        rows: [
          for (final row in rows.indexed.map(
            (entry) => {
              ...panelDisplayRow(section, {
                ...entry.$2,
                '_index': entry.$1 + 1 + offset,
              }, data),
              '_record': entry.$2,
            },
          ))
            DataRow(
              cells: [
                for (final column in effectiveColumns)
                  DataCell(
                    section == 'users' && column['key'] == 'status'
                        ? PanelAccessStatus(
                            status: optionalObject(row['_record'])['status'],
                          )
                        : section == 'users' &&
                              ['roles', 'permissions'].contains(column['key'])
                        ? PanelAccessBadges(
                            items: objects(row['${column['key']}'] ?? []),
                            roles: column['key'] == 'roles',
                          )
                        : column['key'] == 'status' &&
                                  column['type'] != 'text' ||
                              ['approval', 'badge'].contains(column['type'])
                        ? PanelStatusCell(
                            row: row,
                            column: column,
                            section: section,
                            onPressed:
                                !busy &&
                                    column['action'] is String &&
                                    available(column['action'], row)
                                ? () => changeStatus(
                                    optionalObject(row['_record']),
                                    column['action'],
                                  )
                                : null,
                          )
                        : ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 220),
                            child: Text(
                              panelCellText(context, row, column),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                  ),
                if (showActions)
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (section == 'finance' &&
                            row['invoiceKind'] == 'subscription' &&
                            row['canPay'] == true)
                          IconButton(
                            tooltip: socialText(
                              context,
                              'خرید اشتراک',
                              'Buy subscription',
                            ),
                            icon: const Icon(Icons.shopping_cart_outlined),
                            onPressed: busy
                                ? null
                                : () => buySubscription(
                                    optionalObject(row['_record']),
                                  ),
                          ),
                        for (final key in rowActions)
                          if (key == 'details' || available('$key', row))
                            if (section == 'users')
                              Padding(
                                padding: const EdgeInsetsDirectional.only(
                                  end: 8,
                                ),
                                child: OutlinedButton(
                                  onPressed: busy
                                      ? null
                                      : () => key == 'details'
                                            ? openRecord(
                                                optionalObject(row['_record']),
                                              )
                                            : perform(
                                                '$key',
                                                optionalObject(row['_record']),
                                              ),
                                  child: Text(
                                    socialText(
                                      context,
                                      key == 'roles'
                                          ? 'تعیین نقش‌ها'
                                          : key == 'permissions'
                                          ? 'تعیین دسترسی‌ها'
                                          : 'مشاهده دسترسی‌ها',
                                      key == 'roles'
                                          ? 'Assign roles'
                                          : key == 'permissions'
                                          ? 'Assign permissions'
                                          : 'View permissions',
                                    ),
                                  ),
                                ),
                              )
                            else if ([
                              'details',
                              'update',
                              'delete',
                              'usage',
                            ].contains(key))
                              IconButton(
                                tooltip: key == 'details'
                                    ? socialText(context, 'جزئیات', 'Details')
                                    : key == 'usage'
                                    ? socialText(
                                        context,
                                        'محل‌های استفاده از درس',
                                        'Lesson usage',
                                      )
                                    : panelLabel(
                                        context,
                                        optionalObject(actions[key]),
                                      ),
                                icon: Icon(
                                  switch (key) {
                                    'details' => Icons.info_outline,
                                    'update' => Icons.edit_outlined,
                                    'delete' => Icons.delete_outline,
                                    _ => Icons.fact_check_outlined,
                                  },
                                  color: key == 'delete'
                                      ? Colors.red
                                      : branchAccent(context),
                                ),
                                onPressed: busy
                                    ? null
                                    : () => key == 'details'
                                          ? openRecord(
                                              optionalObject(row['_record']),
                                            )
                                          : perform(
                                              '$key',
                                              optionalObject(row['_record']),
                                            ),
                              )
                            else
                              TextButton(
                                onPressed: busy
                                    ? null
                                    : () => key == 'details'
                                          ? openRecord(
                                              optionalObject(row['_record']),
                                            )
                                          : perform(
                                              '$key',
                                              optionalObject(row['_record']),
                                            ),
                                child: Text(
                                  key == 'details'
                                      ? socialText(context, 'جزئیات', 'Details')
                                      : panelLabel(
                                          context,
                                          optionalObject(actions[key]),
                                        ),
                                ),
                              ),
                      ],
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Widget recordRow(
    Json row, {
    List<String>? only,
    Map<String, String> extra = const {},
  }) {
    final rowActions =
        only ?? actions.keys.where((key) => available(key, row)).toList();
    final inlineActions =
        only == null &&
        !['chat', 'gallery', 'my-gallery', 'account'].contains(section);
    final menuActions = rowActions
        .where((key) => !inlineActions || !['update', 'delete'].contains(key))
        .toList();
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
            trailing: menuActions.isEmpty
                ? null
                : PopupMenuButton<String>(
                    onSelected: (key) => perform(key, row, extra),
                    itemBuilder: (_) => [
                      for (final key in menuActions)
                        if (actions.containsKey(key))
                          PopupMenuItem(
                            value: key,
                            child: Text('${actions[key]['label']}'),
                          ),
                    ],
                  ),
            onTap: () => openRecord(row),
          ),
          if (inlineActions)
            Padding(
              padding: const EdgeInsetsDirectional.only(start: 16, end: 8),
              child: Wrap(
                spacing: 4,
                children: [
                  TextButton.icon(
                    onPressed: () => openRecord(row),
                    icon: const Icon(Icons.info_outline, size: 18),
                    label: Text(socialText(context, 'جزئیات', 'Details')),
                  ),
                  for (final key in ['update', 'delete'])
                    if (rowActions.contains(key))
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor: key == 'delete'
                              ? Colors.red
                              : branchAccent(context),
                        ),
                        onPressed: busy ? null : () => perform(key, row, extra),
                        icon: Icon(
                          key == 'delete'
                              ? Icons.delete_outline
                              : Icons.edit_outlined,
                          size: 18,
                        ),
                        label: Text(
                          panelLabel(context, optionalObject(actions[key])),
                        ),
                      ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Future<void> buySubscription(Json row) async {
    final plan = await showDialog<Json>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          socialText(
            context,
            'انتخاب پلن اشتراک',
            'Choose a subscription plan',
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final plan in objects(data['subscriptionPlans'] ?? []))
                ListTile(
                  title: Text('${plan['label']}'),
                  subtitle: Text(
                    '${plan['amount']} ${socialText(context, 'تومان', 'toman')}',
                  ),
                  onTap: () => Navigator.pop(dialogContext, plan),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(socialText(context, 'انصراف', 'Cancel')),
          ),
        ],
      ),
    );
    if (plan == null || !mounted) return;
    final confirmed = await showPanelConfirmation(
      context,
      socialText(context, 'پرداخت اشتراک', 'Pay for subscription'),
      message:
          '${plan['label']} — ${plan['amount']} ${socialText(context, 'تومان', 'toman')}',
    );
    if (!confirmed || !mounted) return;
    setState(() => busy = true);
    try {
      final response = await widget.api.act(
        'finance',
        'subscription-pay',
        params: {'id': '${row['subscriptionId']}'},
        values: {'months': plan['months']},
      );
      final target = SiteApi.origin.resolve('${response['redirectUrl'] ?? ''}');
      if ('${response['redirectUrl'] ?? ''}'.trim().isEmpty ||
          !['https', 'http'].contains(target.scheme) ||
          !await launchUrl(target, mode: LaunchMode.externalApplication)) {
        throw const SocialException('لینک پرداخت دریافت نشد.');
      }
      if (mounted) await load(refresh: true);
    } catch (error) {
      if (mounted) socialError(context, error);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthSession?>();
    if (auth != null && auth.token != widget.api.token) {
      return const PanelScaffold(body: JoinCommunity());
    }
    if (['branches', 'branch-types'].contains(section)) {
      return BranchesPage(
        api: widget.api,
        section: {
          ...widget.section,
          'label': widget.titleSection['label'],
          'en': widget.titleSection['en'],
        },
        tabs: widget.tabs,
      );
    }
    final dynamic collection = panelValue(
      data,
      '${widget.section['rows'] ?? ''}',
    );
    final rows = collection is List
        ? collection
              .whereType<Map>()
              .map(
                (row) => {
                  ...optionalObject(row),
                  if (widget.section['rowId'] is String)
                    'id': row[widget.section['rowId']],
                  if (widget.section['rowTitle'] is String)
                    'title': row[widget.section['rowTitle']],
                  if (widget.section['rowSubtitle'] is String)
                    'summary': row[widget.section['rowSubtitle']],
                },
              )
              .toList()
        : data['items'] is List
        ? objects(data['items'])
        : <Json>[];
    final organizationOptions =
        (gallerySection && data['hideOwnerFilters'] == true)
        ? <String, String>{}
        : (section == 'dashboard' ||
              (tableContract['organizationFilter'] ??
                      widget.section['organizationFilter']) ==
                  true)
        ? panelOrganizationOptions(
            data,
            rows,
            fa: Localizations.localeOf(context).languageCode == 'fa',
            mode: section == 'dashboard'
                ? 'branch'
                : '${tableContract['organizationMode'] ?? 'branch'}',
            includeFixedScope: section == 'schedules',
          )
        : <String, String>{};
    if (section == 'users' && !panelFixedBranchScope(data))
      organizationOptions['academy'] = socialText(
        context,
        'آموزشگاه',
        'Academy',
      );
    final filterFields = panelWebFilters(widget.section, data, rows);
    final effectiveOrganization =
        organizationOptions.containsKey(organizationFilter)
        ? organizationFilter
        : '';
    var filtered = rows
        .where(
          (row) =>
              (['users', 'schedules'].contains(section) ||
                  panelMatchesOrganization(row, effectiveOrganization, data)) &&
              panelMatchesFilters(row, filterFields, filters) &&
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
    filtered = panelSortedRows(
      filtered,
      sortKey,
      sortAscending,
      (row, key) => panelTableValue(panelDisplayRow(section, row, data), key),
    );
    final serverPaged = data['total'] != null && data['perPage'] != null;
    final localPages = (filtered.length / pageSize).ceil().clamp(1, 1000000);
    final currentLocalPage = localPage.clamp(1, localPages);
    final displayedRows = serverPaged
        ? filtered
        : filtered
              .skip((currentLocalPage - 1) * pageSize)
              .take(pageSize)
              .toList();
    final financeTotals = section == 'finance'
        ? panelFinanceTotals(filtered)
        : <String, dynamic>{};
    final definedExportColumns = panelTableColumns(tableContract, data);
    final exportColumns = definedExportColumns.isEmpty
        ? <Json>[
            {'key': 'title', 'label': socialText(context, 'عنوان', 'Title')},
            if (filtered.any((row) => row.containsKey('status')))
              {
                'key': 'status',
                'label': socialText(context, 'وضعیت', 'Status'),
              },
          ]
        : definedExportColumns;
    List<Json> exportValues(List<Json> values) => [
      if (values.isEmpty)
        {for (final column in exportColumns) panelCaption(context, column): ''},
      for (final entry in values.indexed)
        {
          for (final column in exportColumns)
            panelCaption(context, column): panelCellText(
              context,
              panelDisplayRow(section, {
                ...entry.$2,
                '_index': entry.$1 + 1,
              }, data),
              column,
            ),
        },
    ];
    Future<List<Json>> completeExport() async {
      if (!serverPaged) return exportValues(filtered);
      final exportFilters = {...filters};
      final exportSearch = query;
      final exportOrganization = organizationFilter;
      final collected = <Json>[];
      var next = 1;
      while (true) {
        final response = await widget.api.refresh('/$section/list', {
          ...widget.params,
          ...panelFilterQuery(
            filterFields,
            exportFilters,
            exportOrganization,
            section,
          ),
          'page': '$next',
          'perPage': '100',
          if (exportSearch.trim().isNotEmpty) 'search': exportSearch.trim(),
          if (exportSearch.trim().isNotEmpty) 'q': exportSearch.trim(),
        });
        final chunk = objects(
          panelValue(response, '${widget.section['rows'] ?? 'items'}') ??
              response['items'] ??
              [],
        );
        collected.addAll(chunk);
        final total = num.tryParse('${response['total']}') ?? collected.length;
        if (collected.length >= total) break;
        if (chunk.isEmpty)
          throw const SocialException(
            'دریافت همهٔ ردیف‌ها برای خروجی کامل نشد.',
          );
        next++;
      }
      if (!mounted) throw const SocialException('صفحه بسته شده است.');
      final matching = collected
          .where(
            (row) =>
                (['users', 'schedules'].contains(section) ||
                    panelMatchesOrganization(
                      row,
                      effectiveOrganization,
                      data,
                    )) &&
                panelMatchesFilters(row, filterFields, exportFilters) &&
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
                    .contains(exportSearch.toLowerCase()),
          )
          .toList();
      return exportValues(
        panelSortedRows(
          matching,
          sortKey,
          sortAscending,
          (row, key) =>
              panelTableValue(panelDisplayRow(section, row, data), key),
        ),
      );
    }

    final pageActions = actions.entries
        .where(
          (entry) =>
              entry.key != 'list' &&
              !(section == 'terms' && entry.key == 'available-times') &&
              section != 'account' &&
              !(section == 'classroom-types' &&
                  entry.key == 'create-from-classroom') &&
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
                  (section == 'term-discounts' && data['ready'] == false ||
                      data['can_create_branch'] == false ||
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
      if (!gallerySection &&
          section != 'users' &&
          (filtered.isNotEmpty ||
              [
                'finance',
                'schedules',
                'scheduling-rules',
                'availability-exceptions',
              ].contains(section) ||
              ['organization-holidays'].contains(widget.section['key'])))
        IconButton(
          tooltip: socialText(context, 'خروجی اکسل', 'Export Excel'),
          icon: const Icon(Icons.table_view, color: Color(0xff16a34a)),
          onPressed: () async {
            try {
              await exportPanelExcel(section, await completeExport());
            } catch (e) {
              if (mounted) socialError(this.context, e);
            }
          },
        ),
      if (!gallerySection &&
          section != 'users' &&
          section != 'dashboard' &&
          (filtered.isNotEmpty ||
              data['stats'] is Map ||
              [
                'finance',
                'schedules',
                'scheduling-rules',
                'availability-exceptions',
              ].contains(section) ||
              widget.section['key'] == 'organization-holidays'))
        IconButton(
          tooltip: socialText(context, 'خروجی PDF', 'Export PDF'),
          icon: const Icon(
            Icons.picture_as_pdf_outlined,
            color: Color(0xffdc2626),
          ),
          onPressed: () async {
            try {
              final exportRows = filtered.isEmpty && data['stats'] is Map
                  ? [optionalObject(data['stats'])]
                  : await completeExport();
              if (!context.mounted) return;
              final labels = {
                for (final key in exportRows.expand((row) => row.keys))
                  key: data['stats'] is Map && filtered.isEmpty
                      ? panelDataLabel(context, key)
                      : key,
              };
              final title = panelLabel(context, widget.section);

              await exportBranchesPdf(
                context,
                exportRows,
                Map.fromEntries(
                  labels.entries.where(
                    (e) => ![
                      'password',
                      'csrf_token',
                      'permissions',
                      'catalog',
                      'staff_catalog',
                    ].contains(e.key),
                  ),
                ),
                title: title,
                subtitle: '',
                fileName: '$section.pdf',
              );
            } catch (e) {
              if (mounted) socialError(this.context, e);
            }
          },
        ),
      if (!gallerySection &&
          (filters.isNotEmpty || organizationFilter.isNotEmpty))
        IconButton(
          tooltip: socialText(context, 'حذف فیلترها', 'Clear filters'),
          icon: const Icon(Icons.filter_alt_off),
          onPressed: () {
            setState(() {
              filters = {};
              organizationFilter = '';
              page = 1;
              localPage = 1;
            });
            load();
          },
        ),
    ];
    final exportButtons = toolbar
        .where(
          (button) =>
              button.icon is Icon &&
              [
                Icons.table_view,
                Icons.picture_as_pdf_outlined,
              ].contains((button.icon as Icon).icon),
        )
        .toList();
    toolbar.removeWhere(exportButtons.contains);
    final listLayout =
        ![
          'chat',
          'gallery',
          'my-gallery',
          'account',
          'dashboard',
          'reports',
        ].contains(section) &&
        collection is List;
    return PanelScaffold(
      appBar: ExpandingSearchBar(
        title: Row(
          children: [
            const BackButton(),
            Expanded(
              child: Text(
                panelLabel(context, widget.titleSection),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: AppTopBarDirection.titleSize(context),
                ),
              ),
            ),
          ],
        ),
        hint: socialText(context, 'جستجو', 'Search'),
        onChanged: searchChanged,
        actions: [
          if (!loading && error == null && additions.length == 1)
            IconButton(
              tooltip: '${additions.single.value['label']}',
              icon: const Icon(Icons.add),
              onPressed: busy ? null : () => perform(additions.single.key),
            ),
          if (!loading && error == null && additions.length > 1)
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
          if ((!loading || section == 'schedules') && error == null)
            ...exportButtons.map(
              (button) => SizedBox(
                width: 48,
                child: IconButton(
                  tooltip: button.tooltip,
                  icon: button.icon,
                  onPressed: loading ? null : button.onPressed,
                ),
              ),
            ),
          if (toolbar.isNotEmpty)
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
      body: pendingContent(
        loading
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
                  padding: const EdgeInsets.only(bottom: 16),
                  children: [
                    if (busy) const LinearProgressIndicator(),
                    if (section == 'schedules')
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final option in [
                              (
                                false,
                                Icons.table_chart_outlined,
                                socialText(
                                  context,
                                  'نمایش جدولی',
                                  'Table view',
                                ),
                              ),
                              (
                                true,
                                Icons.calendar_view_week_outlined,
                                socialText(
                                  context,
                                  'نمایش برنامه هفتگی',
                                  'Weekly schedule view',
                                ),
                              ),
                            ])
                              OutlinedButton.icon(
                                key: ValueKey(
                                  'schedule-view-${option.$1 ? 'weekly' : 'table'}',
                                ),
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: weekly == option.$1
                                      ? Theme.of(
                                          context,
                                        ).colorScheme.primaryContainer
                                      : Theme.of(context).colorScheme.surface,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: appRadius(context),
                                  ),
                                  minimumSize: const Size(0, 40),
                                ),
                                icon: Icon(option.$2, size: 18),
                                label: Text(option.$3),
                                onPressed: () {
                                  if (weekly == option.$1) return;
                                  setState(() {
                                    weekly = option.$1;
                                    loading = true;
                                    page = 1;
                                    localPage = 1;
                                  });
                                  load();
                                },
                              ),
                          ],
                        ),
                      ),
                    PanelPageGuidance(
                      api: widget.api,
                      section: section,
                      horizontalInset: 12,
                      defaults: optionalObject(tableContract['guidance']),
                      enabled: widget.section['pageGuidance'] is Map,
                      canEdit:
                          optionalObject(
                            widget.section['pageGuidance'],
                          )['canEdit'] ==
                          true,
                    ),
                    if (section == 'finance') ...[
                      if (data['subscriptionUnavailable'] == true)
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Text(
                            socialText(
                              context,
                              'اطلاعات اشتراک دریافت نشد. API وب را به‌روز کنید و دوباره تلاش کنید.',
                              'Subscription data could not be loaded. Update the web API and retry.',
                            ),
                          ),
                        ),
                      PanelSectionCard(
                        storageId: 'finance-subscription',
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: .2),
                        icon: Icons.description_outlined,
                        title: socialText(
                          context,
                          'اشتراک سامانه مدیریت آموزشگاه',
                          'Academy management subscription',
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  socialText(
                                    context,
                                    'ماه اول رایگان',
                                    'First month free',
                                  ),
                                ),
                                for (final plan in objects(
                                  data['subscriptionPlans'] ?? [],
                                ))
                                  Text(
                                    '${plan['label']} — ${plan['amount']} ${socialText(context, 'تومان', 'toman')}',
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        child: PanelStatistics(
                          stats: {
                            for (final metric in ['total', 'paid', 'remaining'])
                              metric:
                                  '${panelNumber(financeTotals[metric], fa: Localizations.localeOf(context).languageCode == 'fa')} ${socialText(context, 'تومان', 'toman')}',
                          },
                        ),
                      ),
                    ],
                    if (section == 'term-discounts' && data['ready'] == false)
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          socialText(
                            context,
                            'برای مدیریت تخفیف‌های سازمانی، به‌روزرسانی پایگاه دادهٔ وب لازم است.',
                            'Update the website database to manage organization discounts.',
                          ),
                        ),
                      ),
                    for (final summary in objects(
                      tableContract['summaries'] ?? [],
                    ))
                      Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: appRadius(context),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                '${summary['label']}',
                                style: Theme.of(context).textTheme.labelLarge,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${summary['countRows'] != null ? objects(data[summary['countRows']] ?? []).where((row) => optionalObject(summary['where']).entries.every((e) => row[e.key] == e.value)).length : panelValue(data, '${summary['path']}') ?? 0}',
                                style: Theme.of(
                                  context,
                                ).textTheme.headlineSmall,
                              ),
                              if (summary['description'] != null)
                                Text(
                                  '${summary['description']}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                            ],
                          ),
                        ),
                      ),
                    if (widget.section['key'] == 'organization-holidays')
                      PanelNationalHolidaySettings(api: widget.api),
                    if (organizationOptions.isNotEmpty &&
                            section != 'schedules' ||
                        filterFields.isNotEmpty)
                      PanelSectionCard(
                        key: ValueKey('panel-filters-$section'),
                        storageId: 'filters-$section',
                        title: socialText(context, 'فیلترها', 'Filters'),
                        children: [
                          if (organizationOptions.isNotEmpty &&
                              section != 'schedules')
                            PanelField(
                              field: {
                                'key': 'organization',
                                'label': section == 'dashboard'
                                    ? 'سازمان'
                                    : 'آموزشگاه و شعبه‌ها',
                                'en': section == 'dashboard'
                                    ? 'Organization'
                                    : 'Academy and branches',
                                'type': 'select',
                                'filter': true,
                                'options': organizationOptions,
                              },
                              value: effectiveOrganization,
                              data: data,
                              changed: (value) {
                                setState(() {
                                  organizationFilter = '${value ?? ''}';
                                  page = 1;
                                  localPage = 1;
                                });
                                if ([
                                  'users',
                                  'schedules',
                                  'dashboard',
                                ].contains(section))
                                  load();
                              },
                            ),
                          for (final field in filterFields.where(
                            (field) =>
                                panelFieldVisible(field, {'_form': filters}) &&
                                !(section == 'schedules' &&
                                    ['branch', 'organization'].contains(
                                      field['queryKey'] ?? field['key'],
                                    )),
                          ))
                            PanelField(
                              field: {...field, 'filter': true},
                              value: filters['${field['key']}'],
                              data: {...data, '_form': filters},
                              changed: (value) {
                                setState(() {
                                  filters['${field['key']}'] = value;
                                  for (final child in objects(
                                    widget.section['filters'] ?? [],
                                  )) {
                                    if (optionalObject(
                                      optionalObject(child['options'])['match'],
                                    ).values.contains(field['key']))
                                      filters.remove('${child['key']}');
                                  }
                                  page = 1;
                                  localPage = 1;
                                });
                                if (field['queryKey'] != null) load();
                              },
                            ),
                        ],
                      ),
                    if (listLayout)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                socialText(
                                  context,
                                  '${data['total'] ?? filtered.length} مورد',
                                  '${data['total'] ?? filtered.length} records',
                                ),
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (listLayout &&
                        !weekly &&
                        !serverPaged &&
                        filtered.length > pageSize)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            onPressed: currentLocalPage > 1
                                ? () => setState(
                                    () => localPage = currentLocalPage - 1,
                                  )
                                : null,
                            child: Text(
                              socialText(context, 'قبلی', 'Previous'),
                            ),
                          ),
                          Text('$currentLocalPage / $localPages'),
                          TextButton(
                            onPressed: currentLocalPage < localPages
                                ? () => setState(
                                    () => localPage = currentLocalPage + 1,
                                  )
                                : null,
                            child: Text(socialText(context, 'بعدی', 'Next')),
                          ),
                        ],
                      ),
                    if (serverPaged &&
                        (page > 1 ||
                            (num.tryParse('${data['total'] ?? 0}') ?? 0) >
                                page *
                                    (num.tryParse(
                                          '${data['perPage'] ?? pageSize}',
                                        ) ??
                                        pageSize)))
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
                            child: Text(
                              socialText(context, 'قبلی', 'Previous'),
                            ),
                          ),
                          Text('$page'),
                          TextButton(
                            onPressed:
                                (num.tryParse('${data['total'] ?? 0}') ?? 0) >
                                    page *
                                        (num.tryParse(
                                              '${data['perPage'] ?? pageSize}',
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
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.red,
                              ),
                              onPressed: () async {
                                for (final row
                                    in rows
                                        .where(
                                          (r) =>
                                              selected.contains('${r['id']}'),
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
                    if (weekly && section == 'schedules')
                      PanelScheduleWeek(
                        preferences: schedulePreferences,
                        rows: filtered,
                        data: {
                          ...data,
                          'branches': [
                            {
                              'id': 0,
                              'name': socialText(
                                context,
                                'آموزشگاه',
                                'Academy',
                              ),
                            },
                            ...objects(data['branches'] ?? []),
                          ],
                        },
                        branch: organizationFilter,
                        start: weekStart,
                        first: firstScheduleWeek,
                        last: lastScheduleWeek,
                        changeWeek: (date) {
                          setState(() {
                            weekStart = date;
                            loading = true;
                          });
                          load();
                        },
                        open: openRecord,
                      )
                    else if (gallerySection)
                      PanelGallery(
                        sectionKey: section,
                        api: widget.api,
                        rows: filtered,
                        fields: objects(
                          optionalObject(actions['update'])['fields'] ?? [],
                        ),
                        data: {
                          ...data,
                          '_category':
                              optionalObject(
                                widget.section['where'],
                              )['category'] ??
                              filters['category'] ??
                              '',
                        },
                        canEdit: actions.containsKey('update'),
                        canDelete: actions.containsKey('delete'),
                        onChanged: () => load(refresh: true),
                      )
                    else if (section == 'account')
                      PanelAccount(
                        key: ValueKey(
                          'account-${widget.api.hashCode}-${widget.accountArea}',
                        ),
                        api: widget.api,
                        data: data,
                        actions: actions,
                        area: widget.accountArea,
                        onAction: (key, row) => perform(key, row),
                        onChanged: () => load(refresh: true),
                      )
                    else if (section == 'dashboard' ||
                        section == 'reports' && collection is! List) ...[
                      PanelDashboard(
                        data: panelDashboardOrganizationData(
                          data,
                          effectiveOrganization,
                        ),
                        onOpen: (target) async {
                          try {
                            final related = objects(
                              widget.section['relatedSections'] ?? [],
                            );
                            Json? destination = related
                                .where(
                                  (s) =>
                                      s['key'] == target ||
                                      s['resourceKey'] == target,
                                )
                                .firstOrNull;
                            destination ??= objects(
                              (await widget.api.get(''))['sections'],
                            ).where((s) => s['key'] == target).firstOrNull;
                            if (!mounted) return;
                            if (destination == null)
                              throw const SocialException(
                                'دسترسی لازم برای این بخش را ندارید.',
                                403,
                              );
                            await Navigator.of(this.context).push(
                              MaterialPageRoute(
                                builder: (_) => PanelResourcePage(
                                  api: widget.api,
                                  section: destination!,
                                ),
                              ),
                            );
                            if (mounted) await load(refresh: true);
                          } catch (error) {
                            if (mounted) socialError(this.context, error);
                          }
                        },
                      ),
                    ] else if (section == 'tracking') ...[
                      PanelTracking(data: data),
                    ] else if (rows.isNotEmpty) ...[
                      if (listLayout)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppTopBarDirection.contentInset,
                          ),
                          child: recordTable(
                            displayedRows,
                            offset: serverPaged
                                ? (page - 1) *
                                      (int.tryParse('${data['perPage']}') ??
                                          pageSize)
                                : (currentLocalPage - 1) * pageSize,
                          ),
                        )
                      else
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
                    if (section == 'my-finance')
                      PanelDataView(
                        value: {
                          'installments': data['installments'] ?? [],
                          'payments': data['payments'] ?? [],
                        },
                      ),
                  ],
                ),
              ),
      ),
    );
  }
}

final panelKnownDataLabels = <String, String>{
  for (final contract in panelWebPresentation.values.whereType<Map>())
    for (final field in [
      ...objects(contract['columns'] ?? []),
      ...objects(contract['detailFields'] ?? []),
    ])
      if (field['label'] != null) '${field['key']}': '${field['label']}',
};

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
    'teacherNotes': 'یادداشت‌های استاد',
    'teacherNote': 'یادداشت استاد',
    'sessionId': 'جلسه',
    'text': 'متن یادداشت',
    'student': 'هنرجو',
    'capacity': 'ظرفیت',
    'privacy': 'حریم خصوصی',
    'showPublicProfile': 'نمایش عمومی پروفایل',
    'current': 'نشست فعلی',
    'lastActive': 'آخرین فعالیت',
    'location': 'مکان',
    'founded': 'تاریخ تأسیس',
    'members': 'اعضا',
    'roles': 'نقش‌ها',
    'rolePermissions': 'دسترسی‌های نقش‌ها',
    'directPermissions': 'دسترسی‌های مستقل از نقش',
  };
  if (!labels.containsKey(key) && !panelKnownDataLabels.containsKey(key)) {
    return socialText(context, 'اطلاعات تکمیلی', 'Additional details');
  }
  return Localizations.localeOf(context).languageCode == 'fa'
      ? labels[key] ?? panelKnownDataLabels[key] ?? 'اطلاعات تکمیلی'
      : panelCaption(context, {
          'key': key,
          'label': labels[key] ?? panelKnownDataLabels[key],
        });
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
                  : PanelListItem(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 14,
                        ),
                        child: Text(
                          '${panelDataLabel(context, '${entry.key}')}: ${entry.value is bool ? (entry.value ? socialText(context, 'بلی', 'Yes') : socialText(context, 'خیر', 'No')) : entry.value}',
                        ),
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
        final result = await showDialog<PanelFormResult>(
          context: context,
          builder: (_) => PanelFormPage(
            dialog: true,
            title: '${definition['label']}',
            fields: fields,
            data: options,
            initial: action == 'edit-message'
                ? {'body': row['body']}
                : const {},
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
        final result = await showDialog<PanelFormResult>(
          context: context,
          builder: (_) => PanelFormPage(
            dialog: true,
            title: socialText(context, 'ارسال پیام‌ها', 'Forward messages'),
            fields: objects(optionalObject(actions['forward'])['fields'] ?? []),
            data: options,
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
      return const PanelScaffold(body: JoinCommunity());
    }
    return PanelScaffold(
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
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
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
      result = await showDialog<PanelFormResult>(
        context: context,
        builder: (_) => PanelFormPage(
          dialog: true,
          title: '${action['label']}',
          fields: fields,
          data: {
            'users': data['availableUsers'] ?? [],
            'people': data['availableUsers'] ?? [],
          },
          initial: key == 'rename' ? {'title': data['title']} : const {},
        ),
      );
      if (result == null || !mounted) return;
    } else {
      final confirmed = await showPanelConfirmation(
        context,
        panelLabel(context, action),
        message: panelTitle(member.isEmpty ? data : member),
        delete: key == 'delete' || key == 'remove-member' || key == 'leave',
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
      return const PanelScaffold(body: JoinCommunity());
    }
    return PanelScaffold(
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
