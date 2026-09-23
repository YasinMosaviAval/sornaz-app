import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sornaz/screens/Voice%20Recorder/provider/voice_recorder_provider.dart';
import 'package:sornaz/screens/Voice%20Recorder/services/file_service.dart';
import 'package:sornaz/screens/Voice%20Recorder/services/recording_service.dart';
import 'package:sornaz/screens/Voice%20Recorder/services/recording_bookmarks.dart';
import 'package:sornaz/screens/Voice%20Recorder/services/playback_service.dart';

class Files implements FileService {
  int counter = 0;
  final splices = <int>[];
  String? published;
  @override
  final bookmarks = RecordingBookmarks();
  @override
  Future<void> init() async {}
  @override
  Future<void> preparePublicStorage() async {}
  @override
  Future<List<SavedRecording>> loadFiles() async => [];
  @override
  String newPath() => '/draft/${counter++}.m4a';
  @override
  Future<void> spliceDraft(String original, String segment, int at) async {
    splices.add(at);
  }

  @override
  Future<void> publish(String path, {String? sourceUri}) async {
    published = path;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class Recorder implements RecordingService {
  final starts = <String>[];
  int stops = 0;
  @override
  Future<bool> hasPermission() async => true;
  @override
  Future<void> start({
    required String path,
    required void Function(double) onAmplitude,
  }) async {
    starts.add(path);
  }

  @override
  Future<String?> stop() async {
    stops++;
    return starts.last;
  }

  @override
  Future<void> dispose() async {}
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class Player implements PlaybackService {
  @override
  String? currentPath;
  @override
  bool isPlaying = false;
  @override
  Duration position = Duration.zero;
  @override
  Duration get displayPosition => position;
  @override
  void Function()? onChanged;
  @override
  Future<void> stop() async {
    currentPath = null;
    position = Duration.zero;
    isPlaying = false;
  }

  @override
  Future<void> play(String path, {bool autoplay = true}) async {
    currentPath = path;
    isPlaying = autoplay;
  }

  @override
  Future<void> seek(Duration p) async {
    position = p;
  }

  @override
  void dispose() {}
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'paused draft stays private and resumes by splicing at selected position',
    () async {
      SharedPreferences.setMockInitialValues({});
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      final files = Files(), recorder = Recorder(), player = Player();
      final vm = VoiceRecorderProvider(files, recorder, player);
      try {
        await vm.startRecording();
        final original = vm.currentFilePath;
        await vm.pauseRecording();
        expect(recorder.stops, 1);
        expect(player.currentPath, original);
        expect(player.isPlaying, false);
        expect(files.published, isNull);
        await player.seek(const Duration(milliseconds: 500));
        await vm.resumeRecording();
        expect(recorder.starts.length, 2);
        expect(vm.currentFilePath, original);
        await vm.pauseRecording();
        expect(files.splices, [500]);
        expect(files.published, isNull);
        await vm.stopRecording();
        expect(files.published, original);
        expect(recorder.stops, 2);
        expect(vm.currentFilePath, isNull);
        expect(vm.amplitudes, isEmpty);
      } finally {
        vm.dispose();
        debugDefaultTargetPlatformOverride = null;
      }
    },
  );
}
