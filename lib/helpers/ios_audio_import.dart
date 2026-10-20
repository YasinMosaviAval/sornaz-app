import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Copy selected Files-provider audio into the persistent application library.
/// Never move provider originals or retain temporary picker paths as tracks.
Future<int> importIosAudio() async {
  final selected = await FilePicker.platform.pickFiles(
    type: FileType.audio,
    allowMultiple: true,
    withData: false,
  );
  if (selected == null) return 0;
  final folder = await Directory(
    p.join((await getApplicationDocumentsDirectory()).path, 'Music'),
  ).create(recursive: true);
  var imported = 0;
  for (final file in selected.files) {
    if (file.path == null)
      throw const FileSystemException('Selected audio has no readable path');
    final name = p.basename(file.name);
    final target = File(
      p.join(folder.path, '${DateTime.now().microsecondsSinceEpoch}-$name'),
    );
    try {
      await File(file.path!).copy(target.path);
      imported++;
    } catch (_) {
      if (await target.exists()) await target.delete();
      rethrow;
    }
  }
  return imported;
}
