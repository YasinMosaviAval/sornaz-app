import 'package:sornaz/components/app_view_mode_selector.dart';
import 'package:sornaz/components/app_async_state.dart';
import 'package:sornaz/components/app_dialog.dart';
import 'package:sornaz/helpers/app_appearance.dart';
import 'dart:async';
import 'dart:convert';
import '../../components/app_top_bar_direction.dart';
import '../../components/expanding_search_bar.dart';
import 'branch_export.dart';
import 'package:flutter/material.dart';
import '../Social/social_api.dart';
import '../Social/social_widgets.dart';
import 'panel_api.dart';
import 'panel_presentation.dart';
import 'branch_style.dart';
import 'branch_form.dart';
import 'panel_page_guidance.dart';
import 'panel_section_card.dart';
import 'panel_table_contract.dart';
import 'panel_form.dart';

class BranchesPage extends StatefulWidget {
  const BranchesPage({
    super.key,
    required this.api,
    required this.section,
    this.tabs,
  });
  final Widget? tabs;
  final PanelApi api;
  final Json section;
  @override
  State<BranchesPage> createState() => _BranchesPageState();
}

class _BranchesPageState extends State<BranchesPage> {
  Widget withTabs(Widget child) => Column(
    children: [
      if (widget.tabs != null) widget.tabs!,
      Expanded(child: child),
    ],
  );

  Json data = {};
  bool loading = true, busy = false, table = false, initialized = false;
  Object? error;

  String query = '', type = '', academy = '', mode = '', status = '', sort = '';
  bool ascending = true;
  int page = 1, pageSize = 20;
  bool get fa => Localizations.localeOf(context).languageCode == 'fa';
  String t(String a, String b) => fa ? a : b;
  bool get typesOnly => widget.section['key'] == 'branch-types';
  String get resource => typesOnly ? 'branch-types' : 'branches';
  Json get actions => optionalObject(widget.section['actions']);
  List<Json> get branches =>
      objects(data[typesOnly ? 'types' : 'branches'] ?? []);
  bool get readOnly => branchFlag(data['read_only']);
  bool get canCreate =>
      actions.containsKey('create') &&
      !readOnly &&
      (typesOnly ||
          (data['can_create_branch'] != false &&
              !branchFlag(data['branch_account'])));
  bool canEdit(Json row) =>
      actions.containsKey('update') &&
      !readOnly &&
      row['canEdit'] != false &&
      row['readOnly'] != true;
  bool canDelete(Json row) =>
      actions.containsKey('delete') &&
      !readOnly &&
      row['canDelete'] != false &&
      (typesOnly ||
          (data['can_delete_branch'] != false &&
              (!branchFlag(row['is_main']) ||
                  (data['main_delete_academy_ids'] as List? ?? const []).any(
                    (id) => '$id' == '${row['academy_id']}',
                  ))));
  @override
  void initState() {
    super.initState();
    load();
    updates = Timer.periodic(const Duration(seconds: 3), (_) {
      if (mounted &&
          !busy &&
          !loading &&
          !polling &&
          ModalRoute.of(context)?.isCurrent == true &&
          WidgetsBinding.instance.lifecycleState != AppLifecycleState.paused) {
        load(background: true);
      }
    });
  }

  Timer? updates;
  bool polling = false;
  @override
  void dispose() {
    updates?.cancel();
    super.dispose();
  }

  Future<void> load({bool refresh = false, bool background = false}) async {
    polling = true;
    try {
      final value = await (background
          ? widget.api.live
          : refresh
          ? widget.api.refresh
          : widget.api.get)('/$resource/list');
      if (!mounted) return;
      final changed =
          background &&
          jsonEncode(data[typesOnly ? 'types' : 'branches']) !=
              jsonEncode(value[typesOnly ? 'types' : 'branches']);
      setState(() {
        data = value;
        error = null;
        loading = false;
        if (!initialized) {
          table = typesOnly || branchFlag(data['site_admin']);
          initialized = true;
        }
      });
      if (changed)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              t('تغییرات سازمان اعمال شد.', 'Organization changes applied.'),
            ),
          ),
        );
    } catch (e) {
      if (mounted && !background)
        setState(() {
          error = e;
          loading = false;
        });
    } finally {
      polling = false;
    }
  }

  List<Json> get filtered {
    final result = branches
        .where(
          (r) =>
              (query.isEmpty ||
                  '${r['name'] ?? r['title']} ${r['manager'] ?? ''} ${r['academy_name'] ?? ''}'
                      .toLowerCase()
                      .contains(query.trim().toLowerCase())) &&
              (type.isEmpty || '${r['type_id']}' == type) &&
              (academy.isEmpty || '${r['academy_id']}' == academy) &&
              (mode.isEmpty || r['physical_type'] == mode) &&
              (status.isEmpty || branchStatusCode(r) == status),
        )
        .toList();
    if (sort.isNotEmpty)
      result.sort((a, b) {
        final left = a[sort], right = b[sort];
        final compared = left is num && right is num
            ? left.compareTo(right)
            : '$left'.compareTo('$right');
        return ascending ? compared : -compared;
      });
    return result;
  }

  String digits(Object value) {
    final text = '$value';
    return fa
        ? text.replaceAllMapped(
            RegExp('[0-9]'),
            (m) => '۰۱۲۳۴۵۶۷۸۹'[int.parse(m[0]!)],
          )
        : text;
  }

  Future<void> edit([Json? row]) async {
    if (busy || (row == null ? !canCreate : !canEdit(row))) return;
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => Theme(
        data: branchTheme(context),
        child: BranchForm(
          api: widget.api,
          data: data,
          row: row,
          typesOnly: typesOnly,
          academyId: academy,
        ),
      ),
    );
    if (saved == true && mounted) {
      await load();
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(t('اطلاعات سازمان ذخیره شد.', 'Organization saved.')),
          ),
        );
    }
  }

  Future<void> registerAccount() async {
    if (busy || !canCreate || !actions.containsKey('register-account')) return;
    final action = optionalObject(actions['register-account']);
    final result = await showDialog<PanelFormResult>(
      context: context,
      builder: (_) => PanelFormPage(
        title: t('ثبت حساب شعبه', 'Register branch account'),
        fields: objects(action['fields'] ?? []),
        data: data,
        initial: {
          'academy_id': academy.isNotEmpty
              ? academy
              : objects(data['academies'] ?? []).firstOrNull?['id'],
        },
        dialog: true,
        declaredOnly: true,
        onRequestCode: (result) async {
          await widget.api.act(
            'branches',
            'registration-otp',
            values: result.values,
          );
        },
        onSubmit: (result) async {
          await widget.api.act(
            'branches',
            'register-account',
            values: result.values,
          );
        },
      ),
    );
    if (result != null && mounted) await load();
  }

  Future<void> remove(Json row) async {
    if (busy || !canDelete(row)) return;
    final yes = await showDeleteConfirmation(
      context,
      title: t(
        typesOnly ? 'حذف نوع آموزشی' : 'حذف شعبه',
        typesOnly ? 'Delete education type' : 'Delete branch',
      ),
      message: t(
        'آیا از حذف «${row['name'] ?? row['title']}» مطمئن هستید؟',
        'Delete “${row['name'] ?? row['title']}”?',
      ),
    );
    if (yes != true || !mounted) return;
    await mutate('delete', row);
  }

  Future<void> mutate(String action, Json row, {Json values = const {}}) async {
    setState(() => busy = true);
    try {
      await widget.api.act(
        resource,
        action,
        params: {'id': '${row['id']}'},
        values: values,
      );
      await load();
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              t('تغییرات سازمان اعمال شد.', 'Organization changes applied.'),
            ),
          ),
        );
    } catch (e) {
      if (mounted) socialError(context, e);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> cycle(Json row) async {
    if (busy || !canEdit(row)) return;
    final next = switch (branchStatusCode(row)) {
      'active' => 'inactive',
      'inactive' => 'removed',
      _ => 'active',
    };
    // The existing mobile catalog exposes update, not the website's status route.
    // Preserve every editable field when sending the same state transition.
    await mutate('update', row, values: {...row, 'status': next});
  }

  Widget badge(
    String text,
    Color background,
    Color foreground, {
    VoidCallback? onTap,
  }) => Material(
    color: background,
    borderRadius: appRadius(context),
    child: InkWell(
      onTap: onTap,
      borderRadius: appRadius(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        child: Text(text, style: TextStyle(fontSize: 12, color: foreground)),
      ),
    ),
  );
  Widget statusBadge(Json row) {
    final state = branchStatusCode(row);
    return badge(
      branchStatus(row, fa),
      state == 'active'
          ? const Color(0xffdcfce7)
          : state == 'removed'
          ? const Color(0xfffee2e2)
          : const Color(0xfffef9c3),
      state == 'active'
          ? const Color(0xff15803d)
          : state == 'removed'
          ? const Color(0xffb91c1c)
          : const Color(0xffa16207),
      onTap: busy || !canEdit(row) ? null : () => cycle(row),
    );
  }

  Widget pair(String label, dynamic value) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: TextStyle(fontSize: 14, color: branchSecondary(context)),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 3,
          child: Text(
            value == null ||
                    '$value'.trim().isEmpty ||
                    '$value'.trim() == 'null'
                ? '—'
                : '$value',
            textAlign: TextAlign.end,
            style: TextStyle(fontSize: 14),
          ),
        ),
      ],
    ),
  );
  Json primary(dynamic values) {
    final rows = objects(values ?? []);
    return rows.where((r) => branchFlag(r['is_main'])).firstOrNull ??
        rows.firstOrNull ??
        {};
  }

  Widget buttons(Json row, {bool iconsOnly = false}) {
    final specs = [
      if (!typesOnly)
        (
          t('جزئیات', 'Details'),
          Icons.info_outline,
          branchAccent(context),
          () => details(row),
        ),
      if (canEdit(row))
        (
          t('ویرایش', 'Edit'),
          Icons.edit_outlined,
          branchAccent(context),
          () => edit(row),
        ),
      if (canDelete(row))
        (
          t('حذف', 'Delete'),
          Icons.delete_outline,
          const Color(0xffdc2626),
          () => remove(row),
        ),
    ];
    return Row(
      mainAxisSize: iconsOnly ? MainAxisSize.min : MainAxisSize.max,
      children: [
        for (var i = 0; i < specs.length; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          if (iconsOnly)
            IconButton(
              tooltip: specs[i].$1,
              onPressed: busy ? null : specs[i].$4,
              icon: Icon(specs[i].$2, color: specs[i].$3),
            )
          else
            Expanded(
              child: TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: i == 0 && !typesOnly
                      ? branchAccent(context)
                      : Colors.white,
                  backgroundColor: i == 0 && !typesOnly
                      ? Colors.white
                      : specs[i].$3,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: appRadius(context),
                    side: BorderSide(color: specs[i].$3.withValues(alpha: .25)),
                  ),
                ),
                onPressed: busy ? null : specs[i].$4,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(specs[i].$2, size: 16),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(specs[i].$1, style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ],
    );
  }

  Widget card(Json row) {
    final address = primary(row['addresses']);
    return BranchSurface(
      key: ValueKey('branch-card-${row['id']}'),
      color: branchFlag(row['is_main'])
          ? branchHighlight(context)
          : Theme.of(context).colorScheme.surface,
      border: branchFlag(row['is_main'])
          ? const Color(0xfffcd34d)
          : Theme.of(context).colorScheme.outline,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  '${row['name']}',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 12),
              statusBadge(row),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if ('${row['academy_name'] ?? ''}'.isNotEmpty)
                badge(
                  '${row['academy_name']}',
                  const Color(0xffede9fe),
                  const Color(0xff6d28d9),
                ),
              badge(
                '${row['type'] ?? '—'}',
                const Color(0xffe0e7ff),
                const Color(0xff4338ca),
              ),
              badge(
                branchMode(row['physical_type'], fa),
                const Color(0xffe0f2fe),
                const Color(0xff0369a1),
              ),
            ],
          ),
          if ('${row['slogan'] ?? ''}'.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                '«${row['slogan']}»',
                style: TextStyle(
                  fontSize: 14,
                  color: branchAccent(context),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          const SizedBox(height: 16),
          pair(t('مدیر', 'Manager'), row['manager']),
          pair(
            t('تلفن اصلی', 'Primary phone'),
            primary(row['phones'])['number'],
          ),
          pair(
            t('آدرس اصلی', 'Primary address'),
            ['province', 'city', 'address']
                .map((k) => '${address[k] ?? ''}')
                .where((v) => v.isNotEmpty)
                .join('، '),
          ),
          pair(t('تعداد کلاس', 'Classrooms'), digits(row['classrooms'] ?? 0)),
          const SizedBox(height: 12),
          buttons(row),
        ],
      ),
    );
  }

  Future<void> details(Json row) => showDialog<void>(
    context: context,
    builder: (_) => Theme(
      data: branchTheme(context),
      child: BranchDialog(
        title: '${row['name']}',
        main: branchFlag(row['is_main']),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '${row['academy_name'] ?? '—'} · ${row['type'] ?? '—'} · ${branchMode(row['physical_type'], fa)} · ${branchFlag(row['is_main']) ? t('شعبه اصلی', 'Main branch') : t('شعبه فرعی', 'Secondary branch')}',
              style: TextStyle(color: branchSecondary(context), fontSize: 14),
            ),
            const SizedBox(height: 24),
            for (final e in {
              'id': t('شناسه شعبه', 'Branch ID'),
              'academy_id': t('شناسه آموزشگاه', 'Academy ID'),
              'user_id': t('شناسه حساب', 'Account ID'),
              'username': t('نام کاربری', 'Username'),
              'manager': t('مدیر', 'Manager'),
              'manager_user_id': t('شناسه مدیر', 'Manager ID'),
              'email': t('ایمیل', 'Email'),
              'phone': t('شماره همراه', 'Mobile number'),
              'type': t('نوع آموزشی', 'Education type'),
              'classrooms': t('تعداد کلاس', 'Classrooms'),
            }.entries)
              pair(e.value, row[e.key]),
            pair(t('وضعیت', 'Status'), branchStatus(row, fa)),
            pair(
              t('نوع ارائه', 'Delivery type'),
              branchMode(row['physical_type'], fa),
            ),
            for (final e in {
              'slogan': t('شعار', 'Slogan'),
              'short_description': t('معرفی کوتاه', 'Introduction'),
              'bio': t('بیوگرافی', 'Biography'),
            }.entries) ...[
              const SizedBox(height: 16),
              Text(e.value, style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('${row[e.key] ?? '—'}'),
            ],
            for (final e in {
              'phones': t('شماره‌های تماس', 'Phone numbers'),
              'links': t('لینک‌ها', 'Links'),
              'addresses': t('آدرس‌ها', 'Addresses'),
            }.entries) ...[
              const SizedBox(height: 24),
              Text(e.value, style: TextStyle(fontWeight: FontWeight.bold)),
              if (objects(row[e.key] ?? []).isEmpty) const Text('—'),
              for (final item in objects(row[e.key] ?? []))
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: BranchSurface(
                    padding: 12,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          e.key == 'phones'
                              ? '${item['number'] ?? ''}'
                              : e.key == 'links'
                              ? '${item['title'] ?? ''}\n${item['url'] ?? ''}'
                              : ['province', 'city', 'address']
                                    .map((k) => '${item[k] ?? ''}')
                                    .where((v) => v.isNotEmpty)
                                    .join('، '),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          e.key == 'addresses'
                              ? '${t('کد پستی', 'Postal code')}: ${item['postal_code'] ?? '—'} · ${item['lat'] ?? '—'}, ${item['lng'] ?? '—'}'
                              : '${e.key == 'links' ? '${item['mode'] ?? ''} · ${item['platform'] ?? ''} · ' : ''}${item['priority'] ?? ''}${branchFlag(item['is_main']) ? t(' · اصلی', ' · Primary') : ''}',
                          style: TextStyle(
                            fontSize: 12,
                            color: branchSecondary(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    ),
  );
  Widget stat(String label, int value, Color bg, Color color) => Container(
    key: ValueKey('stat-$label'),
    height: 40,
    padding: const EdgeInsets.symmetric(horizontal: 10),
    decoration: BoxDecoration(color: bg, borderRadius: appRadius(context)),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(fontSize: 11, color: color),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          digits(value),
          style: TextStyle(
            fontSize: 14,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
  Widget filter(
    String key,
    String hint,
    List<Json> rows,
    String value,
    ValueChanged<String> change,
  ) {
    final label = switch (key) {
      'type' => t('نوع آموزشی', 'Education type'),
      'academy' => t('آموزشگاه', 'Academy'),
      'mode' => t('نوع ارائه', 'Delivery type'),
      _ => t('وضعیت', 'Status'),
    };
    final selected = rows.where((r) => '${r['id']}' == value).firstOrNull;
    return Column(
      children: [
        InkWell(
          key: ValueKey('branch-filter-$key'),
          onTap: () async {
            final choice = await showDialog<String>(
              context: context,
              builder: (c) => SimpleDialog(
                shape: RoundedRectangleBorder(borderRadius: appRadius(context)),
                title: Text(label, style: TextStyle(fontSize: 14)),
                children: [
                  SimpleDialogOption(
                    onPressed: () => Navigator.pop(c, ''),
                    child: Text(hint),
                  ),
                  for (final row in rows)
                    SimpleDialogOption(
                      onPressed: () => Navigator.pop(c, '${row['id']}'),
                      child: Text('${row['name'] ?? row['title']}'),
                    ),
                ],
              ),
            );
            if (choice != null && mounted)
              setState(() {
                change(choice);
                page = 1;
              });
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                Expanded(child: Text(label, style: TextStyle(fontSize: 13))),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    selected == null
                        ? hint
                        : '${selected['name'] ?? selected['title']}',
                    textAlign: TextAlign.end,
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
        const Divider(height: .2, thickness: .2, color: Color(0xffeeeeee)),
      ],
    );
  }

  Widget tableView(List<Json> rows) {
    final columns = typesOnly
        ? {
            'title': t('عنوان', 'Title'),
            'summary': t('خلاصه', 'Summary'),
            'description': t('شرح', 'Description'),
          }
        : {
            'academy_name': t('آموزشگاه', 'Academy'),
            'name': t('شعبه', 'Branch'),
            'type': t('نوع', 'Type'),
            'physical_type': t('ارائه', 'Delivery'),
            'manager': t('مدیر', 'Manager'),
            'status': t('وضعیت', 'Status'),
          };
    return BranchSurface(
      padding: 0,
      child: ClipRRect(
        borderRadius: appRadius(context),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            dividerThickness: .2,
            border: const TableBorder(
              horizontalInside: BorderSide(color: Color(0xffeeeeee), width: .2),
            ),
            sortAscending: ascending,
            sortColumnIndex: columns.containsKey(sort)
                ? columns.keys.toList().indexOf(sort)
                : sort == 'id'
                ? columns.length
                : null,
            headingRowColor: WidgetStatePropertyAll(branchCanvas(context)),
            columnSpacing: 24,
            dataRowMinHeight: 64,
            dataRowMaxHeight: 90,
            columns: [
              for (final e in columns.entries)
                DataColumn(
                  label: Text(e.value),
                  onSort: typesOnly
                      ? null
                      : (_, __) => setState(() {
                          ascending = sort == e.key ? !ascending : true;
                          sort = e.key;
                        }),
                ),
              DataColumn(
                label: Text(t('عملیات', 'Actions')),
                onSort: typesOnly
                    ? null
                    : (_, __) => setState(() {
                        ascending = sort == 'id' ? !ascending : true;
                        sort = 'id';
                      }),
              ),
            ],
            rows: [
              for (final r in rows)
                DataRow(
                  color: WidgetStatePropertyAll(
                    branchFlag(r['is_main'])
                        ? branchHighlight(context)
                        : Colors.white,
                  ),
                  cells: [
                    for (final key in columns.keys)
                      DataCell(
                        key == 'status'
                            ? statusBadge(r)
                            : SizedBox(
                                width: typesOnly ? 180 : 115,
                                child: Text(
                                  key == 'physical_type'
                                      ? branchMode(r[key], fa)
                                      : '${r[key] ?? (key == 'title' ? r['name'] : '—')}',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                      ),
                    DataCell(
                      SizedBox(
                        width: typesOnly ? 102 : 156,
                        child: buttons(r, iconsOnly: true),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> export(bool pdf) async {
    final labels = {
      'index': t('ردیف', 'Index'),
      'academy': t('آموزشگاه', 'Academy'),
      'name': t('نام شعبه', 'Branch name'),
      'type': t('نوع آموزشی', 'Education type'),
      'mode': t('نوع ارائه', 'Delivery'),
      'main': t('اصلی', 'Main'),
      'manager': t('مدیر', 'Manager'),
      'status': t('وضعیت', 'Status'),
      'classrooms': t('تعداد کلاس', 'Classrooms'),
    };
    final rows = [
      for (final (i, r) in filtered.indexed)
        {
          'index': i + 1,
          'academy': r['academy_name'] ?? '',
          'name': r['name'],
          'type': r['type'],
          'mode': branchMode(r['physical_type'], fa),
          'main': branchFlag(r['is_main']) ? t('بله', 'Yes') : t('خیر', 'No'),
          'manager': r['manager'] ?? '',
          'status': branchStatus(r, fa),
          'classrooms': r['classrooms'] ?? 0,
        },
    ];
    try {
      if (pdf) {
        await exportBranchesPdf(context, rows, labels);
      } else {
        await exportPanelRows('branches', [
          for (final r in rows)
            {for (final e in r.entries) labels[e.key]!: e.value},
        ]);
      }
    } catch (e) {
      if (mounted) socialError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final rows = filtered;
    final pages = (rows.length / pageSize).ceil().clamp(1, 1000000);
    final current = page.clamp(1, pages);
    final shown = typesOnly
        ? rows
        : rows.skip((current - 1) * pageSize).take(pageSize).toList();
    final title = typesOnly
        ? t('انواع آموزشی', 'Education types')
        : t('مدیریت شعبه‌ها', 'Branch management');
    return Theme(
      data: branchTheme(context),
      child: Scaffold(
        appBar: ExpandingSearchBar(
          title: Row(
            children: [
              const BackButton(),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: AppTopBarDirection.titleSize(context),
                  ),
                ),
              ),
            ],
          ),
          hint: t('جستجو', 'Search'),
          fieldKey: const ValueKey('branch-search'),
          onChanged: (v) => setState(() {
            query = v;
            page = 1;
          }),
          actions: [
            if (canCreate &&
                !typesOnly &&
                actions.containsKey('register-account'))
              IconButton(
                tooltip: t('ثبت حساب شعبه', 'Register branch account'),
                onPressed: loading || busy ? null : registerAccount,
                icon: const Icon(Icons.person_add_alt),
              ),
            if (canCreate)
              IconButton(
                tooltip: typesOnly
                    ? t('نوع آموزشی جدید', 'New education type')
                    : t('افزودن شعبه جدید', 'Add new branch'),
                onPressed: loading || busy ? null : () => edit(),
                icon: const Icon(Icons.add),
              ),
            if (!typesOnly) ...[
              IconButton(
                tooltip: t('خروجی اکسل', 'Export Excel'),
                onPressed: loading || busy ? null : () => export(false),
                icon: const Icon(Icons.table_view, color: Color(0xff16a34a)),
              ),
              IconButton(
                tooltip: t('خروجی PDF', 'Export PDF'),
                onPressed: loading || busy ? null : () => export(true),
                icon: const Icon(
                  Icons.picture_as_pdf_outlined,
                  color: Color(0xffdc2626),
                ),
              ),
            ],
          ],
        ),
        body: withTabs(
          loading
              ? const AppLoadingIndicator()
              : error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        t(
                          'دریافت اطلاعات ممکن نشد.',
                          'Could not load branches.',
                        ),
                      ),
                      TextButton(
                        onPressed: () => load(refresh: true),
                        child: Text(t('تلاش دوباره', 'Retry')),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () => load(refresh: true),
                  child: ListView(
                    padding: const EdgeInsets.all(12),
                    children: [
                      PanelPageGuidance(
                        api: widget.api,
                        section: resource,
                        defaults: optionalObject(
                          panelTableContract(widget.section)['guidance'],
                        ),
                        enabled: widget.section['pageGuidance'] is Map,
                        canEdit:
                            optionalObject(
                              widget.section['pageGuidance'],
                            )['canEdit'] ==
                            true,
                      ),
                      if (!typesOnly) ...[
                        if (branchFlag(data['site_admin'])) ...[
                          Row(
                            children: [
                              Expanded(
                                child: stat(
                                  t('تعداد آموزشگاه‌ها', 'Academies'),
                                  objects(data['academies'] ?? []).isNotEmpty
                                      ? objects(data['academies']).length
                                      : branches
                                            .map((r) => r['academy_id'])
                                            .toSet()
                                            .length,
                                  const Color(0xfff5f3ff),
                                  const Color(0xff6d28d9),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: stat(
                                  t('تعداد شعبه‌ها', 'Branches'),
                                  branches.length,
                                  const Color(0xffeef2ff),
                                  const Color(0xff4338ca),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                        ],
                        AppViewModeSelector<bool>(
                          value: table,
                          onChanged: (v) => setState(() => table = v),
                          options: [
                            AppViewMode(
                              value: true,
                              icon: Icons.table_chart_outlined,
                              label: t('نمایش جدولی', 'Table view'),
                            ),
                            AppViewMode(
                              value: false,
                              icon: Icons.grid_view,
                              label: t('نمایش کارتی', 'Card view'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        PanelSectionCard(
                          horizontalInset: 0,
                          storageId: 'organization-filters',
                          title: t('فیلترها', 'Filters'),
                          children: [
                            filter(
                              'type',
                              t('همه انواع آموزشی', 'All education types'),
                              objects(data['types'] ?? []),
                              type,
                              (v) => type = v,
                            ),
                            if (branchFlag(data['site_admin']) &&
                                !branchFlag(data['branch_account'])) ...[
                              filter(
                                'academy',
                                t('همه آموزشگاه‌ها', 'All academies'),
                                objects(data['academies'] ?? []),
                                academy,
                                (v) => academy = v,
                              ),
                            ],

                            filter(
                              'mode',
                              t('همه انواع ارائه', 'All delivery types'),
                              [
                                for (final k in [
                                  'physical',
                                  'online',
                                  'hybrid',
                                ])
                                  {'id': k, 'name': branchMode(k, fa)},
                              ],
                              mode,
                              (v) => mode = v,
                            ),

                            filter(
                              'status',
                              t('همه وضعیت‌ها', 'All statuses'),
                              [
                                for (final k in [
                                  'active',
                                  'inactive',
                                  'removed',
                                ])
                                  {
                                    'id': k,
                                    'name': branchStatus({'status': k}, fa),
                                  },
                              ],
                              status,
                              (v) => status = v,
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                      ],
                      if (busy) const LinearProgressIndicator(),
                      if (rows.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 64),
                          child: Center(
                            child: Text(
                              t(
                                typesOnly
                                    ? 'نوع آموزشی ثبت نشده است.'
                                    : 'شعبه‌ای یافت نشد',
                                'No results found',
                              ),
                              style: TextStyle(color: branchSecondary(context)),
                            ),
                          ),
                        )
                      else if (table)
                        tableView(shown)
                      else
                        for (final row in shown) ...[
                          card(row),
                          const SizedBox(height: 24),
                        ],
                      if (!typesOnly && branches.length >= 11) ...[
                        const SizedBox(height: 20),
                        BranchSurface(
                          padding: 16,
                          child: Column(
                            children: [
                              Text(
                                t(
                                  'نمایش ${digits(rows.isEmpty ? 0 : (current - 1) * pageSize + 1)} تا ${digits(((current - 1) * pageSize + shown.length))} از ${digits(rows.length)} شعبه',
                                  '${rows.length} branches',
                                ),
                                style: TextStyle(
                                  fontSize: 14,
                                  color: branchSecondary(context),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  DropdownButton<int>(
                                    value: pageSize,
                                    items: [
                                      for (final n in [10, 20, 50, 100])
                                        DropdownMenuItem(
                                          value: n,
                                          child: Text(digits(n)),
                                        ),
                                    ],
                                    onChanged: (v) => setState(() {
                                      pageSize = v!;
                                      page = 1;
                                    }),
                                  ),
                                  OutlinedButton(
                                    onPressed: current > 1
                                        ? () =>
                                              setState(() => page = current - 1)
                                        : null,
                                    child: Text(t('قبلی', 'Previous')),
                                  ),
                                  Text('${digits(current)} / ${digits(pages)}'),
                                  OutlinedButton(
                                    onPressed: current < pages
                                        ? () =>
                                              setState(() => page = current + 1)
                                        : null,
                                    child: Text(t('بعدی', 'Next')),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
