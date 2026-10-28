import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../Authentication/providers/auth_session.dart';
import 'package:sornaz/components/app_top_bar_direction.dart';
import 'package:sornaz/components/expanding_search_bar.dart';
import '../Social/social_widgets.dart';
import '../Social/social_api.dart';
import 'panel_api.dart';
import 'panel_ui.dart';

/// Founder-only data is fetched afresh and is never placed in offline storage.
class PanelDatabasePage extends StatefulWidget {
  const PanelDatabasePage({super.key, required this.api});
  final PanelApi api;
  @override
  State<PanelDatabasePage> createState() => _PanelDatabasePageState();
}

class _PanelDatabasePageState extends State<PanelDatabasePage> {
  Json data = {};
  String search = '', table = '';
  int page = 1, sequence = 0;
  bool loading = true, downloading = false, accessDenied = false;
  Object? error;
  Timer? searchTimer;
  BuildContext? valueDialogContext;
  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void dispose() {
    sequence++;
    searchTimer?.cancel();
    data = {};
    super.dispose();
  }

  Future<void> load() async {
    final version = ++sequence;
    setState(() => loading = true);
    try {
      final value = await widget.api.sensitiveGet(
        '/database-management/${table.isEmpty ? 'list' : 'rows'}',
        {
          'page': '$page',
          if (table.isNotEmpty) 'table': table,
          if (table.isNotEmpty) 'name': table,
          if (table.isEmpty && search.trim().isNotEmpty)
            'search': search.trim(),
        },
      );
      if (!mounted || version != sequence) return;
      setState(() {
        data = value;
        error = null;
        accessDenied = false;
        loading = false;
      });
    } catch (e) {
      if (mounted && version == sequence) {
        eraseDeniedData(e);
        setState(() {
          data = {};
          error = e;
          loading = false;
        });
      }
    }
  }

  String text(String fa, String en) => socialText(context, fa, en);
  void eraseDeniedData(Object error) {
    if (error is! SocialException || ![401, 403].contains(error.status)) return;
    sequence++;
    searchTimer?.cancel();
    final dialog = valueDialogContext;
    if (dialog != null &&
        dialog.mounted &&
        ModalRoute.of(dialog)?.isCurrent == true)
      Navigator.of(dialog).pop();
    valueDialogContext = null;
    setState(() {
      data = {};
      table = '';
      search = '';
      page = 1;
      accessDenied = true;
      loading = false;
      this.error = error;
    });
  }

  Future<void> download(String mode, {String name = ''}) async {
    if (downloading || loading || accessDenied) return;
    setState(() => downloading = true);
    try {
      await widget.api.downloadDatabase(
        name.isEmpty ? 'download-$mode' : 'table-$mode',
        {
          if (name.isNotEmpty) ...{'table': name, 'name': name},
        },
        '${name.isEmpty ? 'database' : name}-${mode == 'schema' ? 'schema' : 'full'}.sql',
      );
    } catch (e) {
      if (mounted) {
        eraseDeniedData(e);
        socialError(context, e);
      }
    } finally {
      if (mounted) setState(() => downloading = false);
    }
  }

  Widget export(String mode, {String name = ''}) => IconButton(
    tooltip: text(
      mode == 'schema'
          ? 'دانلود ساختار جدول‌ها'
          : 'دانلود ساختار و اطلاعات جدول‌ها',
      mode == 'schema' ? 'Download schema' : 'Download schema and data',
    ),
    onPressed: downloading || loading || accessDenied
        ? null
        : () => download(mode, name: name),
    icon: Icon(
      mode == 'schema' ? Icons.schema_outlined : Icons.download_outlined,
    ),
  );
  Widget pagination() {
    final total = number(data['total']),
        perPage = number(data['perPage']) > 0 ? number(data['perPage']) : 10;
    final last = (total / perPage).ceil().clamp(1, 1000000000);
    if (total <= perPage && page == 1) return const SizedBox.shrink();
    void go(int value) {
      setState(() => page = value);
      load();
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          tooltip: text('اول', 'First'),
          onPressed: page > 1 ? () => go(1) : null,
          icon: const Icon(Icons.first_page),
        ),
        IconButton(
          tooltip: text('قبلی', 'Previous'),
          onPressed: page > 1 ? () => go(page - 1) : null,
          icon: const Icon(Icons.chevron_left),
        ),
        Text('$page / $last'),
        IconButton(
          tooltip: text('بعدی', 'Next'),
          onPressed: page < last ? () => go(page + 1) : null,
          icon: const Icon(Icons.chevron_right),
        ),
        IconButton(
          tooltip: text('آخر', 'Last'),
          onPressed: page < last ? () => go(last) : null,
          icon: const Icon(Icons.last_page),
        ),
      ],
    );
  }

  void openTable(String name) {
    setState(() {
      table = name;
      page = 1;
      data = {};
    });
    load();
  }

  String cell(dynamic value) {
    if (value == null) return 'NULL';
    if (value is Map && value['type'] == 'binary')
      return 'base64: ${value['value'] ?? ''}';
    return value is Map || value is List
        ? const JsonEncoder.withIndent('  ').convert(value)
        : '$value';
  }

  void showValue(String name, dynamic value) => unawaited(
    showDialog<void>(
      context: context,
      builder: (context) {
        valueDialogContext = context;
        return PanelModal(
          title: name,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * .6,
            ),
            child: SingleChildScrollView(child: SelectableText(cell(value))),
          ),
        );
      },
    ).whenComplete(() => valueDialogContext = null),
  );
  Widget tables() {
    final rows = objects(data['tables']);
    if (rows.isEmpty)
      return Center(child: Text(text('جدولی یافت نشد.', 'No tables found.')));
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: WidgetStatePropertyAll(
          Theme.of(context).colorScheme.surfaceContainerHighest,
        ),
        columns: [
          for (final label in [
            text('جدول', 'Table'),
            text('نوع', 'Type'),
            text('تعداد تقریبی سطرها', 'Estimated rows'),
            text('عملیات', 'Actions'),
          ])
            DataColumn(label: Text(label)),
        ],
        rows: [
          for (final row in rows)
            DataRow(
              cells: [
                DataCell(
                  Text('${row['name']}'),
                  onTap: () => openTable('${row['name']}'),
                ),
                DataCell(Text('${row['type'] ?? ''}')),
                DataCell(Text('${row['estimatedRows'] ?? '—'}')),
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: text('مشاهده سطرها', 'View rows'),
                        onPressed: () => openTable('${row['name']}'),
                        icon: const Icon(Icons.table_rows_outlined),
                      ),
                      export('schema', name: '${row['name']}'),
                      export('data', name: '${row['name']}'),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget records() {
    final columns = objects(data['columns']), rows = objects(data['rows']);
    if (columns.isEmpty)
      return Text(text('ستونی موجود نیست.', 'No columns available.'));
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: WidgetStatePropertyAll(
          Theme.of(context).colorScheme.surfaceContainerHighest,
        ),
        columns: [
          for (final column in columns)
            DataColumn(
              label: Tooltip(
                message: '${column['type'] ?? ''}',
                child: Text('${column['name']}'),
              ),
            ),
        ],
        rows: [
          for (final row in rows)
            DataRow(
              cells: [
                for (final column in columns)
                  DataCell(
                    SizedBox(
                      width: 180,
                      child: Text(
                        cell(row[column['name']]),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    onTap: () =>
                        showValue('${column['name']}', row[column['name']]),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final account = context.watch<AuthSession?>();
    if (account != null && account.token != widget.api.token) {
      if (!accessDenied)
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted)
            eraseDeniedData(const SocialException('Access denied', 401));
        });
      return PanelScaffold(
        appBar: AppBar(
          title: Text(text('مدیریت دیتابیس', 'Database management')),
        ),
        body: Center(
          child: Text(
            text('برای ادامه وارد حساب شوید.', 'Sign in to continue.'),
          ),
        ),
      );
    }
    final title = table.isEmpty
        ? text('مدیریت دیتابیس', 'Database management')
        : table;
    return PanelScaffold(
      appBar: table.isEmpty
          ? ExpandingSearchBar(
              key: ValueKey('database-search-$accessDenied'),
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
              hint: text('جستجوی جدول', 'Search tables'),
              onChanged: (value) {
                search = value;
                searchTimer?.cancel();
                searchTimer = Timer(const Duration(milliseconds: 300), () {
                  page = 1;
                  load();
                });
              },
            )
          : AppTopBarDirection(
              child: AppBar(
                title: Text(title),
                leading: BackButton(
                  onPressed: () {
                    setState(() {
                      table = '';
                      page = 1;
                      data = {};
                    });
                    load();
                  },
                ),
              ),
            ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                export('schema', name: table),
                export('data', name: table),
                if (downloading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            Expanded(
              child: loading
                  ? const Center(child: CircularProgressIndicator())
                  : error != null
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            text(
                              'دریافت اطلاعات ممکن نشد.',
                              'Could not load database information.',
                            ),
                          ),
                          TextButton(
                            onPressed: load,
                            child: Text(text('تلاش دوباره', 'Retry')),
                          ),
                        ],
                      ),
                    )
                  : SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          table.isEmpty ? tables() : records(),
                          pagination(),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
