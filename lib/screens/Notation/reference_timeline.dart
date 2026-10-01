import 'package:xml/xml.dart';

/// A position measured in quarter notes from the beginning of the score.
/// Seconds are derived from tempo changes and are never used as score positions.
class ReferenceNote {
  const ReferenceNote({
    required this.id,
    required this.measureIndex,
    required this.voice,
    required this.quarterPosition,
    required this.quarterDuration,
    required this.startSeconds,
    required this.durationSeconds,
    required this.isRest,
    required this.isAttack,
    required this.tieStart,
    required this.tieStop,
    this.midiPitch,
  });

  final String id;
  final int measureIndex;
  final String voice;
  final double quarterPosition;
  final double quarterDuration;
  final double startSeconds;
  final double durationSeconds;
  final bool isRest;
  final bool isAttack;
  final bool tieStart;
  final bool tieStop;

  /// Written MIDI pitch; fractional values preserve microtonal `alter`.
  final double? midiPitch;
  double get endSeconds => startSeconds + durationSeconds;
}

class ReferenceTempo {
  const ReferenceTempo(
    this.quarterPosition,
    this.quarterBpm,
    this.startSeconds,
  );
  final double quarterPosition;
  final double quarterBpm;
  final double startSeconds;
}

class ReferenceScore {
  const ReferenceScore({
    required this.title,
    required this.partId,
    required this.notes,
    required this.tempos,
    required this.durationQuarters,
    required this.durationSeconds,
  });
  final String title;
  final String partId;
  final List<ReferenceNote> notes;
  final List<ReferenceTempo> tempos;
  final double durationQuarters;
  final double durationSeconds;

  double secondsAt(double quarterPosition) {
    if (quarterPosition < 0 || quarterPosition > durationQuarters) {
      throw RangeError.value(quarterPosition, 'quarterPosition');
    }
    var active = tempos.first;
    for (final tempo in tempos.skip(1)) {
      if (tempo.quarterPosition > quarterPosition) break;
      active = tempo;
    }
    return active.startSeconds +
        (quarterPosition - active.quarterPosition) * 60 / active.quarterBpm;
  }
}

class ReferenceFormatException extends FormatException {
  const ReferenceFormatException(super.message);
}

class _RawNote {
  const _RawNote(
    this.id,
    this.measure,
    this.voice,
    this.position,
    this.duration,
    this.rest,
    this.pitch,
    this.tieStart,
    this.tieStop,
  );
  final String id, voice;
  final int measure;
  final double position, duration;
  final bool rest, tieStart, tieStop;
  final double? pitch;
}

class _TempoChange {
  const _TempoChange(this.position, this.bpm, this.order);
  final double position, bpm;
  final int order;
}

/// Parses the single-part, written-pitch subset used by the first analysis
/// reference. Unsupported structures fail explicitly rather than silently
/// producing a misleading alignment timeline.
class ReferenceTimelineParser {
  const ReferenceTimelineParser();

  ReferenceScore parse(String source) {
    final XmlDocument document;
    try {
      document = XmlDocument.parse(source);
    } on XmlException catch (error) {
      throw ReferenceFormatException('Invalid MusicXML: $error');
    }
    final root = document.rootElement;
    if (root.name.local != 'score-partwise') {
      throw const ReferenceFormatException(
        'Only score-partwise MusicXML is supported.',
      );
    }
    final parts = root.findElements('part').toList();
    if (parts.length != 1) {
      throw const ReferenceFormatException('Exactly one part is required.');
    }
    final part = parts.single;
    final measures = part.findElements('measure').toList();
    if (measures.isEmpty) {
      throw const ReferenceFormatException('MusicXML has no measures.');
    }
    final raw = <_RawNote>[];
    final changes = <_TempoChange>[_TempoChange(0, 120, -1)];
    var divisions = 0;
    var measureStart = 0.0;
    var measureCapacity = 0.0;
    var changeOrder = 0;
    var noteIndex = 0;
    for (var measureIndex = 0; measureIndex < measures.length; measureIndex++) {
      final measure = measures[measureIndex];
      var cursor = 0.0;
      var extent = 0.0;
      var lastOnset = 0.0;
      var hasPriorNote = false;
      for (final element in measure.children.whereType<XmlElement>()) {
        switch (element.name.local) {
          case 'attributes':
            final value = _child(element, 'divisions');
            if (value != null) {
              divisions = _positiveInt(value.innerText, 'divisions');
            }
            if (_child(element, 'transpose') != null) {
              throw const ReferenceFormatException(
                'Transposing parts are not supported.',
              );
            }
            final time = _child(element, 'time');
            if (time != null) {
              final beats = _positiveInt(
                _child(time, 'beats')?.innerText ?? '',
                'beats',
              );
              final beatType = _positiveInt(
                _child(time, 'beat-type')?.innerText ?? '',
                'beat-type',
              );
              measureCapacity = beats * 4 / beatType;
            }
          case 'direction':
            final sound = _child(element, 'sound');
            final soundTempo = sound?.getAttribute('tempo');
            final metronome = _child(
              _child(element, 'direction-type'),
              'metronome',
            );
            double? bpm;
            if (metronome != null) {
              final unit = _child(metronome, 'beat-unit')?.innerText.trim();
              final perMinute = _child(metronome, 'per-minute')?.innerText;
              if (unit == null || perMinute == null) {
                throw const ReferenceFormatException(
                  'Incomplete metronome direction.',
                );
              }
              final unitQuarters = _beatUnitQuarters(unit);
              final dots = metronome.findElements('beat-unit-dot').length;
              var multiplier = 1.0;
              var addition = 0.5;
              for (var i = 0; i < dots; i++) {
                multiplier += addition;
                addition /= 2;
              }
              bpm =
                  _positiveDouble(perMinute, 'per-minute') *
                  unitQuarters *
                  multiplier;
            }
            if (soundTempo != null) {
              final soundBpm = _positiveDouble(soundTempo, 'tempo');
              final rawMark = metronome == null
                  ? null
                  : double.tryParse(
                      _child(metronome, 'per-minute')?.innerText.trim() ?? '',
                    );
              // The bundled editor uses the displayed mark in sound/@tempo
              // even for dotted or non-quarter beats. Honor its beat unit.
              if (bpm == null ||
                  rawMark == null ||
                  (soundBpm - rawMark).abs() > 1e-9) {
                bpm = soundBpm;
              }
            }
            if (bpm != null) {
              final offset = _child(element, 'offset');
              final offsetQuarters = offset == null
                  ? 0.0
                  : _number(offset.innerText, 'direction offset') /
                        _requireDivisions(divisions);
              final position = measureStart + cursor + offsetQuarters;
              if (position < measureStart - 1e-9) {
                throw const ReferenceFormatException(
                  'Negative tempo position.',
                );
              }
              changes.add(_TempoChange(position, bpm, changeOrder++));
            }
          case 'backup':
            cursor -= _duration(element, divisions);
            if (cursor < -1e-9) {
              throw const ReferenceFormatException(
                'Backup precedes measure start.',
              );
            }
          case 'forward':
            cursor += _duration(element, divisions);
            if (cursor > extent) extent = cursor;
          case 'barline':
            if (element.descendants.whereType<XmlElement>().any(
              (e) => e.name.local == 'repeat' || e.name.local == 'ending',
            )) {
              throw const ReferenceFormatException(
                'Repeats and endings are not supported.',
              );
            }
          case 'note':
            final duration = _duration(element, divisions);
            final chord = _child(element, 'chord') != null;
            final position = chord ? lastOnset : cursor;
            if (chord && !hasPriorNote) {
              throw const ReferenceFormatException(
                'Chord has no preceding note.',
              );
            }
            final rest = _child(element, 'rest') != null;
            final pitch = rest ? null : _pitch(element);
            final ties = element
                .findElements('tie')
                .map((tie) => tie.getAttribute('type'))
                .toSet();
            final voice = _child(element, 'voice')?.innerText.trim() ?? '1';
            final id =
                '${part.getAttribute('id') ?? 'P1'}:$measureIndex:${noteIndex++}';
            raw.add(
              _RawNote(
                id,
                measureIndex,
                voice,
                measureStart + position,
                duration,
                rest,
                pitch,
                ties.contains('start'),
                ties.contains('stop'),
              ),
            );
            hasPriorNote = true;
            if (!chord) {
              lastOnset = cursor;
              cursor += duration;
            }
            if (position + duration > extent) extent = position + duration;
        }
      }
      if (measureCapacity > 0 && extent > measureCapacity + 1e-9) {
        throw const ReferenceFormatException(
          'Measure exceeds its time signature.',
        );
      }
      final implicit = measure.getAttribute('implicit') == 'yes';
      measureStart += implicit
          ? extent
          : (measureCapacity > extent ? measureCapacity : extent);
    }
    changes.sort((a, b) {
      final position = a.position.compareTo(b.position);
      return position != 0 ? position : a.order.compareTo(b.order);
    });
    final tempos = <ReferenceTempo>[];
    for (final change in changes) {
      if (change.position > measureStart + 1e-9) {
        throw const ReferenceFormatException(
          'Tempo change exceeds score duration.',
        );
      }
      final previous = tempos.isEmpty ? null : tempos.last;
      final seconds = previous == null
          ? 0.0
          : previous.startSeconds +
                (change.position - previous.quarterPosition) *
                    60 /
                    previous.quarterBpm;
      if (previous != null &&
          (previous.quarterPosition - change.position).abs() < 1e-9) {
        tempos.removeLast();
      }
      tempos.add(ReferenceTempo(change.position, change.bpm, seconds));
    }
    double at(double position) {
      var active = tempos.first;
      for (final tempo in tempos.skip(1)) {
        if (tempo.quarterPosition > position) break;
        active = tempo;
      }
      return active.startSeconds +
          (position - active.quarterPosition) * 60 / active.quarterBpm;
    }

    final notes = raw
        .map(
          (note) => ReferenceNote(
            id: note.id,
            measureIndex: note.measure,
            voice: note.voice,
            quarterPosition: note.position,
            quarterDuration: note.duration,
            startSeconds: at(note.position),
            durationSeconds:
                at(note.position + note.duration) - at(note.position),
            isRest: note.rest,
            isAttack: !note.rest && !note.tieStop,
            tieStart: note.tieStart,
            tieStop: note.tieStop,
            midiPitch: note.pitch,
          ),
        )
        .toList(growable: false);
    return ReferenceScore(
      title: _child(root, 'work') == null
          ? (_child(root, 'movement-title')?.innerText.trim() ?? '')
          : (_child(_child(root, 'work'), 'work-title')?.innerText.trim() ??
                ''),
      partId: part.getAttribute('id') ?? 'P1',
      notes: List.unmodifiable(notes),
      tempos: List.unmodifiable(tempos),
      durationQuarters: measureStart,
      durationSeconds: at(measureStart),
    );
  }

  static XmlElement? _child(XmlElement? parent, String name) =>
      parent?.findElements(name).firstOrNull;
  static double _number(String value, String field) {
    final number = double.tryParse(value.trim());
    if (number == null || !number.isFinite) {
      throw ReferenceFormatException('Invalid $field.');
    }
    return number;
  }

  static double _positiveDouble(String value, String field) {
    final number = _number(value, field);
    if (number <= 0) throw ReferenceFormatException('Invalid $field.');
    return number;
  }

  static int _positiveInt(String value, String field) {
    final number = int.tryParse(value.trim());
    if (number == null || number <= 0) {
      throw ReferenceFormatException('Invalid $field.');
    }
    return number;
  }

  static int _requireDivisions(int divisions) {
    if (divisions <= 0) {
      throw const ReferenceFormatException(
        'Missing divisions before durations.',
      );
    }
    return divisions;
  }

  static double _duration(XmlElement element, int divisions) {
    final value = _child(element, 'duration')?.innerText;
    if (value == null) {
      throw const ReferenceFormatException('Missing note or cursor duration.');
    }
    final duration =
        _positiveDouble(value, 'duration') / _requireDivisions(divisions);
    return duration;
  }

  static double _pitch(XmlElement note) {
    final pitch = _child(note, 'pitch');
    final step = _child(pitch, 'step')?.innerText.trim().toUpperCase();
    final octave = int.tryParse(
      _child(pitch, 'octave')?.innerText.trim() ?? '',
    );
    const semitones = {'C': 0, 'D': 2, 'E': 4, 'F': 5, 'G': 7, 'A': 9, 'B': 11};
    if (step == null ||
        !semitones.containsKey(step) ||
        octave == null ||
        octave < -1 ||
        octave > 9) {
      throw const ReferenceFormatException('Invalid written pitch.');
    }
    final alterText = _child(pitch, 'alter')?.innerText;
    final alter = alterText == null ? 0.0 : _number(alterText, 'alter');
    return (octave + 1) * 12 + semitones[step]! + alter;
  }

  static double _beatUnitQuarters(String unit) => switch (unit) {
    'whole' => 4,
    'half' => 2,
    'quarter' => 1,
    'eighth' => 0.5,
    '16th' => 0.25,
    '32nd' => 0.125,
    '64th' => 0.0625,
    _ => throw const ReferenceFormatException(
      'Unsupported metronome beat unit.',
    ),
  };
}
