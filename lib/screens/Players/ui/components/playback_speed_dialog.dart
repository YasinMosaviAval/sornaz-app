import 'package:flutter/material.dart';
import 'package:sornaz/screens/Social/social_widgets.dart';

Future<void> showPlaybackSpeedDialog(
  BuildContext context, {
  required double speed,
  required List<double> presets,
  required ValueChanged<double> onChanged,
}) => showDialog<void>(
  context: context,
  builder: (context) => StatefulBuilder(
    builder: (context, update) {
      void change(double v) {
        update(() => speed = v);
        onChanged(v);
      }

      return AlertDialog(
        title: Text(socialText(context, 'سرعت پخش', 'Playback speed')),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 4,
                children: [
                  for (final value in presets)
                    TextButton(
                      onPressed: () => change(value),
                      style: TextButton.styleFrom(
                        foregroundColor: (speed - value).abs() < .001
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.onSurface,
                      ),
                      child: Text('${value}×'),
                    ),
                ],
              ),
              Slider(
                min: presets.first,
                max: presets.last,
                value: speed.clamp(presets.first, presets.last),
                divisions: ((presets.last - presets.first) * 100).round(),
                label: '${speed.toStringAsFixed(2)}×',
                onChanged: change,
              ),
              Text('${speed.toStringAsFixed(2)}×'),
            ],
          ),
        ),
      );
    },
  ),
);
