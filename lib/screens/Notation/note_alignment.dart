import 'performed_notes.dart';
import 'reference_timeline.dart';

enum AlignmentMark { matched, wrongNote, missed, extra }

class AlignedNote {
  const AlignedNote(this.mark, this.reference, this.performed);
  final AlignmentMark mark;
  final ReferenceNote? reference;
  final PerformedNote? performed;
}

class NoteAlignment {
  const NoteAlignment(
    this.events,
    this.estimatedQuarterBpm,
    this.timeScale,
    this.startOffsetSeconds,
  );
  final List<AlignedNote> events;
  final double? estimatedQuarterBpm;
  final double timeScale, startOffsetSeconds;
}

/// Sequence alignment only. Its edit costs select correspondences, never grades.
class ReferenceNoteAligner {
  const ReferenceNoteAligner();

  NoteAlignment align(ReferenceScore score, List<PerformedNote> performed) {
    final reference = score.notes.where((n) => n.isAttack && !n.isRest).toList()
      ..sort((a, b) => a.startSeconds.compareTo(b.startSeconds));
    // A single-pitch audio stream cannot reliably correspond to simultaneous
    // reference pitches. Reject this case instead of inventing note matches.
    for (var i = 1; i < reference.length; i++) {
      if ((reference[i].startSeconds - reference[i - 1].startSeconds).abs() <
          1e-7) {
        throw UnsupportedError(
          'Polyphonic reference alignment is not supported.',
        );
      }
    }
    for (var i = 1; i < performed.length; i++) {
      if (performed[i].startSeconds < performed[i - 1].startSeconds) {
        throw const FormatException('Performed notes must be time ordered.');
      }
    }
    if (reference.isEmpty) {
      return NoteAlignment(
        List.unmodifiable(
          performed.map((n) => AlignedNote(AlignmentMark.extra, null, n)),
        ),
        null,
        1,
        0,
      );
    }
    if (performed.isEmpty) {
      return NoteAlignment(
        List.unmodifiable(
          reference.map((n) => AlignedNote(AlignmentMark.missed, n, null)),
        ),
        null,
        1,
        0,
      );
    }
    _Path? best;
    // Search the global performance speed without assuming matching endpoints;
    // insertions and omissions can occur at either end.
    for (var scale = 0.5; scale <= 2.001; scale += 0.05) {
      final path = _solve(
        reference,
        performed,
        scale,
        performed.first.startSeconds - reference.first.startSeconds * scale,
      );
      if (best == null || path.cost < best.cost) best = path;
    }
    var path = best!;
    final pairs = path.events
        .where((e) => e.reference != null && e.performed != null)
        .toList();
    if (pairs.length >= 2) {
      final slopes = <double>[];
      for (var i = 0; i < pairs.length; i++) {
        for (var j = i + 1; j < pairs.length; j++) {
          final delta =
              pairs[j].reference!.startSeconds -
              pairs[i].reference!.startSeconds;
          if (delta > 0.15) {
            slopes.add(
              (pairs[j].performed!.startSeconds -
                      pairs[i].performed!.startSeconds) /
                  delta,
            );
          }
        }
      }
      if (slopes.isNotEmpty) {
        slopes.sort();
        final refined = slopes[slopes.length ~/ 2].clamp(0.5, 2.0);
        final offsets =
            pairs
                .map(
                  (e) =>
                      e.performed!.startSeconds -
                      refined * e.reference!.startSeconds,
                )
                .toList()
              ..sort();
        path = _solve(
          reference,
          performed,
          refined,
          offsets[offsets.length ~/ 2],
        );
      }
    }
    final initialBpm = score.tempos.first.quarterBpm;
    return NoteAlignment(
      List.unmodifiable(path.events),
      initialBpm / path.scale,
      path.scale,
      path.offset,
    );
  }

  _Path _solve(
    List<ReferenceNote> r,
    List<PerformedNote> p,
    double scale,
    double offset,
  ) {
    final rows = r.length + 1, cols = p.length + 1;
    final costs = List.generate(
      rows,
      (_) => List.filled(cols, double.infinity),
    );
    final moves = List.generate(rows, (_) => List.filled(cols, 0));
    costs[0][0] = 0;
    for (var i = 0; i < rows; i++) {
      for (var j = 0; j < cols; j++) {
        final current = costs[i][j];
        if (i < r.length && current + 1.25 < costs[i + 1][j]) {
          costs[i + 1][j] = current + 1.25;
          moves[i + 1][j] = 1;
        }
        if (j < p.length && current + 1.25 < costs[i][j + 1]) {
          costs[i][j + 1] = current + 1.25;
          moves[i][j + 1] = 2;
        }
        if (i < r.length && j < p.length) {
          final pitch = (r[i].midiPitch! - p[j].midiPitch).abs();
          final time =
              ((p[j].startSeconds - offset - scale * r[i].startSeconds).abs() /
                      0.25)
                  .clamp(0.0, 1.5);
          final match = current + (pitch <= 0.65 ? 0 : 1.3) + time * 0.5;
          if (match < costs[i + 1][j + 1]) {
            costs[i + 1][j + 1] = match;
            moves[i + 1][j + 1] = 3;
          }
        }
      }
    }
    var i = r.length, j = p.length;
    final events = <AlignedNote>[];
    while (i > 0 || j > 0) {
      switch (moves[i][j]) {
        case 1:
          events.add(AlignedNote(AlignmentMark.missed, r[--i], null));
        case 2:
          events.add(AlignedNote(AlignmentMark.extra, null, p[--j]));
        case 3:
          final reference = r[--i], performance = p[--j];
          events.add(
            AlignedNote(
              (reference.midiPitch! - performance.midiPitch).abs() <= 0.65
                  ? AlignmentMark.matched
                  : AlignmentMark.wrongNote,
              reference,
              performance,
            ),
          );
        default:
          throw StateError('Invalid alignment backtrack.');
      }
    }
    return _Path(events.reversed.toList(), costs.last.last, scale, offset);
  }
}

class _Path {
  const _Path(this.events, this.cost, this.scale, this.offset);
  final List<AlignedNote> events;
  final double cost, scale, offset;
}
