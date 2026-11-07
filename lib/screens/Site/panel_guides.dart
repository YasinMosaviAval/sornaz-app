import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../components/app_async_state.dart';
import '../../components/app_bar.dart';
import '../../components/app_dialog.dart';
import '../Articles/ui/components/article_content_widget.dart';
import '../Authentication/providers/auth_session.dart';
import '../Social/social_widgets.dart';
import 'panel_api.dart';
import 'panel_form.dart';
import 'panel_section_card.dart';
import 'panel_ui.dart';
import '../Social/social_api.dart';

class PanelGuidesPage extends StatefulWidget {
  const PanelGuidesPage({super.key, required this.api, required this.section});
  final PanelApi api;
  final Json section;
  @override
  State<PanelGuidesPage> createState() => _PanelGuidesPageState();
}

class _PanelGuidesPageState extends State<PanelGuidesPage> {
  List<Json> guides = [], documents = [];
  bool loading = true;
  Object? error;
  String search = '';
  bool get library => widget.section['documentLibrary'] is Map;
  String t(String fa, String en) => socialText(context, fa, en);
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final result = await widget.api.live('/guides/list');
      final files = library
          ? await widget.api.get('/guide-documents/list')
          : <String, dynamic>{};
      if (mounted) {
        setState(() {
          guides = objects(result['items'] ?? []);
          documents = objects(files['documents'] ?? []);
          error = null;
          loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          error = e;
          loading = false;
        });
      }
    }
  }

  Future<void> edit(Json guide) async {
    await showDialog<PanelFormResult>(
      context: context,
      builder: (c) => _guideAccess(
        c,
        widget.api,
        PanelFormPage(
          dialog: true,
          title: t('ویرایش راهنما', 'Edit guide'),
          fields: objects(
            optionalObject(
              optionalObject(widget.section['actions'])['update'],
            )['fields'],
          ),
          initial: guide,
          data: const {},
          onSubmit: (result) async {
            await widget.api.act(
              'guides',
              'update',
              values: {...result.values, 'key': guide['key']},
            );
          },
        ),
      ),
    );
    if (mounted) await load();
  }

  Future<void> open(Json document) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PanelGuideDocumentPage(
          api: widget.api,
          document: document,
          documents: documents,
        ),
      ),
    );
    if (mounted) await load();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthSession?>();
    if (auth != null &&
        (auth.token != widget.api.token || auth.user?.id != 1)) {
      return PanelScaffold(
        body: AppEmptyState(
          message: t('دسترسی لازم را ندارید.', 'Access denied.'),
        ),
      );
    }
    final query = search.trim().toLowerCase();
    final visible = documents.where(
      (d) => '${d['title']} ${d['path']}'.toLowerCase().contains(query),
    );
    return PanelScaffold(
      appBar: SornazAppBar(title: t('راهنمای عملکردها', 'Guides')),
      body: loading
          ? const AppLoadingIndicator()
          : error != null
          ? AppErrorState(message: '$error', onRetry: load)
          : RefreshIndicator(
              onRefresh: load,
              child: ListView(
                padding: const EdgeInsets.all(12),
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  if (library) ...[
                    TextField(
                      key: const ValueKey('guide-library-search'),
                      decoration: InputDecoration(
                        labelText: t(
                          'جستجوی نام یا مسیر راهنما',
                          'Search guide title or path',
                        ),
                        prefixIcon: const Icon(Icons.search),
                      ),
                      onChanged: (value) => setState(() => search = value),
                    ),
                    for (final directory in ['docs', 'Modules'])
                      if (visible.any(
                        (d) => '${d['path']}'.startsWith('$directory/'),
                      ))
                        PanelSectionCard(
                          horizontalInset: 0,
                          title: directory == 'docs'
                              ? t('مستندات پروژه', 'Project documentation')
                              : t('راهنمای ماژول‌ها', 'Module documentation'),
                          icon: Icons.folder_outlined,
                          storageId: 'guide-library-$directory',
                          children: [
                            for (final document in visible.where(
                              (d) => '${d['path']}'.startsWith('$directory/'),
                            ))
                              ListTile(
                                key: ValueKey('guide-${document['path']}'),
                                title: Text('${document['title']}'),
                                subtitle: Text('${document['path']}'),
                                leading: const Icon(Icons.description_outlined),
                                onTap: () => open(document),
                              ),
                          ],
                        ),
                    if (visible.isEmpty)
                      AppEmptyState(
                        message: t('راهنمایی پیدا نشد.', 'No guides found.'),
                      ),
                  ],
                  for (final guide in guides)
                    PanelSectionCard(
                      title: '${guide['title']}',
                      horizontalInset: 0,
                      icon: Icons.menu_book_outlined,
                      children: [
                        if (optionalObject(
                          widget.section['actions'],
                        ).containsKey('update'))
                          Align(
                            alignment: AlignmentDirectional.centerEnd,
                            child: IconButton(
                              tooltip: t('ویرایش راهنما', 'Edit guide'),
                              icon: const Icon(Icons.edit_outlined),
                              onPressed: () => edit(guide),
                            ),
                          ),
                        if (guide['html'] is String)
                          ArticlesContentWidget(
                            content: guide['html'] as String,
                          )
                        else
                          SelectableText('${guide['content'] ?? ''}'),
                      ],
                    ),
                ],
              ),
            ),
    );
  }
}

class PanelGuideDocumentPage extends StatefulWidget {
  const PanelGuideDocumentPage({
    super.key,
    required this.api,
    required this.document,
    required this.documents,
  });
  final PanelApi api;
  final Json document;
  final List<Json> documents;
  @override
  State<PanelGuideDocumentPage> createState() => _PanelGuideDocumentPageState();
}

class _PanelGuideDocumentPageState extends State<PanelGuideDocumentPage> {
  Json? document;
  Object? error;
  bool deleting = false;
  String t(String fa, String en) => socialText(context, fa, en);
  String get path => '${widget.document['path']}';
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final value = await widget.api.get('/guide-documents/read', {
        'path': path,
      });
      if (mounted) {
        setState(() {
          document = value;
          error = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => error = e);
    }
  }

  Future<void> edit() async {
    final current = document;
    if (current == null) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (c) => _guideAccess(
          c,
          widget.api,
          PanelFormPage(
            title: t('ویرایش فایل راهنما', 'Edit guide document'),
            fields: [
              {
                'key': 'content',
                'label': 'متن راهنما',
                'en': 'Guide content',
                'type': 'multiline',
                'minLines': 18,
                'maxLines': 24,
                'maxLength': 2097152,
                'required': false,
              },
            ],
            initial: {'content': current['content']},
            data: const {},
            onSubmit: (result) async {
              // Keep the version opened by the editor. Conflict must retain typed text.
              final saved = await widget.api.act(
                'guide-documents',
                'update',
                values: {
                  'path': path,
                  'version': current['version'],
                  'content': result.values['content'] ?? '',
                },
              );
              if (mounted) setState(() => document = saved);
            },
          ),
        ),
      ),
    );
  }

  Future<void> remove() async {
    final current = document;
    if (current == null || deleting) return;
    if (await showDeleteConfirmation(
              context,
              title: t('حذف فایل راهنما؟', 'Delete guide document?'),
              message: path,
            ) !=
            true ||
        !mounted) {
      return;
    }
    setState(() => deleting = true);
    try {
      await widget.api.act(
        'guide-documents',
        'delete',
        values: {'path': path, 'version': current['version']},
      );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) socialError(context, e);
    } finally {
      if (mounted) setState(() => deleting = false);
    }
  }

  Future<void> link(String value) async {
    final uri = Uri.tryParse(value);
    if (uri == null) return;
    if (!uri.hasScheme) {
      final target = Uri(path: path).resolveUri(uri).path;
      final next = widget.documents
          .where((d) => d['path'] == target)
          .firstOrNull;
      if (next != null && mounted) {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => PanelGuideDocumentPage(
              api: widget.api,
              document: next,
              documents: widget.documents,
            ),
          ),
        );
      }
      return;
    }
    if (['http', 'https'].contains(uri.scheme)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthSession?>();
    if (auth != null &&
        (auth.token != widget.api.token || auth.user?.id != 1)) {
      return PanelScaffold(
        body: AppEmptyState(
          message: t('دسترسی لازم را ندارید.', 'Access denied.'),
        ),
      );
    }
    return PanelScaffold(
      appBar: SornazAppBar(
        title: '${document?['title'] ?? widget.document['title'] ?? path}',
        actions: [
          if (document != null) ...[
            IconButton(
              tooltip: t('ویرایش', 'Edit'),
              onPressed: deleting ? null : edit,
              icon: const Icon(Icons.edit_outlined),
            ),
            IconButton(
              tooltip: t('حذف', 'Delete'),
              onPressed: deleting ? null : remove,
              icon: const Icon(Icons.delete_outline),
            ),
          ],
        ],
      ),
      body: error != null
          ? AppErrorState(message: '$error', onRetry: load)
          : document == null
          ? const AppLoadingIndicator()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SelectableText(
                    path,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 12),
                  ArticlesContentWidget(
                    content: '${document!['html'] ?? ''}',
                    onLinkTap: link,
                  ),
                ],
              ),
            ),
    );
  }
}

Widget _guideAccess(BuildContext context, PanelApi api, Widget child) {
  return Consumer<AuthSession?>(
    child: child,
    builder: (context, auth, child) {
      if (auth != null && (auth.token != api.token || auth.user?.id != 1)) {
        return PanelScaffold(
          body: AppEmptyState(
            message: socialText(
              context,
              'دسترسی لازم را ندارید.',
              'Access denied.',
            ),
          ),
        );
      }
      return child!;
    },
  );
}
