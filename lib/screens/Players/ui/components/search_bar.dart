import 'package:sornaz/components/scroll_aware_scaffold.dart';
import 'package:sornaz/components/app_top_bar_direction.dart';
import 'package:sornaz/helpers/app_data.dart';
import 'package:sornaz/helpers/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sornaz/components/expanding_search_bar.dart';

import '../../providers/audio_player_provider.dart';
import '../../services/player_settings.dart';
import '../pages/playlists.dart';
import 'player_dialog.dart';
import 'package:sornaz/screens/Social/social_widgets.dart';

class SearchBarWidget extends StatelessWidget implements PreferredSizeWidget {
  const SearchBarWidget({super.key, this.tab = 0});
  final int tab;
  @override
  Size get preferredSize => const Size.fromHeight(56);
  @override
  Widget build(BuildContext context) {
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
              socialText(context, 'پخش‌کننده موسیقی', 'Music player'),
              style: const TextStyle(fontSize: 16),
            ),
            actions: [
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
      title: Row(
        children: [
          const BackButton(),
          Expanded(
            child: Text(
              socialText(context, 'پخش‌کننده موسیقی', 'Music player'),
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
      searchIconSize: 24,
      searchIconColor: AppColors.sornaz_app_bar_text_color(
        isDark: context.watch<AppData>().isDark,
      ),
      onChanged: context.read<AudioPlayerProvider>().filter,
      actions: [
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
                    style: const TextStyle(fontSize: 13),
                  ),
                  value: settings.stopsFor(entry.key),
                  onChanged: (v) => settings.setStop(entry.key, v),
                ),
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
              if (form.currentState!.validate())
                Navigator.pop(c, int.parse(minutes));
            },
            child: Text(socialText(c, 'شروع', 'Start')),
          ),
        ],
      ),
    );
    if (custom != null)
      player.setSleepTimer(duration: Duration(minutes: custom));
  } else {
    player.setSleepTimer(
      duration: value > 0 ? Duration(minutes: value) : null,
      atTrackEnd: value == -2,
    );
  }
}
