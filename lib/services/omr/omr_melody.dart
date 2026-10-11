class OmrDraftNote {
  OmrDraftNote({
    required this.x,
    required this.pitch,
    this.duration,
    this.staffStep,
  });
  final int x;
  final int? staffStep;
  bool editedPitch = false;
  String? pitch;
  String? duration;
}

class OmrMelody {
  static const wholeUnits = 967680;
  static const durations = <String, int>{
    'w': wholeUnits,
    'h': wholeUnits ~/ 2,
    'q': wholeUnits ~/ 4,
    '8': wholeUnits ~/ 8,
    '16': wholeUnits ~/ 16,
  };
  static const pitchNames = [
    'C',
    'C#',
    'D',
    'Eb',
    'E',
    'F',
    'F#',
    'G',
    'Ab',
    'A',
    'Bb',
    'B',
  ];
  static const _trebleSteps = [64, 65, 67, 69, 71, 72, 74, 76, 77, 79, 81, 83];
  static const _bassSteps = [43, 45, 47, 48, 50, 52, 53, 55, 57, 59, 60, 62];

  static String? pitchForStep(String clef, int? step) {
    if (step == null || step < 0 || step >= _trebleSteps.length) return null;
    return midiPitch((clef == 'bass' ? _bassSteps : _trebleSteps)[step]);
  }

  static String? midiPitch(int? midi) {
    if (midi == null || midi < 21 || midi > 108) return null;
    final name = pitchNames[midi % 12];
    return '$name${midi ~/ 12 - 1}';
  }

  static List<OmrDraftNote> fromProbe(Map<String, Object?> result) {
    final staffs = result['staffs'] as List<dynamic>? ?? [];
    if (staffs.length != 1) {
      throw const FormatException('Exactly one staff is required.');
    }
    final staff = staffs.single as Map<String, dynamic>;
    final notes = (staff['notes'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
    if (notes.isEmpty) throw const FormatException('No noteheads found.');
    if (notes.length > 128) throw const FormatException('Too many notes.');
    final draft = <OmrDraftNote>[
      for (final note in notes)
        OmrDraftNote(
          x: (note['x'] as num).round(),
          pitch: midiPitch(note['midi'] as int?),
          staffStep: note['staffStep'] as int?,
        ),
    ];
    draft.sort((a, b) => a.x.compareTo(b.x));
    return draft;
  }

  static Map<String, Object?> toImport({
    required List<OmrDraftNote> notes,
    required String clef,
    required int numerator,
    required int denominator,
    required String title,
  }) {
    if (notes.isEmpty ||
        notes.length > 128 ||
        !['treble', 'bass'].contains(clef) ||
        numerator < 1 ||
        numerator > 32 ||
        ![2, 4, 8, 16].contains(denominator)) {
      throw const FormatException('Invalid melody settings.');
    }
    final capacity = wholeUnits * numerator ~/ denominator;
    final measures = <Map<String, Object?>>[];
    var current = <Map<String, Object?>>[];
    var at = 0;
    for (final note in notes) {
      final duration = durations[note.duration];
      final match = RegExp(
        r'^([A-G])([#b]?)([0-8])$',
      ).firstMatch(note.pitch ?? '');
      if (match == null || duration == null || duration > capacity) {
        throw const FormatException('Confirm every pitch and duration.');
      }
      final natural = '${match.group(1)}${match.group(3)}';
      if (!RegExp(r'^(?:[A-G][1-7]|[AB]0|C8)$').hasMatch(natural)) {
        throw const FormatException('Confirm every pitch and duration.');
      }
      if (at + duration > capacity) {
        if (at != capacity)
          throw const FormatException(
            'A note crosses a measure boundary. Adjust its duration.',
          );
        measures.add({'notes': current, 'preserve': true});
        if (measures.length >= 64)
          throw const FormatException('Too many measures.');
        current = <Map<String, Object?>>[];
        at = 0;
      }
      current.add({
        'pitch': natural,
        'accidental': match.group(2) ?? '',
        'duration': note.duration,
        'dots': 0,
        'staff': 1,
        'voice': 1,
        'at': at,
      });
      at += duration;
    }
    if (at != capacity)
      throw const FormatException(
        'The last measure is incomplete. Adjust note durations or time signature.',
      );
    measures.add({'notes': current, 'preserve': true});
    return {
      'format': 'sornaz-notation',
      'version': 1,
      'metadata': {
        'title': title.trim().isEmpty ? 'Scanned melody' : title.trim(),
        'instrument': 'Voice',
        'staves': [
          {'clef': clef},
        ],
        'clef': clef,
        'key': 'C',
        'time': '$numerator/$denominator',
        'bpm': 100,
        'tempo_note': 'q',
        'tempo_dots': 0,
      },
      'score': {'measures': measures},
    };
  }
}
