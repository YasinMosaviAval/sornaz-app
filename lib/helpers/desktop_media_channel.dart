import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_platform.dart';

// Release adapter: notation storage only; native platforms retain their channel.
class DesktopMediaChannel extends MethodChannel {
  const DesktopMediaChannel(super.name);
  @override
  Future<T?> invokeMethod<T>(String method, [dynamic arguments]) async {
    if (kIsWeb || !AppPlatform.isWindows)
      return super.invokeMethod<T>(method, arguments);
    return await DesktopMedia.invoke(
          name,
          method,
          Map<String, dynamic>.from(arguments as Map? ?? {}),
        )
        as T?;
  }
}

class DesktopMedia {
  static Future<dynamic> invoke(
    String channel,
    String method,
    Map<String, dynamic> a,
  ) async {
    if (channel == 'sornaz/notation_storage') {
      final prefs = await SharedPreferences.getInstance();
      if (method == 'choose') {
        final selected = await FilePicker.platform.getDirectoryPath();
        if (selected == null) return null;
        final resolved = await Directory(selected).resolveSymbolicLinks();
        if (!await prefs.setString('desktop.notationFolder', resolved))
          throw StateError('Could not save folder');
        return resolved;
      }
      final directory = Directory(
        prefs.getString('desktop.notationFolder') ??
            p.join(
              (await getApplicationDocumentsDirectory()).path,
              'Sornaz',
              'Music Sheets',
            ),
      );
      if (method == 'location') return directory.path;
      if (method == 'save') {
        final name = '${a['name']}';
        final extension = p.extension(name).toLowerCase();
        if (!['.json', '.musicxml'].contains(extension))
          throw ArgumentError('Unsupported score format');
        final safe = p
            .basenameWithoutExtension(name)
            .replaceAll(RegExp(r'[<>:"/\\|?*\x00-\x1f]'), '_');
        if (safe.isEmpty || safe.length > 100)
          throw ArgumentError('Invalid score name');
        await directory.create(recursive: true);
        final file = File(
          p.join(
            directory.path,
            '$safe-${DateTime.now().microsecondsSinceEpoch}$extension',
          ),
        );
        await file.writeAsString(a['content'] as String, flush: true);
        return file.path;
      }
    }

    throw MissingPluginException('Unsupported notation storage operation');
  }
}
