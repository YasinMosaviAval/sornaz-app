import 'package:sornaz/helpers/app_platform.dart';
import 'desktop_library_paths.dart';
import 'dart:io';
import 'dart:async';
import 'dart:typed_data' show Endian;
import 'dart:math' as math;
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:ffmpeg_kit_flutter_new_audio/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new_audio/ffprobe_kit.dart';
import 'package:ffmpeg_kit_flutter_new_audio/return_code.dart';
import 'package:image/image.dart' as image;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';

/// Keeps the Android contracts intact and handles desktop files locally.
/// Unimplemented methods fail explicitly rather than report a false success.
class DesktopMediaChannel extends MethodChannel {
  const DesktopMediaChannel(super.name);
  @override
  Future<T?> invokeMethod<T>(String method, [dynamic arguments]) async {
    if (kIsWeb || (!AppPlatform.isWindows && !AppPlatform.isIOS)) {
      return super.invokeMethod<T>(method, arguments);
    }
    final values = Map<String, dynamic>.from(arguments as Map? ?? {});
    if (AppPlatform.isIOS) {
      if (!{
        'sornaz/audio_crop',
        'sornaz/device_videos',
        'sornaz/story_media',
      }.contains(name)) {
        return super.invokeMethod<T>(method, arguments);
      }
      return await DesktopMedia.invokeIOS(name, method, values) as T?;
    }
    return await DesktopMedia.invoke(name, method, values) as T?;
  }
}

class DesktopMedia {
  static const _ios = MethodChannel('sornaz/ios_media');
  static List<String> get videoEncoder => AppPlatform.isIOS
      ? ['-c:v', 'mpeg4', '-q:v', '2']
      : ['-c:v', 'h264_mf', '-hw_encoding', '0'];

  /// The audio-only iOS FFmpeg distribution has no H.264 encoder. Compose a
  /// high-quality MPEG-4 draft, then let AVFoundation produce the final MP4.
  static Future<File> finishVideo(File source) async {
    if (!AppPlatform.isIOS) return source;
    await privateFile(source.path);
    final output = await draft('mp4');
    try {
      await _ios.invokeMethod<void>('encodeVideo', {
        'path': source.path,
        'output': output.path,
      });
      if (!await output.exists() || await output.length() == 0) {
        throw StateError('Native video export is empty');
      }
      await source.delete();
      return output;
    } catch (_) {
      if (await output.exists()) await output.delete();
      rethrow;
    }
  }

  static Future<String> iosMaterialize(String uri) async =>
      await _ios.invokeMethod<String>('materialize', {'uri': uri}) ??
      (throw StateError('Selected iOS media is unavailable'));

  static Future<dynamic> invokeIOS(
    String channel,
    String method,
    Map<String, dynamic> a,
  ) async {
    if (channel == 'sornaz/device_videos') {
      if (method == 'sdk') return 0;
      if (method == 'list') return _ios.invokeMethod('videos');
      if (method == 'stageAudioSource') return iosMaterialize('${a['uri']}');
      if (method == 'delete' || method == 'rename')
        return _ios.invokeMethod(method, a);
      if (method == 'share') {
        final paths = <String>[];
        try {
          for (final uri in a['uris'] as List? ?? []) {
            paths.add(await iosMaterialize('$uri'));
          }
          return await _ios.invokeMethod('share', {'paths': paths});
        } finally {
          for (final path in paths) {
            final file = await privateFile(path);
            if (await file.exists()) await file.delete();
          }
        }
      }
      if (method == 'saveCrop') {
        final file = await privateFile('${a['staged']}');
        return _ios.invokeMethod('save', {'path': file.path, 'video': true});
      }
    }
    if (channel == 'sornaz/story_media') {
      if (method == 'permission' || method == 'gallery')
        return _ios.invokeMethod(method, a);
      if (method == 'camera') {
        final path = await _ios.invokeMethod<String>('camera');
        return path == null ? null : info(File(path), false);
      }
      if (method == 'select') {
        final path = await iosMaterialize('${a['uri']}');
        return info(File(path), a['video'] == true);
      }
      if (method == 'save') {
        final file = await privateFile('${a['path']}');
        return _ios.invokeMethod('save', {
          'path': file.path,
          'video': a['video'] == true,
        });
      }
      if (method == 'thumbnail' && '${a['uri']}'.startsWith('ph://')) {
        if (((a['timeMs'] as num?) ?? 0) == 0)
          return _ios.invokeMethod(method, a);
        final path = await iosMaterialize('${a['uri']}');
        try {
          return await invoke(channel, method, {...a, 'uri': path});
        } finally {
          await File(path).delete();
        }
      }
    }
    return invoke(channel, method, a);
  }

  static String path(String value) =>
      value.startsWith('file:') ? Uri.parse(value).toFilePath() : value;
  static Future<Directory> workspace() async => Directory(
    p.join((await getTemporaryDirectory()).path, 'sornaz-media'),
  ).create(recursive: true);
  static Future<File> draft(String extension) async => File(
    p.join(
      (await workspace()).path,
      '${DateTime.now().microsecondsSinceEpoch}.$extension',
    ),
  );
  static Future<void> run(List<String> arguments) async {
    final session = await FFmpegKit.executeWithArguments([
      '-nostdin',
      '-y',
      ...arguments,
    ]);
    if (!ReturnCode.isSuccess(await session.getReturnCode())) {
      throw PlatformException(
        code: 'MEDIA_FAILED',
        message:
            await session.getFailStackTrace() ??
            await session.getOutput() ??
            'Media processing failed',
      );
    }
  }

  static Future<Map<String, dynamic>> probe(String source) async {
    final info = (await FFprobeKit.getMediaInformation(
      path(source),
    )).getMediaInformation();
    if (info == null) throw const FormatException('Unreadable media');
    final properties = Map<String, dynamic>.from(info.getAllProperties() ?? {});
    return {
      ...properties,
      ...Map<String, dynamic>.from(properties['format'] as Map? ?? {}),
    };
  }

  static Future<int> duration(String source) async {
    final info = await probe(source);
    return ((double.tryParse('${info['duration']}') ?? 0) * 1000).round();
  }

  static Future<Map<String, dynamic>> info(File file, bool video) async => {
    'path': file.path,
    'uri': file.uri.toString(),
    'video': video,
    'size': await file.length(),
    'name': p.basename(file.path),
  };
  static Future<File> privateFile(String source) async {
    final file = File(path(source));
    final root = await (await workspace()).resolveSymbolicLinks();
    if (!p.isWithin(root, await file.resolveSymbolicLinks())) {
      throw const FileSystemException('Not a private media draft');
    }
    return file;
  }

  static Future<List<File>> files({bool images = false}) async {
    final profile = Platform.environment['USERPROFILE'];
    if (profile == null) return [];
    final result = <File>[];
    final extensions = {
      '.mp4',
      '.mov',
      '.mkv',
      '.avi',
      '.webm',
      '.m4v',
      if (images) ...{'.jpg', '.jpeg', '.png', '.webp'},
    };
    final roots = <String>{
      p.join(profile, 'Videos'),
      if (images) p.join(profile, 'Pictures'),
      ...await desktopLibraryFolders(true),
    };
    final seen = <String>{};
    for (final root in roots) {
      final directory = Directory(root);
      if (!await directory.exists()) continue;
      try {
        await for (final entity in directory.list(
          recursive: true,
          followLinks: false,
        )) {
          if (entity is File &&
              extensions.contains(p.extension(entity.path).toLowerCase()))
            if (seen.add(p.normalize(entity.path))) result.add(entity);
        }
      } on FileSystemException {
        /* Preserve other accessible folders. */
      }
    }
    result.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
    return result;
  }

  static Future<String> save(
    File file, {
    bool video = false,
    bool audio = false,
  }) async {
    final profile = Platform.environment['USERPROFILE'];
    final base = profile == null
        ? (await getApplicationDocumentsDirectory()).path
        : p.join(
            profile,
            audio
                ? 'Music'
                : video
                ? 'Videos'
                : 'Pictures',
          );
    final directory = await Directory(
      p.join(base, 'Sornaz'),
    ).create(recursive: true);
    final destination = p.join(
      directory.path,
      '${p.basenameWithoutExtension(file.path)}-${DateTime.now().microsecondsSinceEpoch}${p.extension(file.path)}',
    );
    await file.copy(destination);
    return destination;
  }

  static Future<String> commit(
    File staged,
    String original,
    bool replace,
  ) async {
    final source = File(path(original));
    final target = replace
        ? source.path
        : p.join(
            source.parent.path,
            '${p.basenameWithoutExtension(source.path)}_crop_${DateTime.now().microsecondsSinceEpoch}${p.extension(staged.path)}',
          );
    final temporary = File(
      '$target.sornaz-new-${DateTime.now().microsecondsSinceEpoch}',
    );
    final backup = File(
      '$target.sornaz-backup-${DateTime.now().microsecondsSinceEpoch}',
    );
    await staged.copy(temporary.path);
    var backedUp = false;
    try {
      if (replace && await source.exists()) {
        await source.rename(backup.path);
        backedUp = true;
      }
      await temporary.rename(target);
    } catch (_) {
      if (backedUp) await backup.rename(source.path);
      rethrow;
    } finally {
      if (await temporary.exists()) await temporary.delete();
    }
    if (backedUp && await backup.exists()) await backup.delete();
    return target;
  }

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
    if (channel == 'sornaz/analysis_audio') {
      if (method == 'cancel') {
        final id = _analysisSession;
        if (id != null) await FFmpegKit.cancel(id);
        return null;
      }
      if (method == 'decode') {
        final source = path('${a['source']}');
        if (!await File(source).exists())
          throw PlatformException(code: 'MISSING_FILE');
        final metadata = await probe(source);
        final output = await draft('s16le');
        final completed = Completer<void>();
        final session = await FFmpegKit.executeWithArgumentsAsync(
          [
            '-nostdin',
            '-y',
            '-i',
            source,
            '-vn',
            '-ar',
            '44100',
            '-ac',
            '1',
            '-f',
            's16le',
            output.path,
          ],
          (_) {
            if (!completed.isCompleted) completed.complete();
          },
        );
        _analysisSession = session.getSessionId();
        try {
          await completed.future;
          final code = await session.getReturnCode();
          if (!ReturnCode.isSuccess(code)) {
            throw PlatformException(
              code: ReturnCode.isCancel(code) ? 'CANCELLED' : 'DECODE_FAILED',
            );
          }
          return {
            'path': output.path,
            'sampleRate': 44100,
            'channels': 1,
            'durationUs':
                ((double.tryParse('${metadata['duration']}') ?? 0) * 1000000)
                    .round(),
            'mime': 'audio/pcm',
          };
        } catch (_) {
          if (await output.exists()) await output.delete();
          rethrow;
        } finally {
          if (_analysisSession == session.getSessionId())
            _analysisSession = null;
        }
      }
    }
    if (channel == 'sornaz/audio_crop') {
      if (method == 'render') {
        final start = (a['start'] as num).toDouble() / 1000;
        final end = (a['end'] as num).toDouble() / 1000;
        if (start < 0 || end <= start)
          throw ArgumentError('Invalid crop interval');
        final video = a['video'] == true;
        var output = await draft(video ? 'mp4' : 'm4a');
        await run([
          '-ss',
          '$start',
          '-i',
          path('${a['source']}'),
          '-t',
          '${end - start}',
          if (video) ...[
            ...videoEncoder,
            '-pix_fmt',
            'yuv420p',
            '-movflags',
            '+faststart',
          ] else
            '-vn',
          '-c:a',
          'aac',
          output.path,
        ]);
        if (video) output = await finishVideo(output);
        return output.path;
      }
      if (method == 'commit') {
        final staged = await privateFile('${a['staged']}');
        final source = path('${a['source']}');
        final replace = a['replace'] == true;
        final extension = p.extension(source).toLowerCase();
        if (replace && extension != p.extension(staged.path).toLowerCase()) {
          if (!{
            '.mp3',
            '.wav',
            '.m4a',
            '.aac',
            '.flac',
            '.ogg',
          }.contains(extension)) {
            throw ArgumentError('Unsupported replacement format');
          }
          final converted = await draft(extension.substring(1));
          try {
            await run(['-i', staged.path, '-vn', converted.path]);
            return await commit(converted, source, true);
          } finally {
            if (await converted.exists()) await converted.delete();
          }
        }
        return commit(staged, source, replace);
      }
    }
    if (channel == 'sornaz/device_videos') {
      if (method == 'sdk') return 0;
      if (method == 'list') {
        return [
          for (final file in await files())
            {
              'uri': file.uri.toString(),
              'name': p.basename(file.path),
              'folder': p.basename(file.parent.path),
              'folderId': file.parent.path,
              'duration': await duration(file.path),
              'addedAt': (await file.lastModified()).millisecondsSinceEpoch,
            },
        ];
      }
      if (method == 'stageAudioSource') {
        final source = File(path('${a['uri']}'));
        return (await source.copy(
          (await draft(p.extension(source.path).replaceFirst('.', ''))).path,
        )).path;
      }
      if (method == 'saveAudioExport')
        return save(File('${a['path']}'), audio: true);
      if (method == 'saveCrop')
        return save(await privateFile('${a['staged']}'), video: true);
      final sources = (a['uris'] as List? ?? [])
          .map((v) => File(path('$v')))
          .toList();
      if (method == 'share') {
        await Share.shareXFiles(sources.map((f) => XFile(f.path)).toList());
        return null;
      }
      if (method == 'delete') {
        for (final file in sources) {
          await file.delete();
        }
        return null;
      }
      if (method == 'rename' && sources.length == 1) {
        final name = '${a['name']}';
        if (name.isEmpty ||
            name != p.basename(name) ||
            name.contains(RegExp(r'[<>:"/\\|?*\x00]')))
          throw ArgumentError('Invalid name');
        final target = File(p.join(sources.first.parent.path, name));
        if (await target.exists())
          throw const FileSystemException('Name already exists');
        final renamed = await sources.first.rename(target.path);
        return renamed.uri.toString();
      }
    }
    if (channel == 'sornaz/story_media') {
      if (method == 'permission' || method == 'savePermission') return true;
      if (method == 'gallery') {
        final list = await files(images: true);
        final offset = (a['offset'] as num?)?.toInt() ?? 0;
        return [
          for (final file in list.skip(offset).take(60))
            {
              'uri': file.uri.toString(),
              'video': !{
                '.jpg',
                '.jpeg',
                '.png',
                '.webp',
              }.contains(p.extension(file.path).toLowerCase()),
              'duration': 0,
            },
        ];
      }
      if (method == 'select') {
        final source = File(path('${a['uri']}'));
        final copy = await source.copy(
          (await draft(p.extension(source.path).replaceFirst('.', ''))).path,
        );
        return info(copy, a['video'] == true);
      }
      if (method == 'thumbnail') {
        final size = ((a['size'] as num?)?.toInt() ?? 240).clamp(16, 4096);
        final source = path('${a['uri']}');
        if (a['video'] != true) {
          final decoded = image.decodeImage(await File(source).readAsBytes());
          if (decoded == null) throw const FormatException('Unreadable image');
          return Uint8List.fromList(
            image.encodeJpg(
              image.copyResize(decoded, width: math.min(size, decoded.width)),
            ),
          );
        }
        final output = await draft('jpg');
        try {
          await run([
            '-ss',
            '${((a['timeMs'] as num?) ?? 0) / 1000}',
            '-i',
            source,
            '-frames:v',
            '1',
            '-vf',
            'scale=$size:-2',
            output.path,
          ]);
          return await output.readAsBytes();
        } finally {
          if (await output.exists()) await output.delete();
        }
      }
      if (method == 'writeImage') {
        final file = await draft('png');
        await file.writeAsBytes(a['bytes'] as List<int>);
        return info(file, false);
      }
      if (method == 'exportVideo') {
        final source = await privateFile('${a['path']}');
        final overlay = await draft('png');
        var output = await draft('mp4');
        try {
          await overlay.writeAsBytes(a['overlay'] as List<int>);
          await run([
            '-i',
            source.path,
            '-i',
            overlay.path,
            '-filter_complex',
            '[0:v]scale=1080:1920:force_original_aspect_ratio=${a['cover'] == true ? 'increase' : 'decrease'},'
                '${a['cover'] == true ? 'crop=1080:1920' : 'pad=1080:1920:(ow-iw)/2:(oh-ih)/2:color=black'}[base];'
                '[1:v]scale=1080:1920[overlay];[base][overlay]overlay=0:0:format=auto',
            ...videoEncoder,
            '-pix_fmt',
            'yuv420p',
            '-movflags',
            '+faststart',
            '-c:a',
            'aac',
            output.path,
          ]);
          output = await finishVideo(output);
          return await info(output, true);
        } finally {
          if (await overlay.exists()) await overlay.delete();
        }
      }
      if (method == 'save')
        return save(
          await privateFile('${a['path']}'),
          video: a['video'] == true,
        );
      if (method == 'delete') {
        for (final value in a['paths'] as List? ?? []) {
          final file = File(path('$value'));
          if (await file.exists()) await (await privateFile('$value')).delete();
        }
        return null;
      }
      if (method == 'camera') {
        final output = await draft('jpg');
        try {
          await const MethodChannel(
            'sornaz/windows_camera',
          ).invokeMethod<String>('capture', {'path': output.path});
          return await info(output, false);
        } catch (_) {
          if (await output.exists()) await output.delete();
          rethrow;
        }
      }
    }
    throw MissingPluginException(
      'Windows media operation unavailable: $channel/$method',
    );
  }

  static int? _analysisSession;

  static Future<List<double>> waveform(String source) async {
    final output = await draft('s16le');
    try {
      await run([
        '-i',
        path(source),
        '-vn',
        '-ar',
        '8000',
        '-ac',
        '1',
        '-f',
        's16le',
        output.path,
      ]);
      final result = <double>[];
      final input = await output.open();
      try {
        while (true) {
          final bytes = await input.read(1600);
          if (bytes.isEmpty) break;
          final data = ByteData.sublistView(bytes);
          var peak = 0;
          for (var i = 0; i + 1 < bytes.length; i += 2) {
            peak = math.max(peak, data.getInt16(i, Endian.little).abs());
          }
          result.add(peak / 32768);
        }
      } finally {
        await input.close();
      }
      return result;
    } finally {
      if (await output.exists()) await output.delete();
    }
  }

  static Future<void> splice(
    String original,
    String segment,
    int milliseconds, {
    bool keepTail = true,
  }) async {
    if (milliseconds < 0 || p.equals(original, segment))
      throw ArgumentError('Invalid splice');
    final replacementSeconds = await duration(segment) / 1000;
    final oldSeconds = await duration(original) / 1000;
    final at = milliseconds / 1000;
    if (at > oldSeconds + .1) throw ArgumentError('Splice beyond recording');
    final extension = p.extension(original).toLowerCase();
    final output = await draft(
      extension.isEmpty ? 'm4a' : extension.substring(1),
    );
    final filters = <String>[];
    final parts = <String>[];
    if (at > 0) {
      filters.add('[0:a]atrim=end=$at,asetpts=PTS-STARTPTS[before]');
      parts.add('[before]');
    }
    filters.add('[1:a]asetpts=PTS-STARTPTS[replacement]');
    parts.add('[replacement]');
    if (keepTail && at + replacementSeconds < oldSeconds) {
      filters.add(
        '[0:a]atrim=start=${at + replacementSeconds},asetpts=PTS-STARTPTS[after]',
      );
      parts.add('[after]');
    }
    filters.add('${parts.join()}concat=n=${parts.length}:v=0:a=1[out]');
    try {
      await run([
        '-i',
        path(original),
        '-i',
        path(segment),
        '-filter_complex',
        filters.join(';'),
        '-map',
        '[out]',
        output.path,
      ]);
      await commit(output, original, true);
    } finally {
      if (await output.exists()) await output.delete();
    }
  }
}
