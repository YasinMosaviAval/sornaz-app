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

    String sortLabel(String value) => switch (value) {
      'name' => t('حروف الفبا', 'Alphabetical'),
      'duration' => t('مدت زمان', 'Duration'),
      'count' => t('تعداد ویدیوهای پوشه', 'Video count in folders'),
      _ => t('تاریخ و زمان اضافه شدن', 'Date and time added'),
    };
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
            SwitchListTile(
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

            choiceRow(
              t('مرتب‌سازی', 'Sort'),
              sortLabel(settings.videoSort),
              () async {
                final value = await choose<String>(t('مرتب‌سازی', 'Sort'), [
                  ('added', t('تاریخ و زمان اضافه شدن', 'Date and time added')),
                  ('name', t('حروف الفبا', 'Alphabetical')),
                  ('duration', t('مدت زمان', 'Duration')),
                  ('count', t('تعداد ویدیوهای پوشه', 'Video count in folders')),
                ]);
                if (value != null) {
                  await settings.setOption('videoSort', value);
                  await settings.setOption(
                    'videoSortAscending',
                    value == 'name' || value == 'duration',
                  );
                }
              },
            ),
            SwitchListTile(
              title: Text(
                t('ترتیب صعودی', 'Ascending order'),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              subtitle: Text(
                t('خاموش: نزولی', 'Off: descending'),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              value: settings.videoSortAscending,
              onChanged: (value) =>
                  settings.setOption('videoSortAscending', value),
            ),
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
