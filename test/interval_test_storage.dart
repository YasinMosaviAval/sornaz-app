import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

/// Open local storage before widget fake-async clocks begin.
void useIntervalTestStorage() {
  late Directory directory;
  setUpAll(() async {
    directory = await Directory.systemTemp.createTemp('sornaz-interval-test-');
    Hive.init(directory.path);
    await Hive.openBox<String>('solfege_interval_results_v1');
  });
  setUp(() async => Hive.box<String>('solfege_interval_results_v1').clear());
  tearDownAll(() async {
    await Hive.close();
    final target = directory.absolute.path;
    final root = Directory.systemTemp.absolute.path;
    if (!target.startsWith('$root${Platform.pathSeparator}') ||
        !directory.uri.pathSegments
            .where((s) => s.isNotEmpty)
            .last
            .startsWith('sornaz-interval-test-'))
      throw StateError('Unexpected test storage path');
    await directory.delete(recursive: true);
  });
}
