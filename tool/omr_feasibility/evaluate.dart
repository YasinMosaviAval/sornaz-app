import 'dart:convert';
import 'dart:io';

void main() {
  final cwd = File.fromUri(Platform.script).parent.path;
  final truth = jsonDecode(File('$cwd/fixture_ground_truth.json').readAsStringSync())
      as Map<String, dynamic>;
  final cases = truth['cases'] as Map<String, dynamic>;
  final results = <Map<String, Object?>>[];
  for (final entry in cases.entries) {
    final name = entry.key;
    final description = entry.value as Map<String, dynamic>;
    final reference = description.containsKey('derivedFrom')
        ? cases[description['derivedFrom']] as Map<String, dynamic>
        : description;
    final run = Process.runSync(Platform.resolvedExecutable,
        ['$cwd/printed_score_probe.dart', '$cwd/$name.png'],
        workingDirectory: cwd);
    if (run.exitCode != 0) {
      throw StateError('$name failed: ${run.stderr}');
    }
    final actual = jsonDecode(run.stdout as String) as Map<String, dynamic>;
    final staffs = actual['staffs'] as List<dynamic>;
    final systems = actual['systems'] as List<dynamic>;
    final expectedStaffs = reference['staffs'] as List<dynamic>;
    final expectedEvents = reference['events'] as List<dynamic>;
    var clefMatches = 0;
    var pitchMatches = 0;
    var emittedPitchCount = 0;
    var durationMatches = 0;
    var emittedDurationCount = 0;
    final expectedPitches = <int>[];
    final actualPitches = <int>[];
    for (var staffIndex = 0; staffIndex < expectedStaffs.length; staffIndex++) {
      if (staffIndex >= staffs.length) continue;
      final staff = staffs[staffIndex] as Map<String, dynamic>;
      if (staff['clef'] == expectedStaffs[staffIndex]) clefMatches++;
      final expectedNotes = expectedEvents.cast<Map<String, dynamic>>()
          .where((event) => event['s'] == staffIndex && event['midi'] is List)
          .toList();
      final actualNotes = (staff['notes'] as List<dynamic>)
          .cast<Map<String, dynamic>>();
      final available = <int>[
        for (final note in actualNotes)
          if (note['midi'] is int) note['midi'] as int,
      ];
      emittedPitchCount += available.length;
      actualPitches.addAll(available);
      for (final event in expectedNotes) {
        for (final pitch in (event['midi'] as List<dynamic>).cast<int>()) {
          expectedPitches.add(pitch);
          final found = available.indexOf(pitch);
          if (found >= 0) {
            pitchMatches++;
            available.removeAt(found);
          }
        }
      }
      final expectedDurations = <String>[
        for (final event in expectedNotes)
          for (final pitch in (event['midi'] as List<dynamic>).cast<int>())
            '$pitch:${event['beats']}',
      ];
      for (final note in actualNotes) {
        if (note['durationBeats'] == null) continue;
        emittedDurationCount++;
        final key = '${note['midi']}:${note['durationBeats']}';
        final found = expectedDurations.indexOf(key);
        if (found >= 0) {
          durationMatches++;
          expectedDurations.removeAt(found);
        }
      }
    }
    final expectedRestCount = expectedEvents.where(
      (event) => (event as Map<String, dynamic>)['rest'] == true,
    ).length;
    final expectedChordCount = expectedEvents.where(
      (event) => (event as Map<String, dynamic>)['midi'] is List &&
          (event['midi'] as List).length > 1,
    ).length;
    final observedHeads = staffs.fold<int>(0, (sum, staff) => sum +
        ((staff as Map<String, dynamic>)['notes'] as List).length);
    final observedRests = staffs.fold<int>(0, (sum, staff) => sum +
        ((staff as Map<String, dynamic>)['measures'] as List).fold<int>(0,
          (measureSum, measure) => measureSum +
            ((measure as Map<String, dynamic>)['rests'] as List).length));
    final observedChords = staffs.fold<int>(0, (sum, staff) => sum +
        ((staff as Map<String, dynamic>)['chords'] as List).length);
    final observedMeasures = systems.fold<int>(0, (sum, system) => sum +
        ((system as Map<String, dynamic>)['measureCount'] as int));
    results.add({
      'case': name,
      'expectedStaffs': expectedStaffs.length,
      'observedStaffs': staffs.length,
      'clefMatches': clefMatches,
      'expectedHeads': expectedPitches.length,
      'observedHeads': observedHeads,
      'pitchMultisetMatches': pitchMatches,
      'emittedPitches': emittedPitchCount,
      'expectedMeasures': reference['measures'],
      'observedMeasures': observedMeasures,
      'expectedRests': expectedRestCount,
      'observedRests': observedRests,
      'expectedChords': expectedChordCount,
      'observedChords': observedChords,
      'correctDurationLabels': durationMatches,
      'emittedDurationLabels': emittedDurationCount,
      'expectedSystems': reference['systems'] ?? (expectedStaffs.length == 2 ? 1 : expectedStaffs.length),
      'observedSystems': systems.length,
      'pianoCandidate': systems.any((system) =>
          (system as Map<String, dynamic>)['type'] == 'pianoCandidate'),
      'deskewDegrees': actual['deskewDegrees'],
      'elapsedMs': actual['elapsedMs'],
      'peakRssBytes': actual['peakRssBytes'],
      'expectedPitchList': expectedPitches,
      'observedPitchList': actualPitches,
    });
    stdout.writeln('$name: staff ${staffs.length}/${expectedStaffs.length}, '
        'pitch $pitchMatches/${expectedPitches.length}, '
        'heads $observedHeads/${expectedPitches.length}, '
        'measures $observedMeasures/${reference['measures']}');
  }
  File('$cwd/evaluation_results.json').writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert({'results': results}));
}
