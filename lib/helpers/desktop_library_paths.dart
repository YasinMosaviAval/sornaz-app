import 'package:shared_preferences/shared_preferences.dart';

Future<List<String>> desktopLibraryFolders(bool video) async =>
    (await SharedPreferences.getInstance()).getStringList(
      video ? 'desktop.videoFolders' : 'desktop.audioFolders',
    ) ??
    [];

Future<String?> desktopRecordingFolder() async =>
    (await SharedPreferences.getInstance()).getString(
      'desktop.recordingFolder',
    );
