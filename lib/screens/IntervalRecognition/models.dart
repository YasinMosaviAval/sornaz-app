import 'dart:math';

/// Language-independent, enharmonically combined interval categories.
enum MusicalInterval {
  minorSecond(1),
  majorSecond(2),
  minorThird(3),
  majorThird(4),
  perfectFourth(5),
  tritone(6),
  perfectFifth(7),
  augmentedFifth(8),
  majorSixth(9),
  minorSeventh(10),
  majorSeventh(11),
  perfectOctave(12);

  const MusicalInterval(this.semitones);
  final int semitones;
  String get translationKey => 'interval.$name';
}

enum IntervalDirection { ascending, descending }

class IntervalLevel {
  const IntervalLevel(
    this.number,
    this.intervals,
    this.direction,
    this.variableRoot,
  );
  final int number;
  final List<MusicalInterval> intervals;
  final IntervalDirection direction;
  final bool variableRoot;
  static const requiredWins = 10;
  static const middleC = 60;
  static const pianoMinimum = 21;
  static const pianoMaximum = 108;
  static const _groups = [
    [MusicalInterval.perfectFifth, MusicalInterval.perfectOctave],
    [
      MusicalInterval.minorThird,
      MusicalInterval.majorThird,
      MusicalInterval.perfectFifth,
      MusicalInterval.perfectOctave,
    ],
    [
      MusicalInterval.majorSecond,
      MusicalInterval.perfectFourth,
      MusicalInterval.majorSixth,
      MusicalInterval.majorSeventh,
    ],
    [
      MusicalInterval.minorSecond,
      MusicalInterval.tritone,
      MusicalInterval.augmentedFifth,
      MusicalInterval.minorSeventh,
    ],
    MusicalInterval.values,
  ];
  static final List<IntervalLevel> all = List.unmodifiable(
    List.generate(
      20,
      (i) => IntervalLevel(
        i + 1,
        _groups[i ~/ 4],
        i.isEven ? IntervalDirection.ascending : IntervalDirection.descending,
        i % 4 >= 2,
      ),
    ),
  );
}

class IntervalQuestion {
  const IntervalQuestion({
    required this.id,
    required this.level,
    required this.interval,
    required this.rootMidi,
    required this.targetMidi,
    required this.direction,
  });
  final int id;
  final int level;
  final MusicalInterval interval;
  int get semitones => interval.semitones;
  final int rootMidi;
  final int targetMidi;
  final IntervalDirection direction;
}

/// Each question independently samples the complete allowed interval set.
class IntervalQuestionGenerator {
  IntervalQuestionGenerator({Random? random}) : _random = random ?? Random();
  final Random _random;
  int _id = 0;

  IntervalQuestion generate(IntervalLevel level) {
    final interval = level.intervals[_random.nextInt(level.intervals.length)];
    final ascending = level.direction == IntervalDirection.ascending;
    final min =
        IntervalLevel.pianoMinimum + (ascending ? 0 : interval.semitones);
    final max =
        IntervalLevel.pianoMaximum - (ascending ? interval.semitones : 0);
    final root = level.variableRoot
        ? min + _random.nextInt(max - min + 1)
        : IntervalLevel.middleC;
    final target =
        root + (ascending ? interval.semitones : -interval.semitones);
    if (root < 21 || root > 108 || target < 21 || target > 108) {
      throw StateError('Invalid piano range');
    }
    return IntervalQuestion(
      id: ++_id,
      level: level.number,
      interval: interval,
      rootMidi: root,
      targetMidi: target,
      direction: level.direction,
    );
  }
}
