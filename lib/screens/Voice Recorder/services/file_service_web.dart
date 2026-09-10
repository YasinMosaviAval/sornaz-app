import 'package:sornaz/helpers/browser_bridge.dart';
import 'recording_bookmarks.dart';
class SavedRecording {
  const SavedRecording({required this.uri, required this.name, required this.modified, this.isPublic = true});
  final String uri, name;
  final DateTime modified;
  final bool isPublic;
}
class FileService {
  Future<String> location() async => 'Browser storage';
  Future<void> chooseLocation() async {}
  Future<String> materialize(SavedRecording item) async => item.uri;
  Future<void> overwrite(SavedRecording item, String path, int at) async => throw UnsupportedError('Audio editing is available on Android.');
  final bookmarks = RecordingBookmarks();
  Future<void> init() async { await browserCall('recordingsInit'); }
  Future<void> preparePublicStorage() async {}
  String newPath() => 'recording:' + DateTime.now().microsecondsSinceEpoch.toString() + '';
  Future<void> publish(String path, {String? sourceUri}) async {
    if (sourceUri == null) throw StateError('Recording was not finalized');
    await browserCall('recordingsSave', {'id': path, 'source': sourceUri});
  }
  Future<List<SavedRecording>> loadFiles() async {
    final rows = await browserCall('recordingsList') as List;
    return rows.map((row) => SavedRecording(uri: row['id'], name: row['name'],
      modified: DateTime.fromMillisecondsSinceEpoch(row['modified']))).toList();
  }
  Future<void> delete(SavedRecording item) async {
    await browserCall('recordingsDelete', {'id': item.uri});
    await bookmarks.delete(item.uri);
  }
  Future<void> rename(SavedRecording item, String name) async {
    if (name.trim().isEmpty || name.length > 100) throw const FormatException('Invalid name');
    await browserCall('recordingsRename', {'id': item.uri, 'name': name});
  }
  Future<void> share(SavedRecording item) async { await browserCall('recordingsDownload', {'id': item.uri}); }
}
