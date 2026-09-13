import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../services/music_playlists.dart';
import '../pages/playlists.dart';
import '../../providers/audio_player_provider.dart';
import '../../scan/audio_file.dart';

Future<void> audioAction(
  BuildContext context,
  List<AudioFile> files,
  String action,
) async {
  if (files.isEmpty) return;
  final provider = context.read<AudioPlayerProvider>();
  try {
    if (action == 'rename') {
      for (final file in files) {
        if (!context.mounted) break;
        final dot = file.fileName.lastIndexOf('.');
        final input = TextEditingController(
          text: dot < 0 ? file.fileName : file.fileName.substring(0, dot),
        );
        final name = await showDialog<String>(
          context: context,
          builder: (c) => AlertDialog(
            title: const Text('تغییر نام'),
            content: TextField(controller: input, maxLength: 100),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(c),
                child: const Text('انصراف'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(c, input.text.trim()),
                child: const Text('ذخیره'),
              ),
            ],
          ),
        );
        input.dispose();
        if (name != null && name.isNotEmpty)
          await provider.renameFile(
            file,
            '$name${dot < 0 ? '' : file.fileName.substring(dot)}',
            'نام فایل تغییر کرد',
          );
      }
    }
    if (action == 'share')
      await Share.shareXFiles(files.map((f) => XFile(f.file.path)).toList());
    if (action == 'favorite') await MusicPlaylists.instance.add(MusicPlaylists.favorite, files.map((f)=>f.file.path));
    if (action == 'playlist' && context.mounted) await chooseMusicPlaylist(context, files);
    if (action == 'delete' && context.mounted) {
      final yes = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: Text('حذف ${files.length} فایل؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('انصراف'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(c, true),
              child: const Text('حذف'),
            ),
          ],
        ),
      );
      if (yes == true) {
        if (files.contains(provider.currentAudio)) await provider.stop();
        for (final file in files) {
          await provider.deleteFromDevice(file, 'فایل حذف شد');
        }
      }
    }
  } catch (_) {
    if (context.mounted)
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('عملیات فایل انجام نشد. دسترسی به فایل را بررسی کنید.'),
        ),
      );
  }
}

class AudioActionsMenu extends StatelessWidget {
  const AudioActionsMenu({super.key, required this.files, this.after});
  final List<AudioFile> files;
  final VoidCallback? after;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 32,
    height: 32,
    child: PopupMenuButton<String>(
      padding: EdgeInsets.zero,
      child: const SizedBox(
        width: 32,
        height: 32,
        child: Center(child: Icon(Icons.more_vert, size: 24)),
      ),
      onSelected: (action) async {
        await audioAction(context, files, action);
        after?.call();
      },
      itemBuilder: (_) => [
        for (final action in [
          ('rename', 'تغییر نام'),
          ('favorite', 'افزودن به علاقه‌مندی‌ها'),
          ('playlist', 'افزودن به پلی‌لیست'),
          ('share', 'اشتراک‌گذاری'),
          ('delete', 'حذف'),
        ])
          PopupMenuItem(value: action.$1, child: Text(action.$2)),
      ],
    ),
  );
}
