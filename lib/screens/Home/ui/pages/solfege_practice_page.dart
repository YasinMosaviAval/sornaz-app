import 'package:flutter/material.dart';
import '../../../../helpers/development_access.dart';
import '../../../IntervalRecognition/levels_screen.dart';
import 'package:sornaz/screens/Players/ui/components/music_playback_entry.dart';
import 'package:sornaz/screens/Players/services/player_settings.dart';
import 'package:sornaz/components/app_bar.dart';
import 'package:sornaz/screens/Social/social_widgets.dart';
import 'package:sornaz/screens/IntervalRecognition/music_selection_screen.dart';
import 'package:sornaz/screens/IntervalRecognition/text.dart';

class SolfegePracticePage extends StatelessWidget {
  const SolfegePracticePage({super.key});

  @override
  Widget build(BuildContext context) => MusicPlaybackEntry(
    reason: PlaybackInterruption.solfege,
    child: _content(context),
  );
  Widget _content(BuildContext context) => Scaffold(
    appBar: SornazAppBar(
      title: socialText(context, 'تمرین سولفژ', 'Solfege practice'),
    ),
    body: ListView(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      children: [
        for (final section in [
          ('گام شناسی', 'Scale recognition'),
          ('آکورد شناسی', 'Chord recognition'),
          ('تشخیص فرکانس', 'Frequency recognition'),
          ('تشخیص فاصله', 'Interval recognition'),
          ('تشخیص آکورد', 'Chord identification'),
          ('تشخیص هارمونی', 'Harmony recognition'),
        ])
          ListTile(
            onTap: section.$2 == 'Interval recognition'
                ? () => socialPush(
                    context,
                    DevelopmentAccess.read(context)
                        ? const IntervalMusicSelectionScreen()
                        : const IntervalLevelsScreen(),
                  )
                : null,
            title: Text(
              section.$2 == 'Interval recognition'
                  ? IntervalText(context)('interval.title')
                  : socialText(context, section.$1, section.$2),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
      ],
    ),
  );
}
