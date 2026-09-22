import 'package:sornaz/helpers/app_platform.dart';
import 'recording_bookmarks.dart';
import 'recording_text.dart';
import '../../Players/services/music_playlists.dart';
import '../../Players/metadata/metadata_service.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class SavedRecording {
  const SavedRecording({
    required this.uri,
    required this.name,
    required this.modified,
    this.isPublic = false,
  });
  final String uri, name;
  final DateTime modified;
  final bool isPublic;
}

class FileService {
  Future<void> discardDraft(String path) async {
    final file = File(path);
    if (await file.exists()) await file.delete();
    await bookmarks.delete(path);
  }

  Future<Map<String, String>> describe(SavedRecording item) async {
    if (item.isPublic) {
      return await channel.invokeMapMethod<String, String>('describe', {
            'uri': item.uri,
          }) ??
          {};
    }
    final metadata = await MetadataService.extract(item.uri);
    return {
      ...metadata.details,
      'location': File(item.uri).parent.path,
      if (metadata.duration != null)
        'durationMs': '${metadata.duration!.inMilliseconds}',
    };
  }

  Future<void> spliceDraft(String original, String segment, int at) =>
      const MethodChannel('sornaz/recordings').invokeMethod<void>(
        'spliceDraft',
        {'original': original, 'segment': segment, 'at': at},
      );
  final bookmarks = RecordingBookmarks();
  static const channel = MethodChannel('sornaz/recordings');
  late Directory _dir;
  int? _sdk;
  Future<void> init() async {
    final base = await getApplicationDocumentsDirectory();
    _dir = Directory('${base.path}/Recordings');
    await _dir.create(recursive: true);
    if (AppPlatform.isAndroid) _sdk = await channel.invokeMethod<int>('sdk');
  }

  Future<void> preparePublicStorage() async {
    if (AppPlatform.isAndroid &&
        (_sdk ?? 29) < 29 &&
        !await Permission.storage.request().isGranted) {
      throw const FileSystemException(
        'Storage permission is required on Android 9 and earlier.',
      );
    }
  }

  Future<void> publish(String path, {String? sourceUri}) async {
    if (!AppPlatform.isAndroid) return;
    final uri = await channel.invokeMethod<String>('save', {'path': path});
    if (uri == null) throw StateError('Missing public recording URI');
    await bookmarks.move(path, uri);
    await MusicPlaylists.recordings.replacePath(path, uri);
    await moveRecordingText(path, uri);
    // Delete staging only after MediaStore has committed the complete file.
    await File(path).delete();
  }

  Future<List<SavedRecording>> loadFiles() async {
    final local = await _dir
        .list()
        .where((f) => f is File && f.path.endsWith('.m4a'))
        .cast<File>()
        .toList();
    final result = <SavedRecording>[];
    for (final file in local) {
      try {
        if (AppPlatform.isAndroid &&
            ((_sdk ?? 29) >= 29 || await Permission.storage.isGranted) &&
            await file.length() > 0) {
          await publish(file.path);
          continue;
        }
      } catch (_) {
        /* Preserve and expose unsaved recordings for playback/retry. */
      }
      result.add(
        SavedRecording(
          uri: file.path,
          name: file.uri.pathSegments.last,
          modified: await file.lastModified(),
        ),
      );
    }
    if (AppPlatform.isAndroid) {
      try {
        final entries = await channel.invokeListMethod<dynamic>('list') ?? [];
        result.addAll(
          entries.map(
            (entry) => SavedRecording(
              uri: entry['uri'] as String,
              name: entry['name'] as String,
              modified: DateTime.fromMillisecondsSinceEpoch(
                (entry['modified'] as num).toInt(),
              ),
              isPublic: true,
            ),
          ),
        );
      } on PlatformException {
        if ((_sdk ?? 29) >= 29) rethrow;
      }
    }
    result.sort((a, b) => b.modified.compareTo(a.modified));
    return result;
  }

  Future<void> delete(SavedRecording item) async {
    if (item.isPublic) {
      await channel.invokeMethod<void>('delete', {'uri': item.uri});
    } else {
      await File(item.uri).delete();
    }
    await bookmarks.delete(item.uri);
    await MusicPlaylists.recordings.replacePath(item.uri, null);
    await moveRecordingText(item.uri, null);
  }

  Future<void> rename(SavedRecording item, String name) async {
    if (name.isEmpty ||
        name.contains(RegExp(r'[/\\\x00]')) ||
        name.length > 100)
      throw const FormatException('Invalid recording name');
    if (item.isPublic) {
      final uri = await channel.invokeMethod<String>('rename', {
        'uri': item.uri,
        'name': name,
      });
      if (uri != null) {
        await bookmarks.move(item.uri, uri);
        await MusicPlaylists.recordings.replacePath(item.uri, uri);
        await moveRecordingText(item.uri, uri);
      }
    } else {
      final renamed = await File(
        item.uri,
      ).rename('${File(item.uri).parent.path}/$name.m4a');
      await bookmarks.move(item.uri, renamed.path);
      await MusicPlaylists.recordings.replacePath(item.uri, renamed.path);
      await moveRecordingText(item.uri, renamed.path);
    }
  }

  Future<void> share(SavedRecording item) async {
    if (item.isPublic) {
      await channel.invokeMethod<void>('share', {'uri': item.uri});
    } else {
      await Share.shareXFiles([XFile(item.uri)]);
    }
  }

  String newPath() =>
      '${_dir.path}/${DateTime.now().microsecondsSinceEpoch}.m4a';
  Future<String> materialize(SavedRecording item) async => item.isPublic
      ? (await channel.invokeMethod<String>('materialize', {'uri': item.uri}))!
      : item.uri;
  Future<void> overwrite(SavedRecording item, String path, int at) async {
    await channel.invokeMethod<void>('overwrite', {
      'uri': item.uri,
      'path': path,
      'at': at,
    });
    await File(path).delete();
  }

  Future<String> location() async => AppPlatform.isAndroid
      ? (await const MethodChannel(
              'sornaz/recording_workspace',
            ).invokeMethod<String>('location')) ??
            'Music/Sornaz'
      : _dir.path;
  Future<void> chooseLocation() async {
    if (AppPlatform.isAndroid)
      await const MethodChannel(
        'sornaz/recording_workspace',
      ).invokeMethod<String>('choose');
  }
}
