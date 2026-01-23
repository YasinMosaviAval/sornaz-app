import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:sornaz/helpers/app_constants.dart';

class FileService {
  late Directory _dir;

  Future<void> init() async {
    final base = await getApplicationDocumentsDirectory();
    _dir = Directory('${base.path}/${AppConstants.AUDIO_RECORDER_FOLDER_NAME}');
    if (!await _dir.exists()) {
      await _dir.create(recursive: true);
    }
  }

  Future<List<File>> loadFiles() async {
    return _dir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith(AppConstants.DOT_M4A))
        .toList()
      ..sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
  }

  String newPath() => '${_dir.path}/${DateTime.now().millisecondsSinceEpoch}${AppConstants.DOT_M4A}';
}
