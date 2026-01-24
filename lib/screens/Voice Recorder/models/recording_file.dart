import 'dart:io';

import 'package:sornaz/helpers/app_constants.dart';

class RecordingFile {
  final File file;
  final DateTime modified;

  RecordingFile(this.file, this.modified);

  String get name => file.path.split('/').last.replaceAll(AppConstants.DOT_M4A, '');
}
