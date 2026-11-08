import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:sornaz/helpers/app_typography.dart';
import 'music_accidental_glyph.dart';
import 'piano_keyboard_spec.dart';

enum PianoPointerPhase { down, move, up, cancel }

@immutable
class AppPianoKey {
  const AppPianoKey(this.midi, this.accidental);
  final int midi;
  final String accidental;
  static const names = [
    'C',
    'C#',
    'D',
    'D#',
    'E',
    'F',
    'F#',
    'G',
    'G#',
    'A',
    'A#',
    'B',
  ];
  String get name =>
      names[(midi + (accidental == 'b' ? 1 : 0)) % 12].replaceAll('#', '');
  int get octave => midi ~/ 12 - 1;
  String get pitch => '$name$octave';
  String get id => '$pitch:$accidental';
  bool get isQuarter => accidental == 'k' || accidental == 'o';
  bool get isWhite => accidental.isEmpty;
  double frequency([double a4 = 440]) =>
      a4 *
      math.pow(
        2,
        (midi -
                69 +
                (accidental == 'k'
                    ? -.5
                    : accidental == 'o'
                    ? .5
                    : 0)) /
            12,
      );
}

typedef PianoPointerCallback =
    void Function(AppPianoKey key, PianoPointerPhase phase, Offset movement);

/// Shared presentation and gestures; audio and score mutations stay with callers.
class AppPianoKeyboard extends StatefulWidget {
  const AppPianoKeyboard({
    super.key,
    required this.firstMidi,
    required this.lastMidi,
    required this.showQuarterTones,
    required this.onPointer,
    this.a4 = 440,
    this.initialMidi,
    this.highlightA4 = false,
    this.showWhiteFrequencies = false,
    this.showBlackFrequencies = false,
    this.showOctave = false,
    this.labelFor,
    this.enabled = true,
    this.selectedKeyId,
  });
  final int firstMidi, lastMidi;
  final bool showQuarterTones,
      highlightA4,
      showWhiteFrequencies,
      showBlackFrequencies,
      showOctave,
      enabled;
  final double a4;
  final int? initialMidi;
  final String? selectedKeyId;
  final String Function(AppPianoKey)? labelFor;
  final PianoPointerCallback onPointer;
  @override
  State<AppPianoKeyboard> createState() => _AppPianoKeyboardState();
}

class _PianoPress {
  _PianoPress(this.key, this.origin);
  final AppPianoKey key;
  final Offset origin;
  bool cancelled = false;
}

class _AppPianoKeyboardState extends State<AppPianoKeyboard> {
  final _scroll = ScrollController();
  final _presses = <int, _PianoPress>{};
  bool _positioned = false;
  double get _width => widget.showQuarterTones
      ? PianoKeyboardSpec.iranianWhiteWidth
      : PianoKeyboardSpec.whiteWidth;
  @override
  void didUpdateWidget(covariant AppPianoKeyboard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.firstMidi != oldWidget.firstMidi ||
        widget.lastMidi != oldWidget.lastMidi ||
        (!widget.enabled && oldWidget.enabled) ||
        widget.showQuarterTones != oldWidget.showQuarterTones) {
      for (final press in _presses.values.where((p) => !p.cancelled)) {
        oldWidget.onPointer(press.key, PianoPointerPhase.cancel, Offset.zero);
      }
      _presses.clear();
    }
    if (widget.showQuarterTones != oldWidget.showQuarterTones &&
        _scroll.hasClients) {
      final oldWidth = oldWidget.showQuarterTones
          ? PianoKeyboardSpec.iranianWhiteWidth
          : PianoKeyboardSpec.whiteWidth;
      final center =
          (_scroll.offset + _scroll.position.viewportDimension / 2) / oldWidth;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _scroll.hasClients) {
          _scroll.jumpTo(
            (center * _width - _scroll.position.viewportDimension / 2).clamp(
              0,
              _scroll.position.maxScrollExtent,
            ),
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Widget _key(
    BuildContext context,
    AppPianoKey key,
    double width,
    double height,
  ) {
    final active =
        widget.selectedKeyId == key.id ||
        _presses.values.any((p) => !p.cancelled && p.key.id == key.id);
    final color = active
        ? Theme.of(context).colorScheme.primary
        : key.isWhite
        ? (widget.highlightA4 && key.midi == 69
              ? Colors.lightBlueAccent
              : const Color(PianoKeyboardSpec.whiteColor))
        : Color(
            key.accidental == 'k'
                ? PianoKeyboardSpec.koronColor
                : key.accidental == 'o'
                ? PianoKeyboardSpec.soriColor
                : PianoKeyboardSpec.blackColor,
          );
    final label =
        widget.labelFor?.call(key) ??
        '${key.name}${key.accidental == '#'
            ? '#'
            : key.accidental == 'b'
            ? '♭'
            : ''}${widget.showOctave ? key.octave : ''}';
    final style = AppTypography.pianoKeyboardWhiteKeyLabel(context).copyWith(
      color: key.isWhite || key.isQuarter ? Colors.black : Colors.white,
    );
    final frequencies = key.isWhite
        ? widget.showWhiteFrequencies
        : widget.showBlackFrequencies;
    final fa = Localizations.maybeLocaleOf(context)?.languageCode == 'fa';
    final signName = switch (key.accidental) {
      'o' => fa ? 'سُری' : 'sori',
      'k' => fa ? 'کُرُن' : 'koron',
      '#' => fa ? 'دیز' : 'sharp',
      'b' => fa ? 'بمل' : 'flat',
      _ => '',
    };
    final shape = Theme.of(context).inputDecorationTheme.border;
    final radius = shape is OutlineInputBorder
        ? shape.borderRadius.bottomLeft.x
        : 4.0;
    return Semantics(
      button: true,
      enabled: widget.enabled,
      label: '${key.pitch} $signName',
      onTap: widget.enabled
          ? () {
              widget.onPointer(key, PianoPointerPhase.down, Offset.zero);
              widget.onPointer(key, PianoPointerPhase.up, Offset.zero);
            }
          : null,
      child: Listener(
        onPointerDown: (e) {
          if (!widget.enabled || e.buttons != 1) return;
          setState(() => _presses[e.pointer] = _PianoPress(key, e.position));
          widget.onPointer(key, PianoPointerPhase.down, Offset.zero);
        },
        onPointerMove: (e) {
          final press = _presses[e.pointer];
          if (press == null || press.cancelled) return;
          final delta = e.position - press.origin;
          if (delta.dx.abs() > 8 && delta.dx.abs() > delta.dy.abs()) {
            setState(() => press.cancelled = true);
            widget.onPointer(key, PianoPointerPhase.cancel, delta);
          } else {
            widget.onPointer(key, PianoPointerPhase.move, delta);
          }
        },
        onPointerUp: (e) {
          final press = _presses.remove(e.pointer);
          if (press == null) return;
          setState(() {});
          if (!press.cancelled) {
            widget.onPointer(
              key,
              PianoPointerPhase.up,
              e.position - press.origin,
            );
          }
        },
        onPointerCancel: (e) {
          final press = _presses.remove(e.pointer);
          if (press == null) return;
          setState(() {});
          if (!press.cancelled) {
            widget.onPointer(
              key,
              PianoPointerPhase.cancel,
              e.position - press.origin,
            );
          }
        },
        child: Container(
          key: ValueKey('piano-${key.id}'),
          width: width,
          height: height,
          alignment: Alignment.bottomCenter,
          decoration: BoxDecoration(
            color: color,
            border: key.isWhite
                ? Border.all(width: .5, color: Colors.black)
                : key.accidental == '#'
                ? const Border(bottom: BorderSide(color: Color(0xff555555)))
                : null,
            borderRadius: key.isWhite
                ? null
                : BorderRadius.vertical(
                    bottom: Radius.circular(radius),
                  ),
          ),
          padding: const EdgeInsets.only(bottom: 4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(label, style: style),
                  if (key.isQuarter)
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: MusicAccidentalGlyph(
                          accidental: key.accidental,
                          size: 18,
                          color: Colors.black,
                        ),
                      ),
                    ),
                ],
              ),
              if (frequencies)
                Text(
                  key.frequency(widget.a4).toStringAsFixed(2),
                  style: AppTypography.pianoKeyboardWhiteKeyFrequency(context)
                      .copyWith(
                        color: key.isWhite || key.isQuarter
                            ? Colors.black
                            : Colors.white,
                      ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _blackKey(BuildContext context, int midi) => SizedBox(
    key: ValueKey('piano-black-${AppPianoKey(midi, '#').pitch}'),
    width: PianoKeyboardSpec.blackWidth,
    height: PianoKeyboardSpec.blackHeight,
    child: ColoredBox(
      color: const Color(PianoKeyboardSpec.blackColor),
      child: Column(
        children: [
          _key(
            context,
            AppPianoKey(midi, '#'),
            PianoKeyboardSpec.blackWidth,
            PianoKeyboardSpec.blackHeight / 2,
          ),
          _key(
            context,
            AppPianoKey(midi, 'b'),
            PianoKeyboardSpec.blackWidth,
            PianoKeyboardSpec.blackHeight / 2,
          ),
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final whites = <int>[];
    for (var midi = widget.firstMidi; midi <= widget.lastMidi; midi++) {
      if (!AppPianoKey.names[midi % 12].contains('#')) whites.add(midi);
    }
    if (!_positioned) {
      _positioned = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_scroll.hasClients || widget.initialMidi == null) {
          return;
        }
        final at = whites.indexWhere((m) => m >= widget.initialMidi!);
        _scroll.jumpTo(
          (at * _width - _scroll.position.viewportDimension / 2).clamp(
            0,
            _scroll.position.maxScrollExtent,
          ),
        );
      });
    }
    return Directionality(
      textDirection: TextDirection.ltr,
      child: SizedBox(
        height: PianoKeyboardSpec.whiteHeight,
        child: SingleChildScrollView(
          controller: _scroll,
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: whites.length * _width,
            height: PianoKeyboardSpec.whiteHeight,
            child: Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                Row(
                  children: whites
                      .map(
                        (m) => _key(
                          context,
                          AppPianoKey(m, ''),
                          _width,
                          PianoKeyboardSpec.whiteHeight,
                        ),
                      )
                      .toList(),
                ),
                for (var i = 0; i < whites.length; i++) ...[
                  if (![4, 11].contains(whites[i] % 12) &&
                      whites[i] < widget.lastMidi)
                    Positioned(
                      left: (i + 1) * _width - PianoKeyboardSpec.blackWidth / 2,
                      top: 0,
                      child: _blackKey(context, whites[i] + 1),
                    ),
                  if (widget.showQuarterTones && whites[i] < widget.lastMidi)
                    Positioned(
                      left:
                          (i + ([4, 11].contains(whites[i] % 12) ? 1 : .5)) *
                              _width -
                          ([4, 11].contains(whites[i] % 12)
                              ? PianoKeyboardSpec.blackWidth / 2
                              : 0),
                      top: 0,
                      child: _key(
                        context,
                        AppPianoKey(whites[i], 'o'),
                        PianoKeyboardSpec.blackWidth,
                        PianoKeyboardSpec.quarterHeight,
                      ),
                    ),
                  if (widget.showQuarterTones &&
                      ![0, 5].contains(whites[i] % 12) &&
                      whites[i] > widget.firstMidi)
                    Positioned(
                      left: i * _width + PianoKeyboardSpec.blackWidth / 2,
                      top: 0,
                      child: _key(
                        context,
                        AppPianoKey(whites[i], 'k'),
                        PianoKeyboardSpec.blackWidth,
                        PianoKeyboardSpec.quarterHeight,
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
