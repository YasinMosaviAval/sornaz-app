import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'desktop_media_channel.dart';

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

/// Import through Files and create a Photos-compatible H.264/AAC copy. iOS
/// does not expose arbitrary shared-storage folders as Android does.
Future<int> importIosVideos() async {
  final selected = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['mp4', 'mov', 'm4v', 'mkv', 'webm', 'avi'],
    allowMultiple: true,
    withData: false,
  );
  if (selected == null) return 0;
  var imported = 0;
  for (final file in selected.files) {
    if (file.path == null)
      throw const FileSystemException('Selected video has no readable path');
    var output = await DesktopMedia.draft('mp4');
    try {
      await DesktopMedia.run([
        '-i',
        file.path!,
        '-map',
        '0:v:0',
        '-map',
        '0:a?',
        ...DesktopMedia.videoEncoder,
        '-pix_fmt',
        'yuv420p',
        '-c:a',
        'aac',
        '-movflags',
        '+faststart',
        output.path,
      ]);
      output = await DesktopMedia.finishVideo(output);
      await DesktopMedia.invokeIOS('sornaz/story_media', 'save', {
        'path': output.path,
        'video': true,
      });
      imported++;
    } finally {
      if (await output.exists()) await output.delete();
    }
  }
  return imported;
}
