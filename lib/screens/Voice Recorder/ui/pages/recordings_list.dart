import 'package:sornaz/components/expanding_search_bar.dart';
import 'recorder_settings.dart';
import 'recording_playback.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sornaz/helpers/app_functions.dart';
import 'package:sornaz/screens/Social/social_widgets.dart';
import '../../provider/voice_recorder_provider.dart';
import '../../services/file_service.dart';

class RecordedFilesPage extends StatefulWidget {
  const RecordedFilesPage({super.key});
  @override
  State<RecordedFilesPage> createState() => _RecordedFilesPageState();
}

class _RecordedFilesPageState extends State<RecordedFilesPage> {
  String query = '';
  final selected = <String>{};
  final favorites = <String>{};
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted)
        _run(() => context.read<VoiceRecorderProvider>().refreshFiles());
    });
    SharedPreferences.getInstance().then((prefs) {
      if (mounted)
        setState(
          () => favorites.addAll(
            prefs.getStringList('recording.favorites') ?? [],
          ),
        );
    });
  }

  Future<void> _run(Future<void> Function() action) async {
    try {
      await action();
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              socialText(
                context,
                'عملیات انجام نشد؛ دسترسی فایل یا فضای خالی گوشی را بررسی کنید.',
                'Could not complete the action. Check file access and available storage.',
              ),
            ),
          ),
        );
    }
  }

  Future<void> _delete(List<SavedRecording> files) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          socialText(context, 'حذف فایل ضبط‌شده؟', 'Delete recording?'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(socialText(context, 'انصراف', 'Cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(socialText(context, 'حذف', 'Delete')),
          ),
        ],
      ),
    );
    if (yes != true || !mounted) return;
    final vm = context.read<VoiceRecorderProvider>();
    await _run(() async {
      await vm.playbackService.stop();
      for (final file in files) {
        await vm.fileService.delete(file);
      }
      await vm.refreshFiles();
      if (mounted) setState(selected.clear);
    });
  }

  Future<void> _rename(SavedRecording file) async {
    final field = TextEditingController(
      text: file.name.replaceFirst(RegExp(r'\.m4a$'), ''),
    );
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(socialText(context, 'تغییر نام', 'Rename')),
        content: TextField(controller: field, autofocus: true, maxLength: 100),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(socialText(context, 'انصراف', 'Cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, field.text.trim()),
            child: Text(socialText(context, 'ذخیره', 'Save')),
          ),
        ],
      ),
    );
    field.dispose();
    if (name == null || name.isEmpty || !mounted) return;
    final vm = context.read<VoiceRecorderProvider>();
    await _run(() async {
      await vm.playbackService.stop();
      await vm.fileService.rename(file, name);
      await vm.refreshFiles();
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<VoiceRecorderProvider>();
    final files = vm.files
        .where((f) => f.name.toLowerCase().contains(query))
        .toList();
    final player = vm.playbackService;
    return Scaffold(
      appBar: ExpandingSearchBar(
        title: Row(
          children: [
            const BackButton(),
            Expanded(
              child: Text(
                socialText(context, 'صداهای ضبط‌شده', 'Recordings'),
                style: const TextStyle(fontSize: 13),
              ),
            ),
          ],
        ),
        onChanged: (value) => setState(() => query = value.toLowerCase()),
        onSettings: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const RecorderSettingsPage()),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              onRefresh: vm.refreshFiles,
              child: files.isEmpty
                  ? ListView(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(32),
                          child: Text(
                            socialText(
                              context,
                              'فایل ضبط‌شده‌ای وجود ندارد.',
                              'No recordings yet.',
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: files.length,
                      itemBuilder: (context, index) {
                        final file = files[index];
                        final active = player.currentPath == file.uri;
                        return Card(
                          margin: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            side: BorderSide(
                              width: .4,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: .12),
                            ),
                          ),
                          child: Column(
                            children: [
                              ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                selected: selected.contains(file.uri),
                                onLongPress: () =>
                                    setState(() => selected.add(file.uri)),
                                onTap: () {
                                  if (selected.isNotEmpty) {
                                    setState(
                                      () => selected.contains(file.uri)
                                          ? selected.remove(file.uri)
                                          : selected.add(file.uri),
                                    );
                                  } else {
                                    _run(() => vm.playSaved(file));
                                  }
                                },
                                leading: IconButton(
                                  icon: Icon(
                                    active && player.isPlaying
                                        ? Icons.pause
                                        : Icons.play_arrow,
                                  ),
                                  onPressed: () =>
                                      _run(() => vm.playSaved(file)),
                                ),
                                title: Text(file.name),
                                subtitle: Text(
                                  file.isPublic
                                      ? formatJalali(file.modified)
                                      : socialText(
                                          context,
                                          'ذخیره در گوشی در انتظار تلاش مجدد',
                                          'Pending save to phone',
                                        ),
                                ),
                                trailing: PopupMenuButton<String>(
                                  onSelected: (action) async {
                                    if (action == 'wave')
                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              RecordingPlaybackPage(file: file),
                                        ),
                                      );
                                    if (action == 'delete')
                                      await _delete([file]);
                                    if (action == 'rename') await _rename(file);
                                    if (action == 'share')
                                      await _run(
                                        () => vm.fileService.share(file),
                                      );
                                    if (action == 'favorite') {
                                      setState(
                                        () => favorites.contains(file.uri)
                                            ? favorites.remove(file.uri)
                                            : favorites.add(file.uri),
                                      );
                                      final prefs =
                                          await SharedPreferences.getInstance();
                                      await prefs.setStringList(
                                        'recording.favorites',
                                        favorites.toList(),
                                      );
                                    }
                                  },
                                  itemBuilder: (_) => [
                                    const PopupMenuItem(
                                      value: 'wave',
                                      child: Text('پخش با نمایش موج صدا'),
                                    ),
                                    PopupMenuItem(
                                      value: 'rename',
                                      child: Text(
                                        socialText(
                                          context,
                                          'تغییر نام',
                                          'Rename',
                                        ),
                                      ),
                                    ),
                                    if (file.isPublic)
                                      PopupMenuItem(
                                        value: 'share',
                                        child: Text(
                                          socialText(
                                            context,
                                            'اشتراک‌گذاری',
                                            'Share',
                                          ),
                                        ),
                                      ),
                                    PopupMenuItem(
                                      value: 'favorite',
                                      child: Row(
                                        children: [
                                          Icon(
                                            favorites.contains(file.uri)
                                                ? Icons.favorite
                                                : Icons.favorite_border,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            socialText(
                                              context,
                                              'علاقه‌مندی',
                                              'Favorite',
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: 'delete',
                                      child: Text(
                                        socialText(context, 'حذف', 'Delete'),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (active)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  child: Row(
                                    children: [
                                      Text(
                                        formatSeconds(
                                          player.position.inSeconds,
                                        ),
                                      ),
                                      Expanded(
                                        child: Slider(
                                          value: player.position.inMilliseconds
                                              .toDouble()
                                              .clamp(
                                                0,
                                                player.duration.inMilliseconds
                                                    .toDouble(),
                                              ),
                                          max:
                                              player.duration.inMilliseconds > 0
                                              ? player.duration.inMilliseconds
                                                    .toDouble()
                                              : 1,
                                          onChanged:
                                              player.duration.inMilliseconds > 0
                                              ? (value) => player.seek(
                                                  Duration(
                                                    milliseconds: value.round(),
                                                  ),
                                                )
                                              : null,
                                        ),
                                      ),
                                      Text(
                                        formatSeconds(
                                          player.duration.inSeconds,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: selected.isEmpty
          ? null
          : SafeArea(
              child: Row(
                children: [
                  TextButton(
                    onPressed: () => setState(selected.clear),
                    child: Text(socialText(context, 'انصراف', 'Cancel')),
                  ),
                  Text('${selected.length}'),
                  const Spacer(),
                  IconButton(
                    onPressed: () => _delete(
                      vm.files.where((f) => selected.contains(f.uri)).toList(),
                    ),
                    icon: const Icon(Icons.delete),
                  ),
                ],
              ),
            ),
    );
  }
}
