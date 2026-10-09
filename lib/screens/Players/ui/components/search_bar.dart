import 'package:sornaz/components/scroll_aware_scaffold.dart';
import 'package:sornaz/components/app_top_bar_direction.dart';
import 'package:sornaz/helpers/app_data.dart';
import 'package:sornaz/helpers/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sornaz/components/expanding_search_bar.dart';
import 'package:sornaz/helpers/app_appearance.dart';

import '../../providers/audio_player_provider.dart';
import '../../library/audio_library_manager.dart';
import '../../services/player_settings.dart';
import '../pages/playlists.dart';
import '../pages/music_library_settings.dart';
import 'player_dialog.dart';
import 'package:sornaz/screens/Social/social_widgets.dart';

class SearchBarWidget extends StatelessWidget implements PreferredSizeWidget {
  const SearchBarWidget({super.key, this.tab = 0, this.onRescan});
  final int tab;
  final VoidCallback? onRescan;
  @override
  Size get preferredSize => const Size.fromHeight(48);
  @override
  Widget build(BuildContext context) {
    final scanning = context.select<AudioLibraryManager, bool>(
      (library) => library.isScanning,
    );
    Widget rescanButton() => IconButton(
      tooltip: socialText(
        context,
        'اسکن مجدد فایل‌های صوتی',
        'Rescan audio files',
      ),
      onPressed: scanning ? null : onRescan,
      icon: const Icon(Icons.refresh, size: 24),
    );
    void settings() => Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PlayerSettingsPage()),
    );
    if (tab == 3) {
      final eq = context.read<AudioPlayerProvider>().equalizer;
      return ListenableBuilder(
        listenable: eq,
        builder: (c, _) => AppTopBarDirection(
          child: AppBar(
            title: Text(
              socialText(context, 'پخش موسیقی', 'Music playback'),
              style:
                  Theme.of(c).appBarTheme.titleTextStyle?.copyWith(
                    fontSize: AppTopBarDirection.titleSize(c),
                  ) ??
                  TextStyle(fontSize: AppTopBarDirection.titleSize(c)),
            ),
            actions: [
              rescanButton(),
              IconButton(
                tooltip: socialText(
                  context,
                  'فعال کردن اکولایزر',
                  'Enable equalizer',
                ),
                onPressed: () => eq.setEnabled(!eq.enabled),
                icon: Icon(
                  Icons.graphic_eq,
                  size: 24,
                  color: eq.enabled
                      ? context.watch<AppData>().accent
                      : Colors.grey,
                ),
              ),
              IconButton(
                tooltip: socialText(
                  context,
                  'بازنشانی فیلترها',
                  'Reset filters',
                ),
                onPressed: eq.enabled ? eq.reset : null,
                icon: const Icon(Icons.restart_alt, size: 24),
              ),
              IconButton(
                onPressed: settings,
                icon: const Icon(Icons.settings, size: 24),
              ),
            ],
          ),
        ),
      );
    }
    return ExpandingSearchBar(
      title: Transform.translate(
        offset: Offset(
          Localizations.localeOf(context).languageCode == 'fa' ? 12 : -12,
          0,
        ),
        child: Row(
          children: [
            const SizedBox(
              width: AppTopBarDirection.leadingWidth,
              child: BackButton(),
            ),
            Expanded(
              child: Text(
                socialText(context, 'پخش موسیقی', 'Music playback'),
                style:
                    Theme.of(context).appBarTheme.titleTextStyle?.copyWith(
                      fontSize: AppTopBarDirection.titleSize(context),
                    ) ??
                    TextStyle(fontSize: AppTopBarDirection.titleSize(context)),
              ),
            ),
          ],
        ),
      ),
      searchIconSize: 24,
      searchIconColor: AppColors.sornaz_app_bar_text_color(
        isDark: context.watch<AppData>().isDark,
      ),
      onChanged: context.read<AudioPlayerProvider>().filter,
      actions: [
        rescanButton(),
        if (tab == 2)
          IconButton(
            tooltip: 'لیست پخش جدید',
            icon: const Icon(Icons.playlist_add),
            onPressed: () => createMusicPlaylist(context),
          ),
      ],
      onSettings: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PlayerSettingsPage()),
      ),
    );
  }
}

String endLabel(BuildContext c, ListEndAction action) => switch (action) {
  ListEndAction.restart => socialText(c, 'پخش از ابتدای لیست', 'Restart list'),
  ListEndAction.nextList => socialText(c, 'پخش لیست بعد', 'Play next list'),
  ListEndAction.stop => socialText(c, 'توقف پخش', 'Stop playback'),
};

class PlayerSettingsPage extends StatelessWidget {
  const PlayerSettingsPage({super.key});
  @override
  Widget build(BuildContext context) {
    final player = context.watch<AudioPlayerProvider>();
    final settings = player.settings;
    return ListenableBuilder(
      listenable: settings,
      builder: (c, _) => ScrollAwareScaffold(
        appBar: AppTopBarDirection(
          child: AppBar(
            title: Text(
              socialText(c, 'تنظیمات پخش موسیقی', 'Music playback settings'),
            ),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.symmetric(vertical: 12),
          children: [
            for (final entry in [
              ('sort', 'مرتب‌سازی تب‌ها', 'Sort Tabs'),
              ('hide', 'مخفی کردن تب‌ها', 'Hide Tabs'),
              ('files', 'فایل‌ها و پوشه‌های مخفی', 'Hidden Files and Folders'),
            ])
              ListTile(
                title: Text(
                  socialText(c, entry.$2, entry.$3),
                  style: Theme.of(c).textTheme.bodyMedium,
                ),
                onTap: () => Navigator.push(
                  c,
                  MaterialPageRoute(
                    builder: (_) => MusicLibrarySettings(mode: entry.$1),
                  ),
                ),
              ),
            SwitchListTile(
              title: Text(
                socialText(
                  c,
                  'ذخیره و بازیابی موقعیت پخش',
                  'Save/Restore Playback Position',
                ),
                style: Theme.of(c).textTheme.bodyMedium,
              ),
              value: settings.savePlaybackPosition,
              onChanged: (v) => settings.setOption('savePlaybackPosition', v),
            ),
            for (final entry in {
              PlaybackInterruption.leavePlayer: socialText(
                c,
                'قطع پخش هنگام خروج از صفحه پخش موسیقی',
                'Stop when leaving the music player',
              ),
              PlaybackInterruption.exitApp: socialText(
                c,
                'قطع پخش هنگام خروج کامل از برنامه',
                'Stop when exiting the app',
              ),
              PlaybackInterruption.recording: socialText(
                c,
                'قطع پخش هنگام ورود به صفحه ضبط صدا',
                'Stop when entering the voice recorder',
              ),
              PlaybackInterruption.metronome: socialText(
                c,
                'قطع پخش هنگام ورود به مترونوم',
                'Stop when entering the metronome',
              ),
              PlaybackInterruption.tuner: socialText(
                c,
                'قطع پخش هنگام ورود به تیونر',
                'Stop when entering the tuner',
              ),
            }.entries)
              Container(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      width: .2,
                      color: Theme.of(
                        c,
                      ).colorScheme.onSurface.withValues(alpha: .04),
                    ),
                  ),
                ),
                child: SwitchListTile(
                  contentPadding: const EdgeInsetsDirectional.only(
                    start: 16,
                    end: 16,
                  ),
                  title: Text(
                    entry.value,
                    style: Theme.of(c).textTheme.bodyMedium,
                  ),
                  value: settings.stopsFor(entry.key),
                  onChanged: (v) => settings.setStop(entry.key, v),
                ),
              ),
            ListTile(
              title: Text(
                socialText(c, 'مرتب‌سازی', 'Sort'),
                style: Theme.of(c).textTheme.bodyMedium,
              ),
              trailing: Text(switch (settings.musicSort) {
                'name' => socialText(c, 'حروف الفبا', 'Alphabetical'),
                'duration' => socialText(c, 'مدت زمان', 'Duration'),
                'count' => socialText(
                  c,
                  'تعداد آهنگ‌های پوشه',
                  'Audio count in folders',
                ),
                _ => socialText(
                  c,
                  'تاریخ و زمان اضافه شدن',
                  'Date and time added',
                ),
              }, style: Theme.of(c).textTheme.bodySmall),
              onTap: () async {
                final value = await showDialog<String>(
                  context: c,
                  builder: (dialog) => SimpleDialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: appRadius(dialog),
                    ),
                    title: Text(
                      socialText(dialog, 'مرتب‌سازی', 'Sort'),
                      style: Theme.of(dialog).textTheme.bodyMedium,
                    ),
                    children: [
                      for (final entry in [
                        (
                          'added',
                          'تاریخ و زمان اضافه شدن',
                          'Date and time added',
                        ),
                        ('name', 'حروف الفبا', 'Alphabetical'),
                        ('duration', 'مدت زمان', 'Duration'),
                        (
                          'count',
                          'تعداد آهنگ‌های پوشه',
                          'Audio count in folders',
                        ),
                      ])
                        SimpleDialogOption(
                          onPressed: () => Navigator.pop(dialog, entry.$1),
                          child: Text(
                            socialText(dialog, entry.$2, entry.$3),
                            style: Theme.of(dialog).textTheme.bodyMedium,
                          ),
                        ),
                    ],
                  ),
                );
                if (value != null) {
                  await settings.setOption('musicSort', value);
                  await settings.setOption(
                    'musicSortAscending',
                    value == 'name' || value == 'duration',
                  );
                }
              },
            ),
            SwitchListTile(
              title: Text(
                socialText(c, 'ترتیب صعودی', 'Ascending order'),
                style: Theme.of(c).textTheme.bodyMedium,
              ),
              subtitle: Text(
                socialText(c, 'خاموش: نزولی', 'Off: descending'),
                style: Theme.of(c).textTheme.bodySmall,
              ),
              value: settings.musicSortAscending,
              onChanged: (value) =>
                  settings.setOption('musicSortAscending', value),
            ),
            InkWell(
              onTap: () async {
                final action = await showDialog<ListEndAction>(
                  context: c,
                  builder: (d) => SimpleDialog(
                    title: Text(
                      socialText(
                        d,
                        'پایان آخرین فایل لیست',
                        'At the end of the list',
                      ),
                      style: const TextStyle(fontSize: 14),
                    ),
                    children: [
                      for (final value in ListEndAction.values)
                        SimpleDialogOption(
                          onPressed: () => Navigator.pop(d, value),
                          child: Text(endLabel(d, value)),
                        ),
                    ],
                  ),
                );
                if (action != null) await settings.setListEnd(action);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        socialText(
                          c,
                          'پایان آخرین فایل لیست',
                          'At the end of the list',
                        ),
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: Text(
                        endLabel(c, settings.listEnd),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Divider(
              height: .2,
              thickness: .2,
              color: Theme.of(c).colorScheme.onSurface.withValues(alpha: .04),
            ),
            InkWell(
              onTap: () => showSleepTimer(c, player),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 18,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        socialText(c, 'تایمر خواب', 'Sleep Timer'),
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      player.sleepAtTrackEnd
                          ? socialText(
                              c,
                              'پایان آهنگ فعلی',
                              'End of current track',
                            )
                          : player.sleepDuration == null
                          ? socialText(c, 'غیرفعال', 'Off')
                          : '${player.sleepDuration!.inMinutes} ${socialText(c, 'دقیقه', 'minutes')}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
            Divider(
              height: .2,
              thickness: .2,
              color: Theme.of(c).colorScheme.onSurface.withValues(alpha: .04),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> showSleepTimer(
  BuildContext context,
  AudioPlayerProvider player,
) async {
  final value = await showDialog<int>(
    context: context,
    builder: (c) => SimpleDialog(
      title: Text(
        socialText(c, 'تایمر خواب', 'Sleep Timer'),
        style: const TextStyle(fontSize: 14),
      ),
      children: [
        SimpleDialogOption(
          onPressed: () => Navigator.pop(c, 0),
          child: Text(socialText(c, 'غیرفعال', 'Off')),
        ),
        for (var minutes = 5; minutes <= 60; minutes += 5)
          SimpleDialogOption(
            onPressed: () => Navigator.pop(c, minutes),
            child: Text('$minutes ${socialText(c, 'دقیقه', 'minutes')}'),
          ),
        SimpleDialogOption(
          onPressed: () => Navigator.pop(c, -1),
          child: Text(socialText(c, 'زمان دستی', 'Custom duration')),
        ),
        SimpleDialogOption(
          onPressed: () => Navigator.pop(c, -2),
          child: Text(socialText(c, 'پایان آهنگ فعلی', 'End of current track')),
        ),
      ],
    ),
  );
  if (value == null || !context.mounted) return;
  if (value == -1) {
    final form = GlobalKey<FormState>();
    var minutes = '';
    final custom = await showDialog<int>(
      context: context,
      builder: (c) => PlayerDialog(
        title: Text(
          socialText(c, 'زمان دستی (دقیقه)', 'Custom duration (minutes)'),
          style: const TextStyle(fontSize: 14),
        ),
        content: Form(
          key: form,
          child: TextFormField(
            autofocus: true,
            keyboardType: TextInputType.number,
            onChanged: (v) => minutes = v,
            validator: (v) => (int.tryParse(v ?? '') ?? 0) > 0
                ? null
                : socialText(
                    c,
                    'زمان معتبر وارد کنید',
                    'Enter a valid duration',
                  ),
          ),
        ),
        actions: [
          PlayerDialogButton(
            primary: false,
            onPressed: () => Navigator.pop(c),
            child: Text(socialText(c, 'انصراف', 'Cancel')),
          ),
          PlayerDialogButton(
            onPressed: () {
              if (form.currentState!.validate()) {
                Navigator.pop(c, int.parse(minutes));
              }
            },
            child: Text(socialText(c, 'شروع', 'Start')),
          ),
        ],
      ),
    );
    if (custom != null) {
      player.setSleepTimer(duration: Duration(minutes: custom));
    }
  } else {
    player.setSleepTimer(
      duration: value > 0 ? Duration(minutes: value) : null,
      atTrackEnd: value == -2,
    );
  }
}
