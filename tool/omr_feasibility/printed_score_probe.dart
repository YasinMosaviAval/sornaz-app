// Experimental, dependency-free-from-the-app OMR probe. Not used by the UI.
// Run: dart run tool/omr_feasibility/printed_score_probe.dart image.png
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;

void main(List<String> arguments) {
  if (arguments.length != 1) {
    stderr.writeln(
      'Usage: dart run tool/omr_feasibility/printed_score_probe.dart score.png',
    );
    exitCode = 64;
    return;
  }
  final watch = Stopwatch()..start();
  final source = File(arguments.single);
  final bytes = source.readAsBytesSync();
  final image = img.decodeImage(bytes);
  if (image == null) {
    stderr.writeln('Unsupported image');
    exitCode = 65;
    return;
  }
  final width = image.width;
  final height = image.height;
  final ink = Uint8List(width * height);
  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      final p = image.getPixel(x, y);
      final luminance = image.numChannels == 1
          ? p.r
          : (p.r * 299 + p.g * 587 + p.b * 114) / 1000;
      ink[y * width + x] = luminance < 140 ? 1 : 0;
    }
  }

  final rows = <int>[];
  final rowCounts = <int>[];
  for (var y = 0; y < height; y++) {
    var count = 0;
    for (var x = 0; x < width; x++) {
      count += ink[y * width + x];
    }
    rowCounts.add(count);
    if (count > width * 0.1) rows.add(y);
  }
  final lines = <int>[];
  for (final row in rows) {
    if (lines.isEmpty || row - lines.last > 2) lines.add(row);
  }
  final staffs = <List<int>>[];
  for (var i = 0; i + 4 < lines.length; i++) {
    final candidate = lines.sublist(i, i + 5);
    final gaps = <int>[
      for (var j = 1; j < 5; j++) candidate[j] - candidate[j - 1],
    ];
    final gap = gaps.reduce((a, b) => a + b) / 4;
    if (gap >= 5 && gap <= 30 && gaps.every((n) => (n - gap).abs() <= 2)) {
      staffs.add(candidate);
      i += 4;
    }
  }
  final result = <String, Object?>{
    'source': source.path,
    'dimensions': [width, height],
    'staffCount': staffs.length,
    'strongestRows': [
      for (final y in [
        ...List.generate(height, (i) => i),
      ]..sort((a, b) => rowCounts[b].compareTo(rowCounts[a])))
        if (rowCounts[y] > 0) {'y': y, 'ink': rowCounts[y]},
    ].take(12).toList(),
    'staffs': <Object>[],
    'unsupported': [
      'clef recognition',
      'rests',
      'accidentals',
      'meter recognition',
      'chords',
      'grand staff grouping',
      'beams',
      'dotted notes',
      'measure timing',
    ],
  };
  final staffResults = result['staffs'] as List<Object>;
  for (final staff in staffs) {
    final spacing = (staff[4] - staff[0]) / 4;
    final upper = math.max(0, (staff.first - spacing * 1.5).round());
    final lower = math.min(height - 1, (staff.last + spacing * 1.5).round());
    final lineMask = <int>{
      for (final line in staff) ...[line - 1, line, line + 1],
    };
    final coverage = List<int>.filled(width, 0);
    for (var x = 0; x < width; x++) {
      for (final line in staff) {
        if (line >= 0 && line < height) coverage[x] += ink[line * width + x];
      }
    }
    final active = <int>[
      for (var x = 0; x < width; x++)
        if (coverage[x] >= 4) x,
    ];
    if (active.isEmpty) continue;
    final left = active.first;
    final right = active.last;
    final candidates = <({int x, int y, int score})>[];
    final radiusX = math.max(4, (spacing * 0.58).round());
    final radiusY = math.max(3, (spacing * 0.36).round());
    // Dense oval ink is evidence for a filled head. A vertical stem or a staff
    // line alone cannot meet the cross-section and area thresholds.
    for (var x = left + (spacing * 7).round(); x <= right - radiusX; x++) {
      for (var y = upper + radiusY; y <= lower - radiusY; y++) {
        var score = 0;
        var centralRows = 0;
        for (var dy = -radiusY; dy <= radiusY; dy++) {
          var rowCount = 0;
          final limit =
              (radiusX * math.sqrt(1 - dy * dy / (radiusY * radiusY + 1)))
                  .round();
          for (var dx = -limit; dx <= limit; dx++) {
            if (!lineMask.contains(y + dy) &&
                ink[(y + dy) * width + x + dx] == 1) {
              score++;
              rowCount++;
            }
          }
          if (dy.abs() <= 1 && rowCount >= radiusX) centralRows++;
        }
        if (score >= radiusX * radiusY * 1.4 && centralRows >= 1) {
          candidates.add((x: x, y: y, score: score));
        }
      }
    }
    candidates.sort((a, b) => b.score.compareTo(a.score));
    final heads = <({int x, int y, int score})>[];
    for (final candidate in candidates) {
      if (heads.every(
        (h) =>
            (h.x - candidate.x).abs() > radiusX * 1.7 ||
            (h.y - candidate.y).abs() > radiusY * 1.8,
      )) {
        heads.add(candidate);
      }
    }
    heads.sort((a, b) => a.x.compareTo(b.x));
    final notes = <Object>[];
    for (final head in heads) {
      // Under a treble-clef assumption, bottom staff line is E4 (MIDI 64).
      // This assumption is explicit because this probe does not read clefs.
      final step = ((staff.last - head.y) / (spacing / 2)).round();
      const diatonic = [64, 65, 67, 69, 71, 72, 74, 76, 77, 79, 81, 83];
      final midi = step >= 0 && step < diatonic.length ? diatonic[step] : null;
      notes.add({
        'x': head.x,
        'y': head.y,
        'staffStep': step,
        'midiIfTreble': midi,
        'duration': null,
      });
    }
    final barlines = <int>[];
    for (var x = left + (spacing * 7).round(); x <= right; x++) {
      var coverage = 0;
      for (var y = staff.first; y <= staff.last; y++) {
        coverage += ink[y * width + x];
      }
      if (coverage > (staff.last - staff.first) * 0.78 &&
          (barlines.isEmpty || x - barlines.last > 2)) {
        barlines.add(x);
      }
    }
    barlines.removeWhere((x) => heads.any((head) => (head.x - x).abs() <= radiusX * 2));
    staffResults.add({
      'lines': staff,
      'bounds': [left, right],
      'clef': 'unknown',
      'notes': notes,
      'barlines': barlines,
    });
  }
  watch.stop();
  result['elapsedMs'] = watch.elapsedMilliseconds;
  result['peakRssBytes'] = ProcessInfo.maxRss;
  stdout.writeln(const JsonEncoder.withIndent('  ').convert(result));
}
