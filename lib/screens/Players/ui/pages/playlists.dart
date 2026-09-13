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
Future<String?> createMusicPlaylist(BuildContext context) async {
  var draft = '';
  final name = await showDialog<String>(
    context: context,
    builder: (c) => AlertDialog(
      title: Text(socialText(c, 'پلی‌لیست جدید', 'New playlist')),
      content: TextField(
        onChanged: (value) => draft = value,
        autofocus: true,
        maxLength: 80,
        decoration: InputDecoration(
          hintText: socialText(c, 'نام پلی‌لیست', 'Playlist name'),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(c),
          child: Text(socialText(c, 'انصراف', 'Cancel')),
        ),
        TextButton(
          onPressed: () => Navigator.pop(c, draft.trim()),
          child: Text(socialText(c, 'ایجاد', 'Create')),
        ),
      ],
    ),
  );

  return name == null ? null : MusicPlaylists.instance.create(name);
}

Future<void> chooseMusicPlaylist(
  BuildContext context,
  List<AudioFile> files,
) async {
  final store = MusicPlaylists.instance;
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
            title: Text(socialText(c, 'پلی‌لیست جدید', 'New playlist')),
            onTap: () => Navigator.pop(c, '__new__'),
          ),
          for (final name in store.lists.keys)
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
    key = await createMusicPlaylist(context);
  if (key != null) {
    await store.add(key, files.map((f) => f.file.path));
  }
}

class PlaylistsTab extends StatefulWidget {
  const PlaylistsTab({super.key});
  @override
  State<PlaylistsTab> createState() => _PlaylistsTabState();
}

class _PlaylistsTabState extends State<PlaylistsTab> {
  final store = MusicPlaylists.instance;
  String? selected;
  @override
  void initState() {
    super.initState();
    store.load();
  }

  Future<void> addFiles(AudioPlayerProvider provider) async {
    final chosen = <String>{};
    final existing = store.lists[selected] ?? [];
    final result = await showDialog<bool>(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (c, update) => AlertDialog(
          title: Text(socialText(c, 'افزودن فایل‌ها', 'Add audio files')),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView(
              shrinkWrap: true,
              children: [
                for (final file in provider.allFiles)
                  CheckboxListTile(
                    value:
                        existing.contains(file.file.path) ||
                        chosen.contains(file.file.path),
                    title: Text(
                      file.fileName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onChanged: existing.contains(file.file.path)
                        ? null
                        : (v) => update(
                            () => v == true
                                ? chosen.add(file.file.path)
                                : chosen.remove(file.file.path),
                          ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: Text(socialText(c, 'انصراف', 'Cancel')),
            ),
            TextButton(
              onPressed: () => Navigator.pop(c, true),
              child: Text(socialText(c, 'افزودن', 'Add')),
            ),
          ],
        ),
      ),
    );
    if (result == true && selected != null) await store.add(selected!, chosen);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AudioPlayerProvider>();
    return AnimatedBuilder(
      animation: store,
      builder: (c, _) {
        final entries = store.lists;
        final paths = entries[selected] ?? [];
        final byPath = {
          for (final file in provider.allFiles) file.file.path: file,
        };
        final files = [
          for (final p in paths)
            if (byPath[p] != null) byPath[p]!,
        ];
        return Column(
          children: [
            Row(
              children: [
                if (selected != null)
                  IconButton(
                    onPressed: () => setState(() => selected = null),
                    icon: const Icon(Icons.arrow_back),
                  ),
                Expanded(
                  child: Text(
                    selected == null
                        ? socialText(c, 'پلی‌لیست‌ها', 'Playlists')
                        : playlistLabel(c, selected!),
                    style: Theme.of(c).textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  tooltip: socialText(c, 'افزودن', 'Add'),
                  icon: Icon(selected == null ? Icons.playlist_add : Icons.add),
                  onPressed: () async {
                    if (selected == null) {
                      final key = await createMusicPlaylist(c);
                      if (key != null && mounted)
                        setState(() => selected = key);
                    } else {
                      await addFiles(provider);
                    }
                  },
                ),
              ],
            ),
            Expanded(
              child: ListView(
                children: selected == null
                    ? [
                        for (final e in entries.entries)
                          ListTile(
                            leading: Icon(
                              e.key == MusicPlaylists.favorite
                                  ? Icons.favorite_border
                                  : Icons.queue_music,
                            ),
                            title: Text(playlistLabel(c, e.key)),
                            subtitle: Text(e.value.length.toString()),
                            onTap: () => setState(() => selected = e.key),
                          ),
                      ]
                    : [
                        if (paths.isEmpty)
                          Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              socialText(
                                c,
                                'با دکمه + فایل اضافه کنید.',
                                'Use + to add audio files.',
                              ),
                            ),
                          ),
                        for (final p in paths)
                          ListTile(
                            selected: provider.currentAudio?.file.path == p,
                            leading: IconButton(
                              icon: Icon(
                                provider.currentAudio?.file.path == p &&
                                        provider.isPlaying
                                    ? Icons.pause
                                    : Icons.play_arrow,
                              ),
                              onPressed: byPath[p] == null
                                  ? null
                                  : () async {
                                      if (provider.currentAudio?.file.path ==
                                          p) {
                                        if (provider.isPlaying) {
                                          await provider.pause();
                                        } else {
                                          await provider.resume();
                                        }
                                      } else {
                                        await provider.playFromFolder(
                                          files,
                                          files.indexOf(byPath[p]!),
                                        );
                                      }
                                    },
                            ),
                            title: Text(
                              byPath[p]?.fileName ??
                                  p.split(RegExp(r'[/\\]')).last,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: byPath[p] == null
                                ? Text(
                                    socialText(
                                      c,
                                      'فایل در دسترس نیست',
                                      'File unavailable',
                                    ),
                                  )
                                : null,
                            trailing: IconButton(
                              icon: const Icon(Icons.remove_circle_outline),
                              onPressed: () => store.remove(selected!, p),
                            ),
                          ),
                      ],
              ),
            ),
          ],
        );
      },
    );
  }
}
