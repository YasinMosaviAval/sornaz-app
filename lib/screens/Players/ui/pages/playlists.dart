import '../components/player_dialog.dart';
import '../components/audio_item.dart';
import '../components/audio_selection.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sornaz/screens/Social/social_widgets.dart';
import '../../services/music_playlists.dart';
import '../../providers/audio_player_provider.dart';
import '../../scan/audio_file.dart';

String playlistLabel(BuildContext c, String key) =>
    key == MusicPlaylists.favorite
    ? socialText(c, 'علاقه‌مندی', 'Favorite')
    : key;
Future<String?> createMusicPlaylist(
  BuildContext context, {
  MusicPlaylists? collection,
}) async {
  var draft = '';
  final name = await showDialog<String>(
    context: context,
    builder: (c) => PlayerDialog(
      title: Text(socialText(c, 'لیست پخش جدید', 'New playlist')),
      content: TextField(
        style: Theme.of(c).textTheme.bodyMedium,
        onChanged: (value) => draft = value,
        autofocus: true,
        maxLength: 80,
        decoration: InputDecoration(
          hintText: socialText(c, 'نام لیست پخش', 'Playlist name'),
        ),
      ),
      actions: [
        PlayerDialogButton(
          primary: false,
          onPressed: () => Navigator.pop(c),
          child: Text(socialText(c, 'انصراف', 'Cancel')),
        ),
        PlayerDialogButton(
          onPressed: () => Navigator.pop(c, draft.trim()),
          child: Text(socialText(c, 'ایجاد', 'Create')),
        ),
      ],
    ),
  );

  return name == null
      ? null
      : (collection ?? MusicPlaylists.instance).create(name);
}

Future<void> chooseMusicPlaylist(
  BuildContext context,
  List<AudioFile> files,
) async {
  await chooseAudioPlaylist(
    context,
    files.map((f) => f.file.path),
    MusicPlaylists.instance,
  );
}

Future<void> chooseAudioPlaylist(
  BuildContext context,
  Iterable<String> paths,
  MusicPlaylists store, {
  String? excludeKey,
}) async {
  await store.load();
  if (!context.mounted) return;
  var key = await showModalBottomSheet<String>(
    context: context,
    builder: (c) => SafeArea(
      child: ListView(
        shrinkWrap: true,
        children: [
          ListTile(
            leading: const Icon(Icons.playlist_add),
            title: Text(socialText(c, 'لیست پخش جدید', 'New playlist')),
            onTap: () => Navigator.pop(c, '__new__'),
          ),
          for (final name in store.lists.keys)
            if (name != excludeKey)
              ListTile(
                leading: Icon(
                  name == MusicPlaylists.favorite
                      ? Icons.favorite_border
                      : Icons.queue_music,
                ),
                title: Text(playlistLabel(c, name)),
                onTap: () => Navigator.pop(c, name),
              ),
        ],
      ),
    ),
  );
  if (key == '__new__' && context.mounted)
    key = await createMusicPlaylist(context, collection: store);
  if (key != null && key != excludeKey) {
    await store.add(key, paths);
  }
}

class PlaylistsTab extends StatefulWidget {
  const PlaylistsTab({super.key});
  @override
  State<PlaylistsTab> createState() => _PlaylistsTabState();
}

class _PlaylistsTabState extends State<PlaylistsTab> {
  final store = MusicPlaylists.instance;
  final expanded = <String>{};
  final selected = <String>{};
  final scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    store.load();
  }

  @override
  void dispose() {
    scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    context.select<AudioPlayerProvider, (int, String, String?)>(
      (p) => (p.libraryRevision, p.searchQuery, p.currentAudio?.file.path),
    );
    final player = context.read<AudioPlayerProvider>();
    return AnimatedBuilder(
      animation: store,
      builder: (c, _) {
        final byPath = {
          for (final file in player.allFiles)
            if (!player.settings.isHidden(file.file.path)) file.file.path: file,
        };
        final lists = [
          for (final e in store.lists.entries)
            MapEntry(e.key, [
              for (final p in e.value)
                if (byPath[p] != null) byPath[p]!,
            ]),
        ];
        final rows = <(String, AudioFile?)>[];
        for (final entry in lists) {
          rows.add((entry.key, null));
          if (expanded.contains(entry.key)) {
            for (final file in entry.value) {
              if (file.fileName.toLowerCase().contains(player.searchQuery)) {
                rows.add((entry.key, file));
              }
            }
          }
        }
        final queues = {for (final entry in lists) entry.key: entry.value};
        final selectedFiles = [
          for (final file in byPath.values)
            if (selected.contains(file.file.path)) file,
        ];
        return Column(
          children: [
            if (selected.isNotEmpty)
              Row(
                children: [
                  IconButton(
                    onPressed: () => setState(selected.clear),
                    icon: const Icon(Icons.close),
                  ),
                  Text('${selected.length}'),
                  const Spacer(),
                  IconButton(
                    onPressed: () => setState(
                      () => selected.addAll([
                        for (final row in rows)
                          if (row.$2 != null) row.$2!.file.path,
                      ]),
                    ),
                    icon: const Icon(Icons.select_all),
                  ),
                  AudioActionsMenu(
                    files: selectedFiles,
                    after: () {
                      if (mounted) setState(selected.clear);
                    },
                  ),
                ],
              ),
            Expanded(
              child: ListView.builder(
                controller: scroll,
                padding: EdgeInsets.zero,
                itemExtent: 64,
                itemCount: rows.length,
                itemBuilder: (c, index) {
                  final (key, audio) = rows[index];
                  final queue = queues[key]!;
                  if (audio == null) {
                    final isExpanded = expanded.contains(key);
                    return AudioRow(
                      title: playlistLabel(c, key),
                      location: '',
                      duration: Duration.zero,
                      count: queue.length,
                      leadingIcon: key == MusicPlaylists.favorite
                          ? (isExpanded
                                ? Icons.favorite
                                : Icons.favorite_border)
                          : (isExpanded
                                ? Icons.queue_music
                                : Icons.queue_music_outlined),
                      isPlaying: isExpanded,
                      onTap: () => setState(() {
                        if (!expanded.remove(key)) expanded.add(key);
                      }),
                      trailing: selected.isNotEmpty
                          ? const SizedBox.shrink()
                          : key == MusicPlaylists.favorite
                          ? Icon(
                              isExpanded
                                  ? Icons.expand_less
                                  : Icons.expand_more,
                            )
                          : PopupMenuButton<String>(
                              onSelected: (action) async {
                                final renamed = await editAudioCollection(
                                  c,
                                  store,
                                  key,
                                  delete: action == 'delete',
                                );
                                if (mounted &&
                                    renamed != null &&
                                    expanded.remove(key)) {
                                  setState(() => expanded.add(renamed));
                                }
                              },
                              itemBuilder: (_) => [
                                PopupMenuItem(
                                  value: 'rename',
                                  child: Text(
                                    socialText(c, 'تغییر نام', 'Rename'),
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Text(socialText(c, 'حذف', 'Delete')),
                                ),
                              ],
                            ),
                    );
                  }
                  return AudioItem(
                    key: ValueKey('$key:${audio.file.path}'),
                    audio: audio,
                    index: queue.indexOf(audio),
                    isPlaying:
                        player.currentAudio?.file.path == audio.file.path,
                    selected: selected.contains(audio.file.path),
                    showActions: selected.isEmpty,
                    onLongPress: () =>
                        setState(() => selected.add(audio.file.path)),
                    onTap: () {
                      if (selected.isNotEmpty) {
                        setState(() {
                          if (!selected.remove(audio.file.path))
                            selected.add(audio.file.path);
                        });
                      } else if (player.currentAudio?.file.path ==
                              audio.file.path &&
                          player.isActiveCollection(queue, key)) {
                        player.isPlaying ? player.pause() : player.resume();
                      } else {
                        player.playFromFolder(
                          queue,
                          queue.indexOf(audio),
                          listKey: key,
                          lists: lists,
                        );
                      }
                    },
                    trailing: PopupMenuButton<String>(
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.more_vert),
                      onSelected: (action) {
                        if (action == 'remove') {
                          store.remove(key, audio.file.path);
                        } else if (action == 'playlist') {
                          chooseAudioPlaylist(
                            c,
                            [audio.file.path],
                            store,
                            excludeKey: key,
                          );
                        } else {
                          audioAction(c, [audio], action);
                        }
                      },
                      itemBuilder: (_) => [
                        for (final action in [
                          ('crop', socialText(c, 'برش صدا', 'Trim audio')),
                          (
                            'playlist',
                            socialText(
                              c,
                              'افزودن به لیست پخش',
                              'Add to playlist',
                            ),
                          ),
                          ('rename', socialText(c, 'تغییر نام', 'Rename')),
                          ('move', socialText(c, 'انتقال', 'Move')),
                          ('share', socialText(c, 'اشتراک‌گذاری', 'Share')),
                          ('delete', socialText(c, 'حذف فایل', 'Delete file')),
                          (
                            'remove',
                            socialText(
                              c,
                              'حذف از لیست پخش',
                              'Remove from playlist',
                            ),
                          ),
                        ])
                          PopupMenuItem(
                            value: action.$1,
                            child: Text(action.$2),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

Future<String?> editAudioCollection(
  BuildContext context,
  MusicPlaylists store,
  String key, {
  bool delete = false,
}) async {
  var name = key;
  final accepted = await showDialog<bool>(
    context: context,
    builder: (c) => PlayerDialog(
      title: Text(delete ? 'حذف «${playlistLabel(c, key)}»؟' : 'تغییر نام'),
      content: delete
          ? const Text('فایل‌های صوتی از دستگاه حذف نمی‌شوند.')
          : TextFormField(
              initialValue: key,
              autofocus: true,
              maxLength: 80,
              onChanged: (value) => name = value.trim(),
            ),
      actions: [
        PlayerDialogButton(
          primary: false,
          onPressed: () => Navigator.pop(c, false),
          child: const Text('انصراف'),
        ),
        PlayerDialogButton(
          onPressed: () => Navigator.pop(c, true),
          child: Text(delete ? 'حذف' : 'ذخیره'),
        ),
      ],
    ),
  );
  if (accepted != true) return null;
  if (delete) {
    await store.delete(key);
    return null;
  }
  if (await store.rename(key, name)) return name;
  if (context.mounted)
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('نام خالی یا تکراری قابل استفاده نیست.')),
    );
  return null;
}
