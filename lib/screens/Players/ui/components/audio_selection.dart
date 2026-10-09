import 'player_dialog.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:sornaz/screens/Social/social_widgets.dart';
import 'package:sornaz/components/audio_crop_page.dart';
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
    if (action == 'hide')
      await provider.settings.setOption('hiddenPaths', [
        ...provider.settings.hiddenPaths,
        ...files.map((f) => f.file.path),
      ]);
    if (action == 'ringtone')
      await const MethodChannel(
        'sornaz/music_tools',
      ).invokeMethod('ringtone', {'path': files.single.file.path});
    if (action == 'crop' && files.length == 1) {
      final file = files.single;
      await provider.pause();
      if (!context.mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AudioCropPage(
            source: file.file.path,
            name: file.fileName,
            onSave: (staged, replace, start, end) async {
              if (replace && provider.currentAudio == file)
                await provider.stop();
              final path = await commitAudioCrop(
                staged,
                file.file.path,
                replace,
              );
              await provider.registerCroppedAudio(
                file,
                path,
                end - start,
                replace,
              );
            },
          ),
        ),
      );
    }
    if (action == 'rename') {
      for (final file in files) {
        if (!context.mounted) break;
        final dot = file.fileName.lastIndexOf('.');
        final input = TextEditingController(
          text: dot < 0 ? file.fileName : file.fileName.substring(0, dot),
        );
        final name = await showDialog<String>(
          context: context,
          builder: (c) => PlayerDialog(
            title: const Text('تغییر نام'),
            content: TextField(
              style: const TextStyle(fontSize: 14),
              controller: input,
              maxLength: 100,
            ),
            actions: [
              PlayerDialogButton(
                primary: false,
                onPressed: () => Navigator.pop(c),
                child: const Text('انصراف'),
              ),
              PlayerDialogButton(
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
    if (action == 'favorite')
      await MusicPlaylists.instance.add(
        MusicPlaylists.favorite,
        files.map((f) => f.file.path),
      );
    if (action == 'playlist' && context.mounted)
      await chooseMusicPlaylist(context, files);
    if (action == 'delete' && context.mounted) {
      final yes = await showDialog<bool>(
        context: context,
        builder: (c) => PlayerDialog(
          title: Text('حذف ${files.length} فایل؟'),
          actions: [
            PlayerDialogButton(
              primary: false,
              onPressed: () => Navigator.pop(c, false),
              child: const Text('انصراف'),
            ),
            PlayerDialogButton(
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
  } on PlatformException catch (e) {
    if (context.mounted)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.code == 'PERMISSION'
                ? socialText(
                    context,
                    'اجازه تغییر تنظیمات سیستم را بدهید و دوباره «قرار دادن به عنوان زنگ گوشی» را انتخاب کنید.',
                    'Allow modifying system settings, then choose Set as Ringtone again.',
                  )
                : socialText(
                    context,
                    'تنظیم زنگ گوشی انجام نشد.',
                    'Could not set the ringtone.',
                  ),
          ),
        ),
      );
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
          ('hide', socialText(context, 'مخفی کردن', 'Hide')),
          if (files.length == 1 &&
              defaultTargetPlatform == TargetPlatform.android)
            (
              'ringtone',
              socialText(
                context,
                'قرار دادن به عنوان زنگ گوشی',
                'Set as Ringtone',
              ),
            ),
          if (files.length == 1) ('rename', 'تغییر نام'),
          if (files.length == 1) ('crop', 'برش صدا'),
          ('playlist', 'افزودن به لیست پخش'),
          ('share', 'اشتراک‌گذاری'),
          ('delete', 'حذف'),
        ])
          PopupMenuItem(value: action.$1, child: Text(action.$2)),
      ],
    ),
  );
}
