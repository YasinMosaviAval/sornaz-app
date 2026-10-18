import 'dart:convert';
import 'dart:io';
import '../lib/screens/IntervalRecognition/models.dart';

/// Source data for server-side answer validation; not an application build.
void main(List<String> arguments) {
  if (arguments.length != 1)
    throw ArgumentError('Provide the destination JSON path');
  final data = {
    'version': 1,
    'branches': {
      for (final music in IntervalMusic.values)
        music.name: {
          for (final level in IntervalLevel.levelsFor(music))
            '${level.number}': {
              'direction': level.direction.name,
              'variableRoot': level.variableRoot,
              'quarterSteps': level.intervals
                  .map((interval) => interval.quarterSteps)
                  .toList(),
            },
        },
    },
  };
  File(
    arguments.single,
  ).writeAsStringSync('${const JsonEncoder.withIndent('  ').convert(data)}\n');
}
