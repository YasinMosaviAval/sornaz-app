typedef JourneyJson = Map<String, dynamic>;

class PracticeJourneyStep {
  const PracticeJourneyStep(this.exam, this.stage);
  final JourneyJson exam;
  final int stage;
}

/// Each round visits every server-ordered level before the next round starts.
/// Progress is keyed by definition version; old answers are never rewritten.
class PracticeJourney {
  PracticeJourney(Iterable<JourneyJson> exams, Iterable<JourneyJson> progress)
    : exams = exams.toList() {
    this.exams.sort((a, b) {
      final position = (a['position'] as int? ?? 0).compareTo(
        b['position'] as int? ?? 0,
      );
      return position != 0
          ? position
          : (a['id'] as int).compareTo(b['id'] as int);
    });
    for (final row in progress) {
      completed
          .putIfAbsent('${row['examId']}:${row['version']}', () => {})
          .addAll(List<int>.from(row['completedStages'] as List? ?? []));
    }
  }
  final List<JourneyJson> exams;
  final completed = <String, Set<int>>{};
  int get rounds => exams.fold(
    0,
    (count, e) =>
        (e['stageCount'] as int) > count ? e['stageCount'] as int : count,
  );
  bool hasPassed(JourneyJson exam, int stage) =>
      completed['${exam['id']}:${exam['version']}']?.contains(stage) ?? false;
  PracticeJourneyStep? get next {
    for (var stage = 1; stage <= rounds; stage++) {
      for (final exam in exams) {
        if (stage <= (exam['stageCount'] as int) && !hasPassed(exam, stage)) {
          return PracticeJourneyStep(exam, stage);
        }
      }
    }
    return null;
  }

  int get completedRounds {
    for (var stage = 1; stage <= rounds; stage++) {
      if (exams.any(
        (e) => stage <= (e['stageCount'] as int) && !hasPassed(e, stage),
      )) {
        return stage - 1;
      }
    }
    return rounds;
  }

  int get stars =>
      rounds == 0 ? 0 : (completedRounds * 5 ~/ rounds).clamp(0, 5);
  int get currentLevel {
    final step = next;
    if (step == null) return exams.length;
    return exams.indexWhere(
          (e) =>
              e['id'] == step.exam['id'] &&
              e['version'] == step.exam['version'],
        ) +
        1;
  }
}
