import 'package:file_picker/file_picker.dart';
import '../../components/media_dialogs.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../Social/social_api.dart';
import '../Social/social_widgets.dart';
import '../Social/media_picker.dart';
import 'panel_api.dart';
import 'panel_form.dart';

class PanelGallery extends StatelessWidget {
  const PanelGallery({
    super.key,
    required this.api,
    required this.rows,
    required this.fields,
    required this.data,
    required this.canEdit,
    this.canDelete = false,
    required this.onChanged,
  });
  final PanelApi api;
  final List<Json> rows, fields;
  final Json data;
  final bool canEdit, canDelete;
  final VoidCallback onChanged;
  @override
  Widget build(BuildContext context) {
    if (rows.length == 1)
      return GalleryRecord(
        key: ValueKey(rows.single['id']),
        api: api,
        row: rows.single,
        fields: fields,
        data: data,
        canEdit: canEdit,
        canDelete: canDelete,
        onChanged: onChanged,
      );
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(8),
      itemCount: rows.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 9 / 16,
        crossAxisSpacing: 6,
        mainAxisSpacing: 6,
      ),
      itemBuilder: (context, index) => InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => GalleryRecord(
              api: api,
              row: rows[index],
              fields: fields,
              data: data,
              canEdit: canEdit,
              canDelete: canDelete,
              onChanged: onChanged,
              standalone: true,
            ),
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: GalleryPreview(
                key: ValueKey(rows[index]['url']),
                token: api.token,
                row: rows[index],
                thumbnail: true,
              ),
            ),
            Text(
              '${rows[index]['title'] ?? ''}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
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
  });
  final PanelApi api;
  final Json row, data;
  final List<Json> fields;
  final bool canEdit, canDelete, standalone;
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
      'gallery',
      'update',
      params: {'id': '${row['id']}'},
      values: result.values,
      files: result.files,
    );
    if (mounted) setState(() => row = saved);
    widget.onChanged();
  }

  Future<void> remove() async {
    if (!await confirmMediaDelete(
          context,
          socialText(context, 'حذف رسانه؟', 'Delete media?'),
        ) ||
        !mounted)
      return;
    setState(() => busy = true);
    try {
      await widget.api.act('gallery', 'delete', params: {'id': '${row['id']}'});
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
        final result = await Navigator.push<PanelFormResult>(
          context,
          MaterialPageRoute(
            builder: (_) => PanelFormPage(
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
                        'imagesOnly': [
                          'cover',
                          'logo',
                        ].contains(row['category']),
                      },
                    },
              ],
              onSubmit: save,
            ),
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
          icon: const Icon(Icons.delete_outline),
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
        ? Scaffold(
            appBar: AppBar(
              title: Text('${row['title'] ?? ''}'),
              actions: actions,
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
        fit: widget.thumbnail ? BoxFit.cover : BoxFit.contain,
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
