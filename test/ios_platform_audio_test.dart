import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sornaz/screens/Tuner/audio/desktop_pitch_input.dart';
import 'package:sornaz/screens/Tuner/audio/pitch_input_native.dart';
import 'package:sornaz/screens/Players/library/device_audio_scan.dart';
import 'package:sornaz/helpers/desktop_media_channel.dart';

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
    'iOS audio export stages a copy and preserves its original file',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'sornaz-ios-export-',
      );
      const paths = MethodChannel('plugins.flutter.io/path_provider');
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(paths, (call) async => directory.path);
      try {
        final original = await File(
          p.join(directory.path, 'آهنگ من.wav'),
        ).writeAsBytes([1, 2, 3]);
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
        await directory.delete(recursive: true);
      }
    },
  );
}
