import 'package:file_picker/file_picker.dart';
import 'panel_ui.dart';
import '../../components/app_top_bar_direction.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../Social/social_api.dart';
import '../Social/social_widgets.dart';
import '../Social/media_picker.dart';
import 'panel_api.dart';
import 'panel_form.dart';
import '../../helpers/app_appearance.dart';

const panelGalleryCategories = [
  ('cover', 'کاور', 'Cover'),
  ('logo', 'لوگو', 'Logo'),
  ('intro_video', 'ویدیو معرفی', 'Intro video'),
  ('gallery', 'گالری', 'Gallery'),
];

String panelGalleryAddTitle(String category, {required bool fa}) =>
    switch (category) {
      'cover' => fa ? 'افزودن کاور' : 'Add cover',
      'logo' => fa ? 'افزودن لوگو' : 'Add logo',
      'intro_video' => fa ? 'افزودن ویدیو معرفی' : 'Add intro video',
      _ => fa ? 'افزودن آیتم به گالری' : 'Add gallery item',
    };

String panelGallerySuggestedTitle(Json values, Json data, {required bool fa}) {
  final owners = objects(data['owners'] ?? []);
  final owner = owners
      .where((owner) => '${owner['userId']}' == '${values['ownerId']}')
      .firstOrNull;
  final name =
      '${owner?['name'] ?? optionalObject(data['profile'])['name'] ?? data['_ownerName'] ?? (fa ? 'حساب' : 'Account')}';
  final category = '${values['collection'] ?? 'gallery'}';
  final label = panelGalleryCategories.firstWhere(
    (item) => item.$1 == category,
    orElse: () => panelGalleryCategories.last,
  );
  if (category != 'gallery') return '${fa ? label.$2 : label.$3} ($name)';
  final count =
      objects(data['items'] ?? [])
          .where(
            (row) =>
                row['category'] == 'gallery' &&
                (values['ownerId'] == null ||
                    '${row['ownerId']}' == '${values['ownerId']}'),
          )
          .length +
      1;
  return fa ? 'آیتم شماره $count گالری ($name)' : 'Gallery item $count ($name)';
}

class PanelGallery extends StatefulWidget {
  const PanelGallery({
    super.key,
    required this.api,
    required this.rows,
    required this.fields,
    required this.data,
    required this.canEdit,
    this.canDelete = false,
    this.sectionKey = 'gallery',
    required this.onChanged,
  });
  final PanelApi api;
  final String sectionKey;
  final List<Json> rows, fields;
  final Json data;
  final bool canEdit, canDelete;
  final VoidCallback onChanged;
  @override
  State<PanelGallery> createState() => _PanelGalleryState();
}

class _PanelGalleryState extends State<PanelGallery> {
  Future<void> view(Json row) async {
    final viewerRows = widget.rows
        .where((item) => item['category'] == row['category'])
        .toList();
    var index = viewerRows.indexOf(row);
    await showDialog<void>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, update) {
          final item = viewerRows[index];
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: appRadius(context)),
            insetPadding: const EdgeInsets.all(12),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1152),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    title: Text('${item['title'] ?? ''}'),
                    subtitle: Text(
                      '${index + 1} / ${viewerRows.length} · ${item['ownerName'] ?? ''}',
                    ),
                    trailing: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ),
                  Flexible(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        AspectRatio(
                          aspectRatio: 16 / 9,
                          child: GalleryPreview(
                            key: ValueKey('${item['id']}-${item['url']}'),
                            token: widget.api.token,
                            row: item,
                          ),
                        ),
                        if (viewerRows.length > 1)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton.filled(
                                tooltip: socialText(
                                  context,
                                  'قبلی',
                                  'Previous',
                                ),
                                onPressed: () => update(
                                  () => index =
                                      (index - 1 + viewerRows.length) %
                                      viewerRows.length,
                                ),
                                icon: const Icon(Icons.chevron_left),
                              ),
                              IconButton.filled(
                                tooltip: socialText(context, 'بعدی', 'Next'),
                                onPressed: () => update(
                                  () => index = (index + 1) % viewerRows.length,
                                ),
                                icon: const Icon(Icons.chevron_right),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            '${item['summary'] ?? '—'}',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text('${item['description'] ?? ''}'),
                          const SizedBox(height: 8),
                          Text(
                            '${item['date'] ?? ''}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const categories = panelGalleryCategories;
    final selected = '${widget.data['_category'] ?? ''}';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final category in categories.where(
            (c) => selected.isEmpty || c.$1 == selected,
          )) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Text(
                socialText(context, category.$2, category.$3),
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            if (!widget.rows.any(
              (row) => '${row['category'] ?? 'gallery'}' == category.$1,
            ))
              Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  socialText(
                    context,
                    'آیتمی در این بخش وجود ندارد',
                    'No items in this section',
                  ),
                ),
              ),
            LayoutBuilder(
              builder: (context, size) {
                final columns = size.maxWidth >= 1000
                    ? 3
                    : size.maxWidth >= 700
                    ? 2
                    : 1;
                return Wrap(
                  spacing: 24,
                  runSpacing: 24,
                  children: [
                    for (final row in widget.rows.where(
                      (row) => '${row['category'] ?? 'gallery'}' == category.$1,
                    ))
                      SizedBox(
                        width: (size.maxWidth - (columns - 1) * 24) / columns,
                        child: GalleryRecord(
                          key: ValueKey(row['id']),
                          sectionKey: widget.sectionKey,
                          api: widget.api,
                          row: row,
                          fields: widget.fields,
                          data: widget.data,
                          canEdit: widget.canEdit,
                          canDelete: widget.canDelete,
                          onChanged: widget.onChanged,
                          compactCard: true,
                          detailed: true,
                          onView: () => view(row),
                        ),
                      ),
                  ],
                );
              },
            ),
            const Divider(height: 48),
          ],
        ],
      ),
    );
  }
}

class GalleryRecord extends StatefulWidget {
  const GalleryRecord({
    super.key,
    required this.api,
    required this.row,
    required this.fields,
    required this.data,
    required this.canEdit,
    this.canDelete = false,
    required this.onChanged,
    this.standalone = false,
    this.sectionKey = 'gallery',
    this.compactCard = false,
    this.detailed = false,
    this.onView,
  });
  final PanelApi api;
  final String sectionKey;
  final Json row, data;
  final List<Json> fields;
  final bool canEdit, canDelete, standalone;
  final bool compactCard, detailed;
  final VoidCallback? onView;
  final VoidCallback onChanged;
  @override
  State<GalleryRecord> createState() => _GalleryRecordState();
}

class _GalleryRecordState extends State<GalleryRecord> {
  late Json row = widget.row;
  bool busy = false;
  @override
  void didUpdateWidget(GalleryRecord old) {
    super.didUpdateWidget(old);
    if (old.row != widget.row) row = widget.row;
  }

  Future<void> save(PanelFormResult result) async {
    final saved = await widget.api.act(
      widget.sectionKey,
      'update',
      params: {'id': '${row['id']}'},
      values: result.values,
      files: result.files,
    );
    if (mounted) setState(() => row = saved);
    widget.onChanged();
  }

  Future<void> remove() async {
    if (!await showPanelConfirmation(
          context,
          socialText(context, 'حذف رسانه؟', 'Delete media?'),
          delete: true,
        ) ||
        !mounted)
      return;
    setState(() => busy = true);
    try {
      await widget.api.act(
        widget.sectionKey,
        'delete',
        params: {'id': '${row['id']}'},
      );
      widget.onChanged();
      if (mounted && widget.standalone) Navigator.pop(context);
    } catch (e) {
      if (mounted) socialError(context, e);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> edit({bool crop = false}) async {
    if (busy) return;
    setState(() => busy = true);
    try {
      if (crop) {
        final uri = Uri.parse(SocialApi.base).resolve('${row['url']}');
        if (uri.origin != Uri.parse(SocialApi.base).origin)
          throw const FormatException('Invalid media address');
        final response = await widget.api.client.get(
          uri,
          headers: widget.api.headers,
        );
        widget.api.checkAccount();
        if (response.statusCode != 200)
          throw const FormatException('Image unavailable');
        if (!mounted) return;
        final file = await Navigator.push<PlatformFile>(
          context,
          MaterialPageRoute(
            builder: (_) => ImageCropPage(bytes: response.bodyBytes),
          ),
        );
        if (file != null) await save(PanelFormResult({...row}, {'file': file}));
      } else {
        final result = await showDialog<PanelFormResult>(
          context: context,
          builder: (_) => PanelFormPage(
            dialog: true,
            title: socialText(context, 'ویرایش', 'Edit'),
            data: widget.data,
            initial: {...row, 'collection': row['category']},
            fields: [
              for (final field in widget.fields)
                if (!['collection', 'ownerId'].contains(field['key']))
                  {
                    ...field,
                    if (field['type'] == 'file') ...{
                      'mediaPicker': true,
                      'imagesOnly': ['cover', 'logo'].contains(row['category']),
                    },
                  },
            ],
            onSubmit: save,
          ),
        );
        if (result == null) return;
      }
    } catch (e) {
      if (mounted) socialError(context, e);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final actions = <Widget>[
      if (widget.canDelete)
        IconButton(
          tooltip: socialText(context, 'حذف', 'Delete'),
          onPressed: busy ? null : remove,
          icon: const Icon(Icons.delete_outline, color: Colors.red),
        ),
      if (widget.canEdit)
        IconButton(
          tooltip: socialText(context, 'ویرایش', 'Edit'),
          onPressed: busy ? null : () => edit(),
          icon: const Icon(Icons.edit_outlined),
        ),
      if (widget.canEdit && row['type'] != 'video')
        IconButton(
          tooltip: socialText(context, 'برش تصویر', 'Crop image'),
          onPressed: busy ? null : () => edit(crop: true),
          icon: const Icon(Icons.crop),
        ),
    ];
    if (widget.compactCard)
      return Card(
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: appRadius(context)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              onTap: widget.onView,
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    GalleryPreview(
                      key: ValueKey(row['url']),
                      token: widget.api.token,
                      row: row,
                      thumbnail: true,
                    ),
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Chip(
                        label: Text(
                          row['type'] == 'video'
                              ? socialText(context, 'ویدیو', 'Video')
                              : socialText(context, 'تصویر', 'Image'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '${row['title'] ?? ''}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  if (widget.detailed) ...[
                    Text(
                      '${row['date'] ?? ''}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${row['summary'] ?? '—'}',
                      maxLines: 2,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${row['description'] ?? socialText(context, 'بدون توضیحات', 'No description')}',
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 16),
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        '${row['ownerName'] ?? ''}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: actions
                            .take(widget.canDelete && widget.canEdit ? 2 : 1)
                            .toList(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!widget.standalone)
          Row(mainAxisAlignment: MainAxisAlignment.end, children: actions),
        if (busy) const LinearProgressIndicator(),
        SizedBox(
          height: row['type'] == 'video' ? null : 320,
          child: GalleryPreview(
            key: ValueKey(row['url']),
            token: widget.api.token,
            row: row,
          ),
        ),
        for (final key in ['title', 'summary', 'description'])
          if ('${row[key] ?? ''}'.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                '${row[key]}',
                style: TextStyle(fontSize: key == 'title' ? 16 : 13),
              ),
            ),
      ],
    );
    return widget.standalone
        ? PanelScaffold(
            appBar: AppTopBarDirection(
              child: AppBar(
                title: Text('${row['title'] ?? ''}'),
                actions: actions,
              ),
            ),
            body: SingleChildScrollView(child: body),
          )
        : body;
  }
}

class GalleryPreview extends StatefulWidget {
  const GalleryPreview({
    super.key,
    required this.token,
    required this.row,
    this.thumbnail = false,
  });
  final String token;
  final Json row;
  final bool thumbnail;
  @override
  State<GalleryPreview> createState() => _GalleryPreviewState();
}

class _GalleryPreviewState extends State<GalleryPreview> {
  late final api = SocialApi(widget.token);
  VideoPlayerController? player;
  @override
  void initState() {
    super.initState();
    if (widget.thumbnail && widget.row['type'] == 'video') load();
  }

  Future<void> load() async {
    final c = VideoPlayerController.networkUrl(
      Uri.parse(api.media('${widget.row['url']}')),
      httpHeaders: api.headers,
    );
    player = c;
    try {
      await c.initialize();
      if (mounted) setState(() {});
    } catch (_) {}
  }

  @override
  void dispose() {
    player?.dispose();
    api.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.row['type'] != 'video')
      return SocialImage(
        api: api,
        path: widget.row['url'],
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.contain,
      );
    if (!widget.thumbnail)
      return Center(
        child: SocialVideo(
          api: api,
          path: '${widget.row['url']}',
          postControls: true,
        ),
      );
    return Stack(
      fit: StackFit.expand,
      children: [
        if (player?.value.isInitialized == true)
          VideoPlayer(player!)
        else
          const ColoredBox(color: Colors.black12),
        const Center(child: Icon(Icons.play_circle_fill, color: Colors.white)),
      ],
    );
  }
}
