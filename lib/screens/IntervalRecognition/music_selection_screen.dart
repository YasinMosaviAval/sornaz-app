import 'package:flutter/material.dart';
import 'package:sornaz/components/app_bar.dart';
import 'package:sornaz/helpers/app_appearance.dart';
import 'levels_screen.dart';
import 'text.dart';
import 'models.dart';

class IntervalMusicSelectionScreen extends StatelessWidget {
  const IntervalMusicSelectionScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final t = IntervalText(context);
    final theme = Theme.of(context);
    return Directionality(
      textDirection: t.direction,
      child: Scaffold(
        appBar: SornazAppBar(title: t('interval.title')),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            children: [
              for (final (key, icon, page) in <(String, IconData, Widget)>[
                (
                  'interval.iranianMusic',
                  Icons.music_note,
                  const IranianIntervalScreen(),
                ),
                (
                  'interval.westernMusic',
                  Icons.piano,
                  const IntervalLevelsScreen(),
                ),
              ]) ...[
                Card(
                  margin: EdgeInsets.zero,
                  child: ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: appRadius(context),
                    ),
                    minVerticalPadding: 20,
                    leading: Icon(icon, color: theme.colorScheme.primary),
                    title: Text(t(key), style: theme.textTheme.bodyLarge),
                    onTap: () => Navigator.of(
                      context,
                    ).push(MaterialPageRoute<void>(builder: (_) => page)),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class IranianIntervalScreen extends StatelessWidget {
  const IranianIntervalScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const IntervalLevelsScreen(music: IntervalMusic.iranian);
}
