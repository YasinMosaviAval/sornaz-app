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
        style: const TextStyle(fontSize: 14),
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
  @override
  void initState() {
    super.initState();
    store.load();
  }

  @override
  Widget build(BuildContext context) {
    final player = context.watch<AudioPlayerProvider>();
    return AnimatedBuilder(
      animation: store,
      builder: (c, _) {
        final byPath = {
          for (final file in player.allFiles) file.file.path: file,
        };
        final lists = [
          for (final e in store.lists.entries)
            MapEntry(e.key, [
              for (final p in e.value)
                if (byPath[p] != null) byPath[p]!,
            ]),
        ];
        return ListView(
          padding: EdgeInsets.zero,
          children: [
            for (final entry in lists) ...[
              SizedBox(
                height: 64,
                child: AudioRow(
                  title: playlistLabel(c, entry.key),
                  location: '',
                  duration: Duration.zero,
                  count: entry.value.length,
                  leadingIcon: entry.key == MusicPlaylists.favorite
                      ? Icons.favorite_border
                      : Icons.queue_music,
                  isPlaying: false,
                  onTap: () => setState(() {
                    if (!expanded.remove(entry.key)) expanded.add(entry.key);
                  }),
                  trailing: entry.key == MusicPlaylists.favorite
                      ? Icon(
                          expanded.contains(entry.key)
                              ? Icons.expand_less
                              : Icons.expand_more,
                        )
                      : PopupMenuButton<String>(
                          padding: EdgeInsets.zero,
                          icon: const Icon(Icons.more_vert, size: 24),
                          onSelected: (action) async {
                            final renamed = await editAudioCollection(
                              c,
                              store,
                              entry.key,
                              delete: action == 'delete',
                            );
                            if (mounted &&
                                renamed != null &&
                                expanded.remove(entry.key))
                              setState(() => expanded.add(renamed));
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(
                              value: 'rename',
                              child: Text('تغییر نام'),
                            ),
                            PopupMenuItem(value: 'delete', child: Text('حذف')),
                          ],
                        ),
                ),
              ),
              if (expanded.contains(entry.key))
                for (final audio in entry.value.where(
                  (f) => f.fileName.toLowerCase().contains(player.searchQuery),
                ))
                  SizedBox(
                    height: 64,
                    child: AudioItem(
                      audio: audio,
                      index: entry.value.indexOf(audio),
                      isPlaying:
                          player.currentAudio?.file.path == audio.file.path,
                      onTap: () {
                        if (player.currentAudio?.file.path == audio.file.path) {
                          player.isPlaying ? player.pause() : player.resume();
                        } else {
                          player.playFromFolder(
                            entry.value,
                            entry.value.indexOf(audio),
                            listKey: entry.key,
                            lists: lists,
                          );
                        }
                      },
                      trailing: PopupMenuButton<String>(
                        padding: EdgeInsets.zero,
                        icon: const Icon(Icons.more_vert, size: 24),
                        onSelected: (action) {
                          if (action == 'remove') {
                            store.remove(entry.key, audio.file.path);
                          } else if (action == 'playlist') {
                            chooseAudioPlaylist(
                              c,
                              [audio.file.path],
                              store,
                              excludeKey: entry.key,
                            );
                          } else {
                            audioAction(c, [audio], action);
                          }
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(value: 'crop', child: Text('برش صدا')),
                          PopupMenuItem(
                            value: 'playlist',
                            child: Text('افزودن به لیست پخش'),
                          ),
                          PopupMenuItem(
                            value: 'rename',
                            child: Text('تغییر نام'),
                          ),
                          PopupMenuItem(
                            value: 'share',
                            child: Text('اشتراک‌گذاری'),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Text('حذف فایل'),
                          ),
                          PopupMenuItem(
                            value: 'remove',
                            child: Text('حذف از لیست پخش'),
                          ),
                        ],
                      ),
                    ),
                  ),
            ],
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
