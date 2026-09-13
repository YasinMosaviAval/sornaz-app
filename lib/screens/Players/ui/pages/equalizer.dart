import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:just_audio/just_audio.dart';
import 'package:sornaz/screens/Players/providers/audio_player_provider.dart';
import 'package:sornaz/screens/Social/social_widgets.dart';

class EqualizerTab extends StatelessWidget {
  const EqualizerTab({super.key});
  @override
  Widget build(BuildContext context) {
    final player = context.watch<AudioPlayerProvider>(), eq = player.equalizer;
    if (eq == null)
      return Center(
        child: Text(
          socialText(
            context,
            'اکولایزر روی این دستگاه در دسترس نیست.',
            'Equalizer is unavailable on this device.',
          ),
        ),
      );
    return FutureBuilder<AndroidEqualizerParameters>(
      future: eq.parameters,
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return Center(
            child: Text(
              socialText(
                context,
                'برای تنظیم اکولایزر یک آهنگ پخش کنید.',
                'Play a track to adjust the equalizer.',
              ),
            ),
          );
        final p = snapshot.data!;
        return StreamBuilder<bool>(
          stream: eq.enabledStream,
          initialData: eq.enabled,
          builder: (context, enabled) => ListView(
            padding: const EdgeInsets.all(20),
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(socialText(context, 'اکولایزر', 'Equalizer')),
                value: enabled.data ?? false,
                onChanged: (v) async {
                  try {
                    await eq.setEnabled(v);
                    await player.saveEqualizer();
                  } catch (e) {
                    if (context.mounted) socialError(context, e);
                  }
                },
              ),
              for (final band in p.bands)
                StreamBuilder<double>(
                  stream: band.gainStream,
                  initialData: band.gain,
                  builder: (context, gain) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${band.centerFrequency >= 1000 ? (band.centerFrequency / 1000).toStringAsFixed(1) : band.centerFrequency.round()} ${band.centerFrequency >= 1000 ? 'kHz' : 'Hz'}    ${(gain.data ?? 0).toStringAsFixed(1)} dB',
                        textDirection: TextDirection.ltr,
                      ),
                      Slider(
                        min: p.minDecibels,
                        max: p.maxDecibels,
                        value: (gain.data ?? 0).clamp(
                          p.minDecibels,
                          p.maxDecibels,
                        ),
                        onChanged: enabled.data == true
                            ? (v) async {
                                try {
                                  await band.setGain(v);
                                } catch (e) {
                                  if (context.mounted) socialError(context, e);
                                }
                              }
                            : null,
                        onChangeEnd: (_) async {
                          await player.saveEqualizer();
                        },
                      ),
                    ],
                  ),
                ),
              TextButton(
                onPressed: () async {
                  for (final b in p.bands) {
                    await b.setGain(0);
                  }
                  await player.saveEqualizer();
                },
                child: Text(socialText(context, 'بازنشانی', 'Reset')),
              ),
            ],
          ),
        );
      },
    );
  }
}
