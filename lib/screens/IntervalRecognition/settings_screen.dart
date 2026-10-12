import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sornaz/components/app_bar.dart';
import 'package:sornaz/helpers/app_appearance.dart';
import 'package:sornaz/screens/Metronome/ui/components/labeled_slider.dart';
import 'settings.dart';
import 'text.dart';

class IntervalSettingsScreen extends StatelessWidget {
  const IntervalSettingsScreen({super.key, required this.settings});
  final IntervalAudioSettings settings;

  Future<void> _chooseInstrument(BuildContext context) async {
    final instrument = await showDialog<IntervalInstrument>(
      context: context,
      builder: (dialog) {
        final t = IntervalText(dialog);
        return Directionality(
          textDirection: t.direction,
          child: SimpleDialog(
            shape: RoundedRectangleBorder(borderRadius: appRadius(dialog)),
            title: Text(
              t('interval.instrument'),
              style: Theme.of(dialog).textTheme.bodyMedium,
            ),
            children: [
              for (final instrument in IntervalInstrument.values)
                SimpleDialogOption(
                  onPressed: () => Navigator.pop(dialog, instrument),
                  child: Text(
                    t(instrument.translationKey),
                    style: Theme.of(dialog).textTheme.bodyMedium,
                  ),
                ),
            ],
          ),
        );
      },
    );
    if (instrument != null) await settings.setInstrument(instrument);
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: settings,
    builder: (context, _) {
      final t = IntervalText(context);
      final theme = Theme.of(context);
      final duration = t('interval.durationValue', {
        'value': t.number(settings.noteDurationMs),
      });
      return Directionality(
        textDirection: t.direction,
        child: Scaffold(
          appBar: SornazAppBar(title: t('interval.settingsTitle')),
          body: SafeArea(
            child: settings.loaded
                ? ListView(
                    padding: const EdgeInsets.all(12),
                    children: [
                      LabeledSlider(
                        leadingIcon: const Icon(Icons.timer_outlined, size: 20),
                        label: '${t('interval.duration')}: $duration',
                        valueLabel: duration,
                        labelPadding: const EdgeInsets.only(top: 12),
                        value: settings.noteDurationMs.toDouble(),
                        min: IntervalAudioSettings.minimumDurationMs.toDouble(),
                        max: IntervalAudioSettings.maximumDurationMs.toDouble(),
                        divisions:
                            (IntervalAudioSettings.maximumDurationMs -
                                IntervalAudioSettings.minimumDurationMs) ~/
                            50,
                        isDark: theme.brightness == Brightness.dark,
                        onChanged: (value) =>
                            unawaited(settings.setDuration(value.round())),
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          t('interval.instrument'),
                          style: theme.textTheme.bodyMedium,
                        ),
                        trailing: Text(
                          t(settings.instrument.translationKey),
                          style: theme.textTheme.bodySmall,
                        ),
                        onTap: () => _chooseInstrument(context),
                      ),
                      if (settings.errorKey != null) ...[
                        Text(
                          t(settings.errorKey!),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.error,
                          ),
                        ),
                        TextButton(
                          onPressed: settings.retrySave,
                          child: Text(t('interval.retry')),
                        ),
                      ],
                    ],
                  )
                : const Center(child: CircularProgressIndicator()),
          ),
        ),
      );
    },
  );
}
