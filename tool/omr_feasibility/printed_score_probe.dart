// Experimental, dependency-free-from-the-app OMR probe. Not used by the UI.
// Run: dart run tool/omr_feasibility/printed_score_probe.dart image.png
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;

void main(List<String> arguments) {
  if (arguments.isEmpty || arguments.length > 2 ||
      (arguments.length == 2 && !arguments[1].startsWith('--clefs='))) {
    stderr.writeln(
      'Usage: dart printed_score_probe.dart score.png [--clefs=treble,bass]',
    );
    exitCode = 64;
    return;
  }
  final watch = Stopwatch()..start();
  final source = File(arguments.first);
  final manualClefs = arguments.length == 2
      ? arguments[1].substring('--clefs='.length).split(',')
      : <String>[];
  final bytes = source.readAsBytesSync();
  final decoded = img.decodeImage(bytes);
  if (decoded == null) {
    stderr.writeln('Unsupported image');
    exitCode = 65;
    return;
  }
  decoded.backgroundColor = img.ColorRgb8(255, 255, 255);
  int horizontalScore(img.Image candidate) {
    final rowScores = <int>[];
    for (var y = 0; y < candidate.height; y++) {
      var dark = 0;
      for (var x = 0; x < candidate.width; x += 2) {
        final p = candidate.getPixel(x, y);
        final brightness = candidate.numChannels == 1 ? p.r :
            (p.r * 299 + p.g * 587 + p.b * 114) / 1000;
        if (brightness < 245) dark++;
      }
      rowScores.add(dark);
    }
    rowScores.sort((a, b) => b.compareTo(a));
    return rowScores.take(5).fold(0, (a, b) => a + b);
  }
  var image = decoded;
  var deskewDegrees = 0;
  var bestScore = horizontalScore(decoded);
  // Try rotations only when five sufficiently long horizontal rows are absent.
  if (bestScore < decoded.width * 0.7) {
    for (final angle in [-5, -4, -3, -2, -1, 1, 2, 3, 4, 5]) {
      final candidate = img.copyRotate(decoded, angle: angle);
      final score = horizontalScore(candidate);
      if (score > bestScore) {
        bestScore = score;
        image = candidate;
        deskewDegrees = angle;
      }
    }
  }
  final width = image.width;
  final height = image.height;
  final ink = Uint8List(width * height);
  final darkInk = Uint8List(width * height);
  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      final p = image.getPixel(x, y);
      final luminance = image.numChannels == 1
          ? p.r
          : (p.r * 299 + p.g * 587 + p.b * 114) / 1000;
      ink[y * width + x] = luminance < 245 ? 1 : 0;
      darkInk[y * width + x] = luminance < 160 ? 1 : 0;
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
    'schemaVersion': 1,
    'engine': 'classical-pixel-prototype',
    'deskewDegrees': deskewDegrees,
    'horizontalScore': bestScore,
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
    'systems': <Object>[],
    'unsupported': [
      'rests',
      'accidentals',
      'meter recognition',
      'independent chord durations',
      'beams',
      'dotted notes',
      'measure timing',
    ],
  };
  final staffResults = result['staffs'] as List<Object>;
  for (var staffIndex = 0; staffIndex < staffs.length; staffIndex++) {
    final staff = staffs[staffIndex];
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
    var clefExtensionInk = 0;
    var clefBodyInk = 0;
    for (var x = left + spacing.round(); x <= math.min(width - 1, left + (spacing * 4).round()); x++) {
      for (var y = math.max(0, staff.first - (spacing * 2.5).round()); y < staff.first - 2; y++) {
        clefExtensionInk += darkInk[y * width + x];
      }
      for (var y = staff.last + 3; y <= math.min(height - 1, staff.last + (spacing * 2.5).round()); y++) {
        clefExtensionInk += darkInk[y * width + x];
      }
      for (var y = staff.first + 2; y <= staff.last - 2; y++) {
        if (!lineMask.contains(y)) clefBodyInk += darkInk[y * width + x];
      }
    }
    final imageClef = clefExtensionInk > spacing * 3
        ? 'treble'
        : clefBodyInk > spacing * 2
            ? 'bass'
            : 'unknown';
    final manualClef = staffIndex < manualClefs.length ? manualClefs[staffIndex] : null;
    final clef = imageClef != 'unknown' ? imageClef :
        (manualClef == 'bass' || manualClef == 'treble' ? manualClef! : 'unknown');
    final clefSource = imageClef != 'unknown' ? 'image' :
        clef != 'unknown' ? 'manual' : 'unknown';
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
    final notes = <Map<String, Object?>>[];
    for (final head in heads) {
      var stemUp = 0;
      var stemDown = 0;
      for (var dx = -radiusX; dx <= radiusX; dx++) {
        final x = head.x + dx;
        if (x < 0 || x >= width) continue;
        var up = 0;
        var down = 0;
        for (var distance = 3; distance <= (spacing * 3).round(); distance++) {
          if (head.y - distance >= 0) up += darkInk[(head.y - distance) * width + x];
          if (head.y + distance < height) down += darkInk[(head.y + distance) * width + x];
        }
        stemUp = math.max(stemUp, up);
        stemDown = math.max(stemDown, down);
      }
      final verticalGroup = heads.where((other) =>
          (other.x - head.x).abs() <= radiusX * 0.8 &&
          (other.y - head.y).abs() >= radiusY).length + 1;
      final supportedByStem =
          (stemUp >= spacing * 2.2 && stemDown <= spacing * 0.7) ||
          (stemDown >= spacing * 2.2 && stemUp <= spacing * 0.7);
      if (!supportedByStem && verticalGroup < 3) continue;
      var precedingInk = 0;
      var precedingBarline = false;
      var centerInk = 0;
      for (var y = math.max(0, head.y - 2); y <= math.min(height - 1, head.y + 2); y++) {
        for (var x = math.max(0, head.x - 2); x <= math.min(width - 1, head.x + 2); x++) {
          if (!lineMask.contains(y)) centerInk += darkInk[y * width + x];
        }
      }
      for (var x = math.max(0, head.x - (spacing * 1.8).round());
          x < head.x - radiusX - 1; x++) {
        var verticalInk = 0;
        for (var y = staff.first; y <= staff.last; y++) {
          verticalInk += ink[y * width + x];
        }
        if (verticalInk > (staff.last - staff.first) * 0.78) precedingBarline = true;
        for (var y = math.max(0, head.y - spacing.round());
            y <= math.min(height - 1, head.y + spacing.round()); y++) {
          if (!lineMask.contains(y)) precedingInk += darkInk[y * width + x];
        }
      }
      final step = ((staff.last - head.y) / (spacing / 2)).round();
      const trebleDiatonic = [64, 65, 67, 69, 71, 72, 74, 76, 77, 79, 81, 83];
      const bassDiatonic = [43, 45, 47, 48, 50, 52, 53, 55, 57, 59, 60, 62];
      final naturalMidi = step >= 0 && step < trebleDiatonic.length
          ? (clef == 'treble' ? trebleDiatonic[step] :
              clef == 'bass' ? bassDiatonic[step] : null)
          : null;
      final accidentalUnresolved = precedingInk > spacing * 2.5 && !precedingBarline;
      final midi = accidentalUnresolved ? null : naturalMidi;
      final hollowCandidate = centerInk <= 5 && stemUp >= spacing * 2.2;
      notes.add({
        'x': head.x,
        'y': head.y,
        'staffStep': step,
        'midi': midi,
        'naturalMidi': naturalMidi,
        'accidentalStatus': accidentalUnresolved ? 'unresolved' : 'noneDetected',
        'durationBeats': hollowCandidate ? 2 : null,
        'durationEvidence': hollowCandidate ? 'hollow-head-candidate' : 'unresolved',
        'at': null,
        'staffIndex': staffIndex,
        'stemInkUp': stemUp,
        'stemInkDown': stemDown,
        'precedingInk': precedingInk,
        'centerInk': centerInk,
        'confidence': midi == null ? 'uncertain' : 'candidate',
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
    barlines.removeWhere((x) => heads.any((head) => (head.x - x).abs() <= radiusX * 1.2));
    notes.removeWhere((note) => barlines.any((bar) => ((note['x'] as int) - bar).abs() <= radiusX * 2));
    for (final note in notes) {
      final x = note['x'] as int;
      note['measureIndex'] = barlines.where((bar) => bar < x).length;
    }
    final chords = <Map<String, Object?>>[];
    for (final note in notes) {
      final x = note['x'] as int;
      final group = <Map<String, Object?>>[note];
      for (final other in notes) {
        if (identical(note, other)) continue;
        if (((other['x'] as int) - x).abs() <= radiusX * 2 &&
            other['measureIndex'] == note['measureIndex']) group.add(other);
      }
      if (group.length > 1 && chords.every((c) => ((c['x'] as int) - x).abs() > radiusX * 2)) {
        chords.add({'x': x, 'measureIndex': note['measureIndex'],
          'pitches': group.map((n) => n['midi']).toList(),
          'durationBeats': null, 'at': null, 'confidence': 'candidate'});
      }
    }
    final measures = <Map<String, Object?>>[];
    for (var measureIndex = 0; measureIndex < barlines.length; measureIndex++) {
      measures.add({'index': measureIndex,
        'startX': measureIndex == 0 ? left : barlines[measureIndex - 1],
        'endX': barlines[measureIndex],
        'notes': notes.where((n) => n['measureIndex'] == measureIndex).toList(),
        'rests': <Object>[],
        'timingStatus': 'unresolved'});
    }
    staffResults.add({
      'lines': staff,
      'bounds': [left, right],
      'clef': clef,
      'clefSource': clefSource,
      'clefExtensionInk': clefExtensionInk,
      'clefBodyInk': clefBodyInk,
      'notes': notes,
      'chords': chords,
      'barlines': barlines,
      'measures': measures,
    });
  }
  final systems = result['systems'] as List<Object>;
  for (var i = 0; i < staffResults.length; i++) {
    final upperStaff = staffResults[i] as Map<String, Object?>;
    if (i + 1 < staffResults.length) {
      final lowerStaff = staffResults[i + 1] as Map<String, Object?>;
      final upperLines = upperStaff['lines'] as List<int>;
      final lowerLines = lowerStaff['lines'] as List<int>;
      final spacing = (upperLines.last - upperLines.first) / 4;
      final gap = lowerLines.first - upperLines.last;
      final upperBars = upperStaff['barlines'] as List<int>;
      final lowerBars = lowerStaff['barlines'] as List<int>;
      final aligned = upperBars.isNotEmpty && upperBars.every(
        (bar) => lowerBars.any((other) => (other - bar).abs() <= spacing),
      );
      var braceInk = 0;
      final left = (upperStaff['bounds'] as List<int>).first;
      for (var x = math.max(0, left - spacing.round()); x < math.min(width, left + spacing.round()); x++) {
        for (var y = upperLines.last + 3; y < lowerLines.first - 3; y++) {
          braceInk += darkInk[y * width + x];
        }
      }
      if (gap > spacing * 4 && gap < spacing * 14 && aligned && braceInk > spacing * 3 &&
          upperStaff['clef'] == 'treble' && lowerStaff['clef'] == 'bass') {
        systems.add({'staffIndices': [i, i + 1], 'type': 'pianoCandidate',
          'grouping': 'candidate', 'braceInk': braceInk,
          'alignedBarlines': aligned, 'measureCount': upperBars.length});
        i++;
        continue;
      }
    }
    systems.add({'staffIndices': [i], 'type': 'singleStaff',
      'grouping': 'detected', 'measureCount': (upperStaff['barlines'] as List<int>).length});
  }
  watch.stop();
  result['elapsedMs'] = watch.elapsedMilliseconds;
  result['peakRssBytes'] = ProcessInfo.maxRss;
  stdout.writeln(const JsonEncoder.withIndent('  ').convert(result));
}
