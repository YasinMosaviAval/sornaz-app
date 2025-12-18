import 'dart:io';
import 'dart:isolate';

import 'package:sornaz/helpers/app_strings.dart';

void scanAudioIsolate(Map<String, dynamic> args) async {
  final SendPort sendPort = args['sendPort'];
  final List<String> roots = args['roots'];

  final audioFiles = <Map<String, dynamic>>[];
  final extensions = [
    AppStrings.file_type_dot_mp3,
    AppStrings.file_type_dot_wav,
    AppStrings.file_type_dot_m4a,
    AppStrings.file_type_dot_aac,
    AppStrings.file_type_dot_flac,
    AppStrings.file_type_dot_ogg,
  ];

  // 1️⃣ شمارش
  final List<File> files = [];

  for (final path in roots) {
    final dir = Directory(path);
    if (!dir.existsSync()) continue;

    await for (final e in dir.list(recursive: true, followLinks: false)) {
      if (e is File &&
          extensions.any((ext) => e.path.toLowerCase().endsWith(ext))) {
        files.add(e);
      }
    }
  }

  final total = files.length;
  int scanned = 0;

  // 2️⃣ ارسال progress
  for (final file in files) {
    audioFiles.add({
      'path': file.path,
      'modified': file.lastModifiedSync().millisecondsSinceEpoch,
    });

    scanned++;
    sendPort.send({
      'scanned': scanned,
      'total': total,
      'path': file.path,
    });
  }

  // 3️⃣ پایان
  sendPort.send({
    'done': true,
    'files': audioFiles,
  });
}
