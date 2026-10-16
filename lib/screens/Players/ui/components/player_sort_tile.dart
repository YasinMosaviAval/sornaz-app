import 'package:flutter/material.dart';
import 'package:sornaz/helpers/app_appearance.dart';
import 'package:sornaz/screens/Social/social_widgets.dart';
import '../../services/player_settings.dart';

const playerSortOptions = [
  ('added', 'تاریخ و زمان اضافه شدن', 'Date and time added'),
  ('name', 'حروف الفبا', 'Alphabetical'),
  ('duration', 'مدت زمان', 'Duration'),
  ('count', 'تعداد فایل‌های پوشه', 'File count in folders'),
];

String playerSortLabel(BuildContext context, String key, bool ascending) {
  final option = playerSortOptions.firstWhere(
    (option) => option.$1 == key,
    orElse: () => playerSortOptions.first,
  );
  return '${socialText(context, option.$2, option.$3)} - ${ascending ? socialText(context, 'صعودی', 'Ascending') : socialText(context, 'نزولی', 'Descending')}';
}

class PlayerSortTile extends StatelessWidget {
  const PlayerSortTile({super.key, this.video = false, this.settings});
  final bool video;
  final PlayerSettings? settings;
  @override
  Widget build(BuildContext context) {
    final settings = this.settings ?? PlayerSettings.instance;
    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) => ListTile(
        title: Text(
          socialText(context, 'مرتب‌سازی', 'Sort'),
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        trailing: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.sizeOf(context).width * .55,
          ),
          child: Text(
            playerSortLabel(
              context,
              video ? settings.videoSort : settings.musicSort,
              video ? settings.videoSortAscending : settings.musicSortAscending,
            ),
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.end,
          ),
        ),
        onTap: () async {
          final value = await showDialog<(String, bool)>(
            context: context,
            builder: (dialog) => SimpleDialog(
              shape: RoundedRectangleBorder(borderRadius: appRadius(dialog)),
              title: Text(
                socialText(dialog, 'مرتب‌سازی', 'Sort'),
                style: Theme.of(dialog).textTheme.bodyMedium,
              ),
              children: [
                for (final option in playerSortOptions)
                  for (final ascending in [true, false])
                    SimpleDialogOption(
                      onPressed: () =>
                          Navigator.pop(dialog, (option.$1, ascending)),
                      child: Text(
                        playerSortLabel(dialog, option.$1, ascending),
                        style: Theme.of(dialog).textTheme.bodyMedium,
                      ),
                    ),
              ],
            ),
          );
          if (value == null) return;
          await settings.setOption(video ? 'videoSort' : 'musicSort', value.$1);
          await settings.setOption(
            video ? 'videoSortAscending' : 'musicSortAscending',
            value.$2,
          );
        },
      ),
    );
  }
}
