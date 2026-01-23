import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sornaz/helpers/app_colors.dart';
import 'package:sornaz/helpers/app_constants.dart';
import 'package:sornaz/helpers/app_data.dart';
import 'package:sornaz/helpers/app_strings.dart';
import 'package:sornaz/helpers/app_translations.dart';
import 'package:sornaz/helpers/app_typography.dart';
import 'package:sornaz/screens/Tuner/controller/tuner_provider.dart';
import 'package:sornaz/screens/Tuner/models/piano_key.dart';
import 'package:sornaz/screens/Tuner/models/tuner_keyboard_settings.dart';
import 'package:sornaz/screens/Tuner/utils/tuner_math.dart';

class PianoKeyboard extends StatefulWidget {
  final double a4;

  const PianoKeyboard({
    super.key,
    this.a4 = 440.0,
  });

  @override
  PianoKeyboardState createState() => PianoKeyboardState();
}

class PianoKeyboardState extends State<PianoKeyboard> {
  final Set<int> activeKeys = {};


  static const List<String> _noteNames = [
    AppConstants.C,
    AppConstants.C_SHARP,
    AppConstants.D,
    AppConstants.D_SHARP,
    AppConstants.E,
    AppConstants.F,
    AppConstants.F_SHARP,
    AppConstants.G,
    AppConstants.G_SHARP,
    AppConstants.A,
    AppConstants.A_SHARP,
    AppConstants.B
  ];


  // ---------- UI constants ----------
  // final double whiteKeyWidth = 60;
  final double whiteKeyHeight = 180;
  final double blackKeyWidth = 40;
  final double blackKeyHeight = 130;
  double _whiteKeyWidth(TunerKeyboardSettings settings) => settings.showQuarterTones ? 120 : 60;


  bool _isBlack(String note) => note.contains(AppConstants.SHARP);


  @override
  Widget build(BuildContext context) {
    final appData = context.watch<AppData>();
    final isDark = appData.isDark;

    final tuner = context.watch<TunerProvider>();
    final settings = tuner.keyboardSettings;

    final keys = _buildKeys(settings);
    final whiteKeys = keys
        .where((k) => !k.isBlack && k.microTone == MicroToneType.normal)
        .toList();
    final blackKeys = keys.where((k) => k.isBlack).toList();
    final keyWidth = _whiteKeyWidth(settings);


    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        // width: settings.octaveCount * 7 * whiteKeyWidth,
        width: settings.octaveCount * 7 * keyWidth,
        height: whiteKeyHeight,
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: AppColors.tuner_piano_keyboard_top_border_color(isDark: isDark), width: 0.3)
            )
          ),
          child: Stack(
            children: [
              _buildWhiteKeys(context, whiteKeys, settings, isDark),
              ..._buildBlackKeys(context, blackKeys, settings, isDark),
            ],
          ),
        ),
      ),
    );
  }


  // ---------- Build Keys ----------
  List<PianoKey> _buildKeys(TunerKeyboardSettings settings) {
    final List<PianoKey> keys = [];

    for (int octaveLengthIndex = 0; octaveLengthIndex < settings.octaveCount; octaveLengthIndex++) {

      final octave = settings.startOctave + octaveLengthIndex;

      for (int i = 0; i < _noteNames.length; i++) {
        final name = _noteNames[i];
        final midi = (octave + 1) * 12 + i;

        // نت اصلی
        keys.add(PianoKey(
          name: name,
          octave: octave,
          midi: midi,
          isBlack: _isBlack(name),
        ));

        if (settings.showQuarterTones) {
          // کرن
          keys.add(PianoKey(
            name: name,
            octave: octave,
            midi: midi,
            isBlack: true,
            microTone: MicroToneType.koron,
          ));

          // سری
          keys.add(PianoKey(
            name: name,
            octave: octave,
            midi: midi,
            isBlack: true,
            microTone: MicroToneType.sori,
          ));
        }
      }
    }
    return keys;
  }


  // ---------- White Keys ----------
  Widget _buildWhiteKeys(
    BuildContext context,
    List<PianoKey> keys,
    TunerKeyboardSettings settings,
    bool isDark,
  ) {
    return Row(
      children: keys.map((key) {
        final isActive = activeKeys.contains(key.midi);
        final isA4 = settings.highlightA4 && key.midi == 69;

        return GestureDetector(
          onTapDown: (_) => _onKeyDown(context, key),
          onTapUp: (_) => _onKeyUp(context, key),
          onTapCancel: () => _onKeyUp(context, key),
          child: Container(
            width: _whiteKeyWidth(settings),
            // width: whiteKeyWidth,
            height: whiteKeyHeight,
            alignment: Alignment.bottomCenter,
            decoration: BoxDecoration(
              color: isA4
                  ? AppColors.tuner_piano_keyboard_a4_key_color(isDark: isDark)
                  : isActive
                      ? AppColors.tuner_piano_keyboard_active_white_key_color(isDark: isDark)
                      : AppColors.tuner_piano_keyboard_inactive_white_key_color(isDark: isDark),
              border: Border.all(width: 0.5, color: AppColors.tuner_piano_keyboard_border_key_color(isDark: isDark)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(key.label, style: AppTypography.pianoKeyboardWhiteKeyLabel(context)),
                if (settings.showWhiteKeyFrequencies)
                  Text(
                    "${TunerMath.removeUnusedZERO(_frequencyFromKey(key))} ${AppStrings.hz.translate(context)}",
                    style: AppTypography.pianoKeyboardWhiteKeyFrequency(context),
                  ),
                const SizedBox(height: 4),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }


  // ---------- Black & Microtone Keys ----------
  List<Widget> _buildBlackKeys(
    BuildContext context,
    List<PianoKey> keys,
    TunerKeyboardSettings settings,
    bool isDark,
  ) {
    return keys.map((key) {
      final isActive = activeKeys.contains(key.midi);

      return Positioned(
        top: _microToneTop(key),
        left: _blackKeyOffset(key, settings),
        child: GestureDetector(
          onTapDown: (_) => _onKeyDown(context, key),
          onTapUp: (_) => _onKeyUp(context, key),
          onTapCancel: () => _onKeyUp(context, key),
          child: Container(
            width: _blackKeyWidthFor(key),
            height: _blackKeyHeightFor(key),
            alignment: Alignment.bottomCenter,
            decoration: BoxDecoration(
              color: isActive ? AppColors.tuner_piano_keyboard_active_not_white_key_color(isDark: isDark) : _microToneColor(key, isDark),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(4),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                key.label,
                style: AppTypography.pianoKeyboardNotWhiteKeyLable(context, key.microTone == MicroToneType.normal ? 10 : 8),
              ),
            ),
          ),
        ),
      );
    }).toList();
  }

  // ---------- Interaction ----------
  void _onKeyDown(BuildContext context, PianoKey key) {
    setState(() => activeKeys.add(key.midi));
    context.read<TunerProvider>().playNote(_frequencyFromKey(key));
  }

  void _onKeyUp(BuildContext context, PianoKey key) {
    setState(() => activeKeys.remove(key.midi));
    if (activeKeys.isEmpty) {
      context.read<TunerProvider>().stopNote();
    }
  }

  // ---------- Frequency ----------
  double _frequencyFromKey(PianoKey key) {
    final base = widget.a4 * pow(2, (key.midi - 69) / 12);

    switch (key.microTone) {
      case MicroToneType.koron:
        return base * pow(2, -0.5 / 12);
      case MicroToneType.sori:
        return base * pow(2, 0.5 / 12);
      default:
        return base;
    }
  }

  // ---------- Layout helpers ----------
  double _blackKeyOffset(PianoKey key, TunerKeyboardSettings settings) {
    const pattern = {
      1: 1.0,
      3: 2.0,
      6: 4.0,
      8: 5.0,
      10: 6.0,
    };

    final index = key.midi % 12;
    if (!pattern.containsKey(index)) return - 1000;

    final keyWidth = _whiteKeyWidth(settings);
    final octaveOffset = (key.octave - settings.startOctave) * 7 * keyWidth;
    final baseX = pattern[index]! * keyWidth + octaveOffset;

    final normalLeft = baseX - blackKeyWidth / 2;

    // 🟢 نت سیاه اصلی
    if (key.microTone == MicroToneType.normal) {
      return normalLeft;
    }

    // 🔵 سری → قبل از سیاه
    if (key.microTone == MicroToneType.sori) {
      return normalLeft - blackKeyWidth * 1;
    }

    // 🟣 کرن → بعد از سیاه
    if (key.microTone == MicroToneType.koron) {
      return normalLeft + blackKeyWidth * 1;
    }

    return normalLeft;
  }


  double _microToneTop(PianoKey key) {
    switch (key.microTone) {
      case MicroToneType.koron:
        return whiteKeyHeight - 180;
      case MicroToneType.sori:
        return whiteKeyHeight - 180;
      default:
        return 0;
    }
  }

  double _blackKeyWidthFor(PianoKey key) {
    return key.microTone == MicroToneType.normal
        ? blackKeyWidth
        : blackKeyWidth * 1;
  }

  double _blackKeyHeightFor(PianoKey key) {
    return key.microTone == MicroToneType.normal
        ? blackKeyHeight
        : blackKeyHeight * 0.75;
  }

  Color _microToneColor(PianoKey key, bool isDark) {
    switch (key.microTone) {
      case MicroToneType.koron:
        return AppColors.tuner_piano_keyboard_inactive_koron_key_color(isDark: isDark);
      case MicroToneType.sori:
        return AppColors.tuner_piano_keyboard_inactive_sori_key_color(isDark: isDark);
      default:
        return AppColors.tuner_piano_keyboard_inactive_black_key_color(isDark: isDark);
    }
  }
}
