import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sornaz/screens/Tuner/audio/desktop_pitch_input.dart';
import 'package:sornaz/screens/Tuner/audio/pitch_input_native.dart';
import 'package:sornaz/screens/Players/library/device_audio_scan.dart';
import 'package:sornaz/helpers/desktop_media_channel.dart';
import 'package:sornaz/screens/Voice Recorder/services/file_service.dart';

class _PcmInput extends DesktopPitchInput {
  int? sampleRate;
  bool stopped = false;
  @override
  Future<void> start(int value) async {
    sampleRate = value;
  }

  @override
  Future<void> stop() async {
    stopped = true;
  }

  @override
  double read() => 440;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
  });
  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
  });

  test(
    'iOS tuner uses PCM instead of the unimplemented Android channel',
    () async {
      final pcm = _PcmInput();
      final input = PitchInput(pcmInput: pcm);
      await input.start(48000);
      expect(pcm.sampleRate, 48000);
      expect(await input.read(), 440);
      await input.stop();
      expect(pcm.stopped, true);
    },
  );

  test(
    'iOS library permission covers its sandbox without Android permissions',
    () async {
      expect(await hasAudioStoragePermission(request: true), true);
    },
  );

  test('iOS audio discovery only scans its documents sandbox', () async {
    final directory = await Directory.systemTemp.createTemp(
      'sornaz-ios-roots-',
    );
    const channel = MethodChannel('plugins.flutter.io/path_provider');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(
      channel,
      (call) async => call.method == 'getApplicationDocumentsDirectory'
          ? directory.path
          : null,
    );
    try {
      final roots = await discoverAudioRoots();
      expect(roots.map((item) => item.path), [directory.path]);
    } finally {
      messenger.setMockMethodCallHandler(channel, null);
      await directory.delete();
    }
  });

  test(
    'iOS audio export materializes its source through the native asset bridge',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'sornaz-ios-export-',
      );
      const paths = MethodChannel('plugins.flutter.io/path_provider');
      const native = MethodChannel('sornaz/ios_media');
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(paths, (call) async => directory.path);
      try {
        final original = await File(
          p.join(directory.path, 'آهنگ من.wav'),
        ).writeAsBytes([1, 2, 3]);
        messenger.setMockMethodCallHandler(native, (call) async {
          expect(call.method, 'materialize');
          expect(call.arguments, {'uri': original.uri.toString()});
          return (await original.copy(
            p.join(directory.path, 'staged.wav'),
          )).path;
        });
        const channel = DesktopMediaChannel('sornaz/device_videos');
        final staged = await channel.invokeMethod<String>('stageAudioSource', {
          'uri': original.uri.toString(),
        });
        expect(staged, isNot(original.path));
        expect(await File(staged!).readAsBytes(), [1, 2, 3]);
        await File(staged).delete();
        expect(await original.readAsBytes(), [1, 2, 3]);
      } finally {
        messenger.setMockMethodCallHandler(paths, null);
        messenger.setMockMethodCallHandler(native, null);
        await directory.delete(recursive: true);
      }
    },
  );
  test('iOS recording folder changes preserve existing recordings', () async {
    final root = await Directory.systemTemp.createTemp(
      'sornaz-ios-recording-folder-',
    );
    final before = await Directory(p.join(root.path, 'before')).create();
    final after = await Directory(p.join(root.path, 'after')).create();
    final recording = await File(
      p.join(before.path, 'keep.m4a'),
    ).writeAsString('original');
    const paths = MethodChannel('plugins.flutter.io/path_provider');
    const workspace = MethodChannel('sornaz/recording_workspace');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(paths, (call) async => root.path);
    messenger.setMockMethodCallHandler(
      workspace,
      (call) async => call.method == 'location' ? before.path : after.path,
    );
    try {
      final service = FileService();
      await service.init();
      expect(await service.location(), before.path);
      await service.chooseLocation();
      expect(await service.location(), after.path);
      expect(p.dirname(service.newPath()), after.path);
      expect(await recording.readAsString(), 'original');
    } finally {
      messenger.setMockMethodCallHandler(paths, null);
      messenger.setMockMethodCallHandler(workspace, null);
      await root.delete(recursive: true);
    }
  });
  test(
    'iOS FFmpeg composes a portable draft for native H.264 finalization',
    () {
      expect(DesktopMedia.videoEncoder, contains('mpeg4'));
      expect(DesktopMedia.videoEncoder, isNot(contains('h264_mf')));
    },
  );
  for (final outcome in ['success', 'failure', 'empty']) {
    test('iOS video finalization preserves drafts on $outcome', () async {
      final root = await Directory.systemTemp.createTemp('sornaz-ios-encode-');
      const paths = MethodChannel('plugins.flutter.io/path_provider');
      const native = MethodChannel('sornaz/ios_media');
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(paths, (call) async => root.path);
      File? output;
      try {
        final source = await DesktopMedia.draft('mp4');
        await source.writeAsBytes([1, 2, 3]);
        messenger.setMockMethodCallHandler(native, (call) async {
          expect(call.method, 'encodeVideo');
          final args = call.arguments as Map;
          expect(args['path'], source.path);
          output = File(args['output'] as String);
          await output!.writeAsBytes(outcome == 'empty' ? [] : [4, 5, 6]);
          if (outcome == 'failure') {
            throw PlatformException(code: 'IOS_MEDIA');
          }
          return null;
        });
        if (outcome == 'success') {
          final finished = await DesktopMedia.finishVideo(source);
          expect(await finished.readAsBytes(), [4, 5, 6]);
          expect(await source.exists(), false);
        } else {
          await expectLater(
            DesktopMedia.finishVideo(source),
            throwsA(
              outcome == 'empty' ? isA<StateError>() : isA<PlatformException>(),
            ),
          );
          expect(await source.readAsBytes(), [1, 2, 3]);
          expect(await output!.exists(), false);
        }
      } finally {
        messenger.setMockMethodCallHandler(paths, null);
        messenger.setMockMethodCallHandler(native, null);
        await root.delete(recursive: true);
      }
    });
  }
  test('iOS gallery forwards pagination and limited-photo responses', () async {
    const native = MethodChannel('sornaz/ios_media');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(native, (call) async {
      if (call.method == 'permission') return 'limited';
      expect(call.method, 'gallery');
      expect(call.arguments, {'offset': 60});
      return [
        {'uri': 'ph://asset/L0/001', 'video': true},
      ];
    });
    try {
      const channel = DesktopMediaChannel('sornaz/story_media');
      expect(await channel.invokeMethod<String>('permission'), 'limited');
      final rows = await channel.invokeListMethod('gallery', {'offset': 60});
      expect((rows!.single as Map)['uri'], 'ph://asset/L0/001');
    } finally {
      messenger.setMockMethodCallHandler(native, null);
    }
  });
}
