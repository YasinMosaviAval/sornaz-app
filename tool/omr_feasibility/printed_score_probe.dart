// Command-line harness for the same pixel engine used by the Flutter app.
import 'dart:convert';
import 'dart:io';

import '../../lib/services/omr/printed_score_engine.dart';

void main(List<String> arguments) {
  if (arguments.isEmpty ||
      arguments.length > 2 ||
      (arguments.length == 2 && !arguments[1].startsWith('--clefs='))) {
    stderr.writeln(
        'Usage: dart printed_score_probe.dart score.png [--clefs=treble,bass]');
    exitCode = 64;
    return;
  }
  try {
    final source = File(arguments.first);
    final manualClefs = arguments.length == 2
        ? arguments[1].substring('--clefs='.length).split(',')
        : <String>[];
    final result =
        analyzePrintedScore(source.readAsBytesSync(), manualClefs: manualClefs);
    result['source'] = source.path;
    result['peakRssBytes'] = ProcessInfo.maxRss;
    stdout.writeln(const JsonEncoder.withIndent('  ').convert(result));
  } on FormatException catch (error) {
    stderr.writeln(error.message);
    exitCode = 65;
  }
}
