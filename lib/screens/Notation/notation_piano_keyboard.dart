import 'package:flutter/material.dart';
import 'package:sornaz/components/app_piano_keyboard.dart';

/// Notation adapter for the same keyboard used by the tuner. The editor remains
/// responsible for scale labels, help, duration gestures, playback and insertion.
class NotationPianoKeyboard extends StatelessWidget {
  const NotationPianoKeyboard({
    super.key,
    required this.data,
    required this.send,
  });
  final Map<String, dynamic> data;
  final void Function(Map<String, Object> event) send;

  @override
  Widget build(BuildContext context) {
    final labels = data['labels'] as Map? ?? const {};
    final visible = data['visible'] == true;
    final shade =
        ((data['modalShade'] as num?)?.toDouble() ??
                (data['durationPickerOpen'] == true ? .18 : 0.0))
            .clamp(0.0, 1.0);
    return Offstage(
      offstage: !visible,
      child: Listener(
        onPointerDown: (_) {
          if (data['durationPickerOpen'] == true) {
            send({'phase': 'dismiss'});
          }
        },
        child: Stack(
          children: [
            AppPianoKeyboard(
              firstMidi: 21,
              lastMidi: 108,
              initialMidi: 60,
              showQuarterTones: data['quarterTones'] == true,
              enabled: visible && data['enabled'] == true,
              selectedKeyId: data['selectedKeyId']?.toString(),
              showOctave: true,
              labelFor: (key) => labels[key.id]?.toString() ?? '',
              onPointer: (key, phase, delta) => send({
                'pitch': key.pitch,
                'accidental': key.accidental,
                'phase': phase.name,
                'dx': delta.dx,
                'dy': delta.dy,
              }),
            ),
            if (shade > 0)
              Positioned.fill(
                child: IgnorePointer(
                  child: ColoredBox(
                    color: Colors.black.withValues(alpha: shade),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
