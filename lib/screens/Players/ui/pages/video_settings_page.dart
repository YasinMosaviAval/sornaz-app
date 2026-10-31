import 'package:sornaz/components/settings_switch_tile.dart';
import '../components/player_sort_tile.dart';
import 'package:sornaz/helpers/app_platform.dart';
import 'package:sornaz/helpers/desktop_library_folders.dart';
import 'package:sornaz/helpers/ios_audio_import.dart';
import 'package:flutter/material.dart';
import 'package:sornaz/components/app_bar.dart';
import 'package:sornaz/helpers/app_appearance.dart';
import 'package:sornaz/screens/Social/social_widgets.dart';

import '../../services/player_settings.dart';
import 'music_library_settings.dart';
import '../components/search_bar.dart' show endLabel;

class VideoSettingsPage extends StatefulWidget {
  const VideoSettingsPage({
    super.key,
    required this.videoNames,
    required this.viewMode,
    required this.onViewMode,
  });

  final Map<String, String> videoNames;
  final int viewMode;
  final ValueChanged<int> onViewMode;

  @override
  State<VideoSettingsPage> createState() => _VideoSettingsPageState();
}

class _VideoSettingsPageState extends State<VideoSettingsPage> {
  late int selectedViewMode = widget.viewMode;
  bool importing = false;

  @override
  Widget build(BuildContext context) {
    final settings = PlayerSettings.instance;
    String t(String fa, String en) => socialText(context, fa, en);
    Future<T?> choose<T>(String title, List<(T, String)> options) =>
        showDialog<T>(
          context: context,
          builder: (dialog) => SimpleDialog(
            shape: RoundedRectangleBorder(borderRadius: appRadius(dialog)),
            title: Text(title, style: Theme.of(dialog).textTheme.bodyMedium),
            children: [
              for (final option in options)
                SimpleDialogOption(
                  onPressed: () => Navigator.pop(dialog, option.$1),
                  child: Text(
                    option.$2,
                    style: Theme.of(dialog).textTheme.bodyMedium,
                  ),
                ),
            ],
          ),
        );

    Widget choiceRow(String title, String value, VoidCallback action) =>
        ListTile(
          title: Text(title, style: Theme.of(context).textTheme.bodyMedium),
          trailing: Text(value, style: Theme.of(context).textTheme.bodySmall),
          onTap: action,
        );

    String viewLabel(int value) => switch (value) {
      3 => t('نمایش گرید سه تایی', 'Three-column grid'),
      4 => t('نمایش گرید چهار تایی', 'Four-column grid'),
      _ => t('نمایش حالت خطی', 'List view'),
    };

    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) => Scaffold(
        appBar: SornazAppBar(
          title: t('تنظیمات پخش‌ ویدیو', 'Video playback settings'),
        ),
        body: ListView(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          children: [
            if (AppPlatform.isIOS)
              ListTile(
                title: Text(
                  t('افزودن ویدیو از فایل‌ها', 'Import videos from Files'),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                trailing: importing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : null,
                onTap: importing
                    ? null
                    : () async {
                        setState(() => importing = true);
                        try {
                          final count = await importIosVideos();
                          if (count > 0 && context.mounted)
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  t(
                                    '$count ویدیو به گالری اضافه شد.',
                                    '$count videos added to Photos.',
                                  ),
                                ),
                              ),
                            );
                        } catch (_) {
                          if (context.mounted)
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  t(
                                    'افزودن ویدیو ممکن نشد.',
                                    'Could not import videos.',
                                  ),
                                ),
                              ),
                            );
                        } finally {
                          if (mounted) setState(() => importing = false);
                        }
                      },
              ),
            if (AppPlatform.isWindows)
              ListTile(
                title: Text(
                  t('پوشه‌های کتابخانه', 'Library folders'),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const DesktopLibraryFolders(video: true),
                  ),
                ),
              ),
            for (final entry in [
              ('sort', 'مرتب‌سازی تب‌ها', 'Sort Tabs'),
              ('hide', 'مخفی کردن تب‌ها', 'Hide Tabs'),
              ('files', 'فایل‌ها و پوشه‌های مخفی', 'Hidden Files and Folders'),
            ])
              ListTile(
                title: Text(
                  t(entry.$2, entry.$3),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MusicLibrarySettings(
                      mode: entry.$1,
                      video: true,
                      videoNames: widget.videoNames,
                    ),
                  ),
                ),
              ),
            SettingsSwitchTile.widgets(
              title: Text(
                t(
                  'ذخیره و بازیابی موقعیت پخش',
                  'Save/Restore Playback Position',
                ),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              value: settings.videoSavePlaybackPosition,
              onChanged: (value) =>
                  settings.setOption('videoSavePlaybackPosition', value),
            ),

            const PlayerSortTile(video: true),
            choiceRow(
              t('حالت نمایش', 'Display mode'),
              viewLabel(selectedViewMode),
              () async {
                final value = await choose<int>(
                  t('حالت نمایش', 'Display mode'),
                  [(0, viewLabel(0)), (3, viewLabel(3)), (4, viewLabel(4))],
                );
                if (value != null) {
                  setState(() => selectedViewMode = value);
                  widget.onViewMode(value);
                }
              },
            ),
            choiceRow(
              t('پایان آخرین فایل لیست', 'At the end of the list'),
              endLabel(context, settings.listEnd),
              () async {
                final value = await choose<ListEndAction>(
                  t('پایان آخرین فایل لیست', 'At the end of the list'),
                  [
                    for (final action in ListEndAction.values)
                      (action, endLabel(context, action)),
                  ],
                );
                if (value != null) settings.setListEnd(value);
              },
            ),
          ],
        ),
      ),
    );
  }
}
