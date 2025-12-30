import 'dart:io';
import 'package:path_provider/path_provider.dart';

class FileService {
  late Directory _dir;

  Future<void> init() async {
    final base = await getApplicationDocumentsDirectory();
    _dir = Directory('${base.path}/Recordings');
    if (!await _dir.exists()) {
      await _dir.create(recursive: true);
    }
  }

  Future<List<File>> loadFiles() async {
    return _dir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.m4a'))
        .toList()
      ..sort((a, b) =>
          b.lastModifiedSync().compareTo(a.lastModifiedSync()));
  }

  String newPath() =>
      '${_dir.path}/${DateTime.now().millisecondsSinceEpoch}.m4a';
}
