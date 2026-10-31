import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:sornaz/screens/MusicPractice/practice_journey.dart';

Map<String, dynamic> level(
  int id, {
  int stages = 5,
  int version = 1,
  int? position,
}) => {
  'id': id,
  'position': position ?? id,
  'version': version,
  'stageCount': stages,
};
Map<String, dynamic> done(int id, List<int> stages, {int version = 1}) => {
  'examId': id,
  'version': version,
  'completedStages': stages,
};
void main() {
  test('all 180 levels finish a round before any second-star level starts', () {
    final exams = List.generate(180, (i) => level(i + 1));
    final progress = <Map<String, dynamic>>[];
    for (var round = 1; round <= 5; round++) {
      for (var id = 1; id <= 180; id++) {
        final plan = PracticeJourney(exams, progress), next = plan.next!;
        expect(next.exam['id'], id);
        expect(plan.currentLevel, id);
        expect(next.stage, round);
        expect(plan.stars, round - 1);
        progress.add(done(id, [round]));
      }
      expect(PracticeJourney(exams, progress).stars, round);
    }
    expect(PracticeJourney(exams, progress).next, isNull);
    expect(PracticeJourney(exams, progress).currentLevel, 180);
  });
  test(
    'reopening persisted progress resumes first unfinished level, not last fully starred level',
    () {
      final saved =
          jsonDecode(
                jsonEncode([
                  done(1, [1, 2, 3, 4, 5]),
                  done(2, [1]),
                  done(3, []),
                ]),
              )
              as List;
      final plan = PracticeJourney([
        level(3),
        level(2),
        level(1),
      ], saved.map((p) => Map<String, dynamic>.from(p as Map)));
      expect(plan.next!.exam['id'], 3);
      expect(plan.next!.stage, 1);
      expect(plan.stars, 0);
    },
  );
  test('server position and revised definitions determine continuation', () {
    final plan = PracticeJourney(
      [level(1, position: 20, version: 2), level(2, position: 10)],
      [
        done(1, [1, 2, 3, 4, 5]),
        done(2, [1]),
      ],
    );
    expect(plan.next!.exam['id'], 1);
    expect(plan.next!.stage, 1);
    expect(plan.stars, 0);
  });
  test(
    'variable stage counts and duplicate local/server records retain correct group stars',
    () {
      final exams = [level(1, stages: 1), level(2, stages: 3)];
      final progress = [
        done(1, [1]),
        done(2, [1]),
        done(2, [1]),
      ];
      var plan = PracticeJourney(exams, progress);
      expect(plan.stars, 1);
      expect(plan.next!.exam['id'], 2);
      expect(plan.next!.stage, 2);
      progress.add(done(2, [2]));
      plan = PracticeJourney(exams, progress);
      expect(plan.stars, 3);
      progress.add(done(2, [3]));
      plan = PracticeJourney(exams, progress);
      expect(plan.stars, 5);
      expect(plan.next, isNull);
    },
  );
  test(
    'unfilled prerequisite stages cannot be skipped by a later stage record',
    () {
      final plan = PracticeJourney(
        [level(1), level(2)],
        [
          done(1, [1, 3]),
          done(2, [1, 2]),
        ],
      );
      expect(plan.next!.exam['id'], 1);
      expect(plan.next!.stage, 2);
      expect(plan.stars, 1);
      expect(PracticeJourney([], []).stars, 0);
    },
  );
}
