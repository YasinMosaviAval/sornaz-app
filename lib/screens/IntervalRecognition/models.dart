import 'dart:math';
import 'iranian_curriculum.dart';

enum IntervalMusic {
  western,
  iranian;

  int get levelCount => this == western ? 44 : 180;
  String get finalMessageKey =>
      this == western ? 'interval.finished' : 'interval.iranianFinished';
}

abstract interface class TrainingInterval {
  String get id;
  String get translationKey;
  int get quarterSteps;
  num get semitones;
}

/// Language-independent, enharmonically combined interval categories.
enum MusicalInterval implements TrainingInterval {
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
  @override
  final int semitones;
  @override
  int get quarterSteps => semitones * 2;
  @override
  String get id => name;
  @override
  String get translationKey => 'interval.$name';
}

enum IntervalDirection { ascending, descending }

class IntervalLevel {
  const IntervalLevel(
    this.number,
    this.intervals,
    this.direction,
    this.variableRoot, {
    this.music = IntervalMusic.western,
  });
  final int number;
  final List<TrainingInterval> intervals;
  final IntervalMusic music;
  final IntervalDirection direction;
  final bool variableRoot;
  static const requiredWins = 10;
  static const middleC = 60;
  static const pianoMinimum = 21;
  static const pianoMaximum = 108;
  static const levelCount = 44;
  static List<IntervalLevel> levelsFor(IntervalMusic music) =>
      music == IntervalMusic.western ? all : IranianCurriculum.levels;
  static const _groups = [
    [MusicalInterval.perfectFifth, MusicalInterval.perfectOctave],
    [MusicalInterval.minorThird, MusicalInterval.majorThird],
    [
      MusicalInterval.minorThird,
      MusicalInterval.majorThird,
      MusicalInterval.perfectFifth,
      MusicalInterval.perfectOctave,
    ],
    [MusicalInterval.majorSecond, MusicalInterval.perfectFourth],
    [
      MusicalInterval.majorSecond,
      MusicalInterval.minorThird,
      MusicalInterval.majorThird,
      MusicalInterval.perfectFourth,
      MusicalInterval.perfectFifth,
      MusicalInterval.perfectOctave,
    ],
    [MusicalInterval.majorSixth, MusicalInterval.majorSeventh],
    [
      MusicalInterval.majorSecond,
      MusicalInterval.minorThird,
      MusicalInterval.majorThird,
      MusicalInterval.perfectFourth,
      MusicalInterval.perfectFifth,
      MusicalInterval.majorSixth,
      MusicalInterval.majorSeventh,
      MusicalInterval.perfectOctave,
    ],
    [MusicalInterval.minorSecond, MusicalInterval.minorSeventh],
    [
      MusicalInterval.minorSecond,
      MusicalInterval.majorSecond,
      MusicalInterval.minorThird,
      MusicalInterval.majorThird,
      MusicalInterval.perfectFourth,
      MusicalInterval.perfectFifth,
      MusicalInterval.majorSixth,
      MusicalInterval.minorSeventh,
      MusicalInterval.majorSeventh,
      MusicalInterval.perfectOctave,
    ],
    [MusicalInterval.tritone, MusicalInterval.augmentedFifth],
    MusicalInterval.values,
  ];
  static final List<IntervalLevel> all = List.unmodifiable(
    List.generate(
      levelCount,
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
  final TrainingInterval interval;
  num get semitones => interval.semitones;
  int get quarterSteps => interval.quarterSteps;
  final int rootMidi;
  final num targetMidi;
  double get rootFrequency => 440.0 * pow(2, (rootMidi - 69) / 12);
  double get targetFrequency => 440.0 * pow(2, (targetMidi - 69) / 12);
  final IntervalDirection direction;
}

/// Each question independently samples the complete allowed interval set.
class IntervalQuestionGenerator {
  IntervalQuestionGenerator({Random? random}) : _random = random ?? Random();
  final Random _random;
  int _id = 0;

  IntervalQuestion generate(
    IntervalLevel level, {
    int startingMidi = IntervalLevel.middleC,
  }) {
    if (startingMidi < 48 || startingMidi > 72) {
      throw ArgumentError.value(startingMidi, 'startingMidi');
    }
    final interval = level.intervals[_random.nextInt(level.intervals.length)];
    final ascending = level.direction == IntervalDirection.ascending;
    final min =
        (IntervalLevel.pianoMinimum + (ascending ? 0 : interval.semitones))
            .ceil();
    final max =
        (IntervalLevel.pianoMaximum - (ascending ? interval.semitones : 0))
            .floor();
    final root = level.variableRoot
        ? min + _random.nextInt(max - min + 1)
        : startingMidi;
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
