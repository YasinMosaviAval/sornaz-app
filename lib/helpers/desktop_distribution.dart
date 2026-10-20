import 'dart:io';
import 'dart:isolate';
import 'package:archive/archive_io.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Share the portable bundle, including its runtime DLLs and public assets.
/// Account data and documents live elsewhere and must never enter this archive.
Future<void> shareDesktopDistribution() async {
  final folder = File(Platform.resolvedExecutable).parent.path;
  final output = p.join(
    (await getTemporaryDirectory()).path,
    'Sornaz-Windows-${DateTime.now().microsecondsSinceEpoch}.zip',
  );
  try {
    await Isolate.run(() async {
      final zip = ZipFileEncoder();
      zip.create(output);
      try {
        for (final entry in Directory(folder).listSync(followLinks: false)) {
          if (entry is File &&
              (p.extension(entry.path).toLowerCase() == '.dll' ||
                  p.equals(entry.path, Platform.resolvedExecutable))) {
            await zip.addFile(entry);
          }
        }
        final data = Directory(p.join(folder, 'data'));
        if (!data.existsSync())
          throw const FileSystemException('Application assets are missing');
        await zip.addDirectory(data, includeDirName: true, followLinks: false);
        final licenses = Directory(p.join(folder, 'LICENSES'));
        if (licenses.existsSync())
          await zip.addDirectory(
            licenses,
            includeDirName: true,
            followLinks: false,
          );
      } finally {
        await zip.close();
      }
    });
    await Share.shareXFiles([XFile(output)]);
  } finally {
    final file = File(output);
    if (await file.exists()) await file.delete();
  }
}
