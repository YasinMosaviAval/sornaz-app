import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../Authentication/providers/auth_session.dart';
import '../Social/social_api.dart';
import '../Social/social_widgets.dart';
import 'panel_api.dart';
import 'panel_parity.dart';
import 'panel_ui.dart';

Future<void> showPanelSessionFiles(
  BuildContext context,
  PanelApi api,
  Json session,
) async {
  final id = '${session['sessionId'] ?? session['id'] ?? ''}';
  if (!RegExp(r'^[1-9]\d*$').hasMatch(id)) return;
  await showDialog<void>(
    context: context,
    builder: (_) => PanelSessionFiles(
      api: api,
      sessionId: id,
      sessionTitle: '${session['title'] ?? session['date'] ?? ''}',
    ),
  );
}

class PanelSessionFiles extends StatefulWidget {
  const PanelSessionFiles({
    super.key,
    required this.api,
    required this.sessionId,
    this.sessionTitle = '',
  });
  final PanelApi api;
  final String sessionId, sessionTitle;
  @override
  State<PanelSessionFiles> createState() => _PanelSessionFilesState();
}

class _PanelSessionFilesState extends State<PanelSessionFiles> {
  Json data = {};
  Object? error;
  bool loading = true, busy = false, denied = false;
  int version = 0;
  String text(String fa, String en) => socialText(context, fa, en);

  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void dispose() {
    version++;
    data = {};
    super.dispose();
  }

  bool clearDenied(Object exception) {
    if (exception is! SocialException ||
        ![401, 403].contains(exception.status)) {
      return false;
    }
    version++;
    data = {};
    denied = true;
    error = exception;
    return true;
  }

  Future<void> load() async {
    final request = ++version;
    setState(() => loading = true);
    try {
      final response = await widget.api.sensitiveGet(
        '/schedules/session-files',
        {'id': widget.sessionId},
      );
      widget.api.checkAccount();
      if (!mounted || request != version) return;
      setState(() {
        data = response;
        error = null;
        denied = false;
      });
    } catch (exception) {
      if (mounted && request == version) {
        setState(() {
          clearDenied(exception);
          data = {};
          error = exception;
        });
      }
    } finally {
      if (mounted && (request == version || denied)) {
        setState(() => loading = false);
      }
    }
  }

  Future<void> upload() async {
    if (busy || loading || denied || data['canUpload'] != true) return;
    setState(() => busy = true);
    try {
      widget.api.checkAccount();
      final picked = await FilePicker.platform.pickFiles(withData: false);
      widget.api.checkAccount();
      if (!mounted || picked == null || picked.files.isEmpty) return;
      final file = picked.files.single;
      final limit = number(data['maxBytes']) > 0
          ? number(data['maxBytes'])
          : 100 * 1024 * 1024;
      if (file.size <= 0 || file.size > limit) {
        throw SocialException(
          text(
            'فایل خالی است یا حجم آن بیشتر از حد مجاز است.',
            'The file is empty or exceeds the upload limit.',
          ),
        );
      }
      await widget.api.act(
        'schedules',
        'session-file-upload',
        params: {'id': widget.sessionId},
        files: {'file': file},
      );
      if (mounted) await load();
    } catch (exception) {
      if (mounted) {
        setState(() => clearDenied(exception));
        socialError(context, exception);
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> download(Json file) async {
    if (busy || loading || denied || data['canDownload'] != true) return;
    setState(() => busy = true);
    try {
      await widget.api.downloadSessionFile(
        widget.sessionId,
        '${file['id']}',
        '${file['name'] ?? 'download'}',
        mime: '${file['mime'] ?? 'application/octet-stream'}',
      );
    } catch (exception) {
      if (mounted) {
        setState(() => clearDenied(exception));
        socialError(context, exception);
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> remove(Json file) async {
    if (busy || loading || denied || file['canDelete'] != true) return;
    if (!await showPanelConfirmation(
      context,
      text('حذف فایل', 'Delete file'),
      message: '${file['name'] ?? ''}',
      delete: true,
    )) {
      return;
    }
    if (!mounted) return;
    setState(() => busy = true);
    try {
      await widget.api.act(
        'schedules',
        'session-file-delete',
        params: {'id': widget.sessionId, 'file': '${file['id']}'},
      );
      if (mounted) await load();
    } catch (exception) {
      if (mounted) {
        setState(() => clearDenied(exception));
        socialError(context, exception);
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  IconData fileIcon(String mime) {
    if (mime.startsWith('image/')) return Icons.image_outlined;
    if (mime.startsWith('audio/')) return Icons.audio_file_outlined;
    if (mime.startsWith('video/')) return Icons.video_file_outlined;
    if (mime == 'application/pdf') return Icons.picture_as_pdf_outlined;
    return Icons.insert_drive_file_outlined;
  }

  @override
  Widget build(BuildContext context) {
    context.watch<AuthSession?>();
    try {
      widget.api.checkAccount();
    } catch (exception) {
      clearDenied(exception);
      loading = false;
    }
    final files = objects(data['files'] ?? []);
    final fa = Localizations.localeOf(context).languageCode == 'fa';
    return PanelModal(
      title: text('فایل‌های جلسه', 'Session files'),
      busy: busy,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.sessionTitle.isNotEmpty && !denied)
            Text(widget.sessionTitle),
          Row(
            children: [
              if (data['canUpload'] == true && !denied)
                IconButton.filled(
                  key: const ValueKey('session-file-upload'),
                  tooltip: text('آپلود فایل جلسه', 'Upload a session file'),
                  onPressed: busy || loading ? null : upload,
                  icon: const Icon(Icons.upload_file_outlined),
                ),
              const Spacer(),
              IconButton(
                tooltip: text('تازه‌سازی', 'Refresh'),
                onPressed: busy || loading ? null : load,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          if (busy || loading) const LinearProgressIndicator(),
          if (error != null)
            Text(
              text(
                denied
                    ? 'دسترسی به فایل‌های این جلسه ندارید.'
                    : 'دریافت فایل‌ها انجام نشد. دوباره تلاش کنید.',
                denied
                    ? 'You cannot access this session’s files.'
                    : 'Could not load files. Please retry.',
              ),
            ),
          if (!loading && error == null && files.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                text(
                  'هنوز فایلی برای این جلسه ثبت نشده است.',
                  'No files have been uploaded for this session.',
                ),
              ),
            ),
          for (final file in files)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(fileIcon('${file['mime'] ?? ''}')),
              title: Text(
                '${file['name'] ?? ''}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                '${panelNumber(file['size'], fa: fa)} ${text('بایت', 'bytes')} · ${panelDate(file['createdAt'], fa: fa)}',
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (data['canDownload'] == true)
                    IconButton(
                      key: ValueKey('session-file-download-${file['id']}'),
                      tooltip: text('دانلود فایل', 'Download file'),
                      onPressed: busy || loading ? null : () => download(file),
                      icon: const Icon(Icons.download_outlined),
                    ),
                  if (file['canDelete'] == true)
                    IconButton(
                      tooltip: text('حذف فایل', 'Delete file'),
                      onPressed: busy || loading ? null : () => remove(file),
                      icon: const Icon(Icons.delete_outline),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
