import 'models.dart';

/// Exact equal-tempered quarter steps, independent of traditional variable tunings.
enum IranianInterval implements TrainingInterval {
  raisedUnison(1),
  minorSecond(2),
  loweredMajorSecond(3),
  majorSecond(4),
  raisedMajorSecond(5),
  minorThird(6),
  neutralThird(7),
  majorThird(8),
  raisedMajorThird(9),
  perfectFourth(10),
  raisedPerfectFourth(11),
  tritone(12),
  raisedAugmentedFourth(13),
  perfectFifth(14),
  raisedPerfectFifth(15),
  minorSixth(16),
  neutralSixth(17),
  majorSixth(18),
  raisedMajorSixth(19),
  minorSeventh(20),
  neutralSeventh(21),
  majorSeventh(22),
  raisedMajorSeventh(23),
  perfectOctave(24);

  const IranianInterval(this.quarterSteps);
  @override
  final int quarterSteps;
  int get number => quarterSteps;
  @override
  double get semitones => quarterSteps / 2;
  @override
  String get id => 'iranian.$name';
  @override
  String get translationKey => 'interval.$id';
}

class IranianCurriculum {
  static final List<List<TrainingInterval>> stages = List.unmodifiable([
    List<TrainingInterval>.unmodifiable(IranianInterval.values.take(2)),
    for (var introduced = 3; introduced <= 24; introduced++) ...[
      List<TrainingInterval>.unmodifiable(
        IranianInterval.values.sublist(introduced - 2, introduced),
      ),
      List<TrainingInterval>.unmodifiable(
        IranianInterval.values.take(introduced),
      ),
    ],
  ]);
  static final List<IntervalLevel> levels = List.unmodifiable(
    List.generate(
      180,
      (i) => IntervalLevel(
        i + 1,
        stages[i ~/ 4],
        i.isEven ? IntervalDirection.ascending : IntervalDirection.descending,
        i % 4 >= 2,
        music: IntervalMusic.iranian,
      ),
    ),
  );
}
