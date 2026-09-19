import 'package:sornaz/screens/Notation/music_sheets_page.dart';
import 'package:sornaz/components/main_tabs.dart';
import 'package:sornaz/components/home_top_bar.dart';
import '../components/app_drawer.dart';
import 'package:flutter/material.dart';
import 'package:sornaz/components/bottom_nav.dart';
import 'package:sornaz/screens/Social/social_widgets.dart';
import 'package:sornaz/screens/Players/ui/pages/music_palyer.dart';
import 'package:sornaz/screens/Metronome/ui/pages/metronome_page.dart';
import 'package:sornaz/screens/Tuner/ui/pages/tuner_page.dart';
import 'package:sornaz/screens/Voice%20Recorder/ui/pages/voice_recorder.dart';

class MusicToolsPage extends StatelessWidget {
  const MusicToolsPage({super.key});
  @override
  Widget build(BuildContext context) => MainTabsScope.maybeOf(context) == null
      ? MainTabs(initialIndex: 3, initialChild: this)
      : SocialScaffold(
          tabIndex: 3,
          title: socialText(context, 'ابزار موسیقی', 'Music tools'),
          appBar: const HomeTopBar(),
          drawer: const AppDrawer(),
          bottom: const BottomNavBarWidget(selectedIndex: 3),
          body: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              for (final item in [
                (
                  Icons.music_note_outlined,
                  'نت‌نویسی',
                  'Notation',
                  const MusicSheetsPage(),
                ),
                (
                  Icons.library_music_outlined,
                  'پخش‌کننده',
                  'Music player',
                  const MusicPlayerPage(),
                ),
                (
                  Icons.punch_clock_outlined,
                  'مترونوم',
                  'Metronome',
                  const MetronomePage(),
                ),
                (Icons.tune, 'تیونر', 'Tuner', const TunerPage()),
                (
                  Icons.mic_none,
                  'ضبط صدا',
                  'Recorder',
                  const VoiceRecorderPage(),
                ),
              ])
                Card(
                  child: ListTile(
                    leading: Icon(item.$1),
                    title: Text(socialText(context, item.$2, item.$3)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => socialPush(context, item.$4),
                  ),
                ),
            ],
          ),
        );
}
