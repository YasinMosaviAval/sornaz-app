import '../components/player_dialog.dart';
import '../components/audio_item.dart';
import '../components/file_actions.dart';
import 'package:sornaz/helpers/app_data.dart';
import 'package:sornaz/helpers/app_colors.dart';
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
    builder: (c) => PlayerDialog(
      title: Text(socialText(c, 'پلی‌لیست جدید', 'New playlist')),
      content: TextField(
        style: const TextStyle(fontSize: 14),
        onChanged: (value) => draft = value,
        autofocus: true,
        maxLength: 80,
        decoration: InputDecoration(
          hintText: socialText(c, 'نام پلی‌لیست', 'Playlist name'),
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
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
                  if (selected == null)
                    IconButton(
                      tooltip: socialText(c, 'افزودن', 'Add'),
                      icon: Icon(
                        selected == null ? Icons.playlist_add : Icons.add,
                      ),
                      onPressed: () async {
                        if (selected == null) {
                          final key = await createMusicPlaylist(c);
                          if (key != null && mounted)
                            setState(() => selected = key);
                        }
                      },
                    ),
                ],
              ),
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
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            tileColor:
                                AppColors.music_player_audio_item_not_playing_background_color(
                                  isDark: context.watch<AppData>().isDark,
                                ),
                            shape: Border(
                              bottom: BorderSide(
                                width: .2,
                                color: Theme.of(
                                  c,
                                ).colorScheme.onSurface.withValues(alpha: .04),
                              ),
                            ),
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
                                'از صفحه آهنگ‌ها یا پوشه‌ها فایل اضافه کنید.',
                                'Add audio files from Songs or Folders.',
                              ),
                            ),
                          ),
                        for (final p in paths)
                          if (byPath[p] case final audio?)
                            AudioItem(
                              audio: audio,
                              isPlaying:
                                  provider.currentAudio?.file.path == p &&
                                  provider.isPlaying,
                              index: files.indexOf(audio),
                              onTap: () async {
                                if (provider.currentAudio?.file.path == p) {
                                  if (provider.isPlaying) {
                                    await provider.pause();
                                  } else {
                                    await provider.resume();
                                  }
                                } else {
                                  await provider.playFromFolder(
                                    files,
                                    files.indexOf(audio),
                                  );
                                }
                              },
                              trailing: PopupMenuButton<String>(
                                padding: EdgeInsets.zero,
                                icon: const Icon(Icons.more_vert, size: 24),
                                onSelected: (value) async {
                                  if (value == 'remove') {
                                    await store.remove(selected!, p);
                                  } else if (c.mounted) {
                                    showFileOptions(c, audio);
                                  }
                                },
                                itemBuilder: (c) => [
                                  PopupMenuItem(
                                    value: 'options',
                                    child: Text(
                                      socialText(
                                        c,
                                        'گزینه‌های فایل',
                                        'File options',
                                      ),
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: 'remove',
                                    child: Text(
                                      socialText(
                                        c,
                                        'حذف از پلی‌لیست',
                                        'Remove from playlist',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            ListTile(
                              leading: const Icon(Icons.audio_file_outlined),
                              title: Text(
                                p.split(RegExp(r'[/\\]')).last,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                socialText(
                                  c,
                                  'فایل در دسترس نیست',
                                  'File unavailable',
                                ),
                              ),
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
