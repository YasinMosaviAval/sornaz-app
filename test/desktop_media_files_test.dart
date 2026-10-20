import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sornaz/helpers/desktop_media_channel.dart';
import 'package:sornaz/screens/Voice%20Recorder/services/file_service_native.dart';
import 'package:sornaz/screens/Voice%20Recorder/services/recording_waveforms.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'recording rename preserves native paths and never overwrites another recording',
    () async {
      SharedPreferences.setMockInitialValues({});
      final directory = await Directory.systemTemp.createTemp(
        'sornaz-recording-rename-test-',
      );
      try {
        final source = await File(
          p.join(directory.path, 'original.m4a'),
        ).writeAsString('original recording');
        final other = await File(
          p.join(directory.path, 'taken.m4a'),
        ).writeAsString('keep other recording');
        final item = SavedRecording(
          uri: source.path,
          name: 'original.m4a',
          modified: DateTime.now(),
        );
        final service = FileService();
        await expectLater(
          service.rename(item, 'taken'),
          throwsA(isA<FileSystemException>()),
        );
        expect(await source.readAsString(), 'original recording');
        expect(await other.readAsString(), 'keep other recording');
        await RecordingWaveforms.save(source.path, [.2, .8]);
        await service.rename(item, 'renamed');
        final renamed = File(p.join(directory.path, 'renamed.m4a'));
        expect(await renamed.readAsString(), 'original recording');
        final listed =
            (await directory
                    .list()
                    .where((f) => p.basename(f.path) == 'renamed.m4a')
                    .toList())
                .single;
        expect(await RecordingWaveforms.cached(listed.path), [.2, .8]);
      } finally {
        await directory.delete(recursive: true);
      }
    },
  );
  test(
    'private media cleanup cannot access files outside its workspace',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'sornaz-private-files-test-',
      );
      const channel = MethodChannel('plugins.flutter.io/path_provider');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            channel,
            (call) async =>
                call.method == 'getTemporaryDirectory' ? directory.path : null,
          );
      try {
        final original = await File(
          p.join(directory.path, 'keep-original.txt'),
        ).writeAsString('private source');
        await expectLater(
          DesktopMedia.privateFile(original.path),
          throwsA(isA<FileSystemException>()),
        );
        expect(await original.readAsString(), 'private source');
        final draft = await DesktopMedia.draft('txt');
        await draft.writeAsString('temporary media');
        expect((await DesktopMedia.privateFile(draft.path)).path, draft.path);
      } finally {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null);
        await directory.delete(recursive: true);
      }
    },
  );
  test('Windows file URI preserves Persian names and spaces', () {
    final original = p.join(Directory.systemTemp.path, 'آهنگ من 100%.m4a');
    expect(DesktopMedia.path(File(original).uri.toString()), original);
  });
  test(
    'crop save preserves original until replace is explicitly chosen',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'sornaz-crop-test-',
      );
      try {
        final original = File(p.join(directory.path, 'original.m4a'));
        final staged = File(p.join(directory.path, 'staged.m4a'));
        await original.writeAsString('original audio');
        await staged.writeAsString('cropped audio');
        final copy = await DesktopMedia.commit(staged, original.path, false);
        expect(await original.readAsString(), 'original audio');
        expect(await File(copy).readAsString(), 'cropped audio');
        expect(await staged.readAsString(), 'cropped audio');
        final replacement = await DesktopMedia.commit(
          staged,
          original.path,
          true,
        );
        expect(replacement, original.path);
        expect(await original.readAsString(), 'cropped audio');
        expect(
          (await directory.list().toList()).any(
            (f) => f.path.contains('sornaz-backup'),
          ),
          false,
        );
      } finally {
        await directory.delete(recursive: true);
      }
    },
  );
  test('missing staged output leaves the original recording intact', () async {
    final directory = await Directory.systemTemp.createTemp(
      'sornaz-crop-failure-',
    );
    try {
      final original = File(p.join(directory.path, 'original.m4a'));
      await original.writeAsString('keep original');
      await expectLater(
        DesktopMedia.commit(
          File(p.join(directory.path, 'missing.m4a')),
          original.path,
          true,
        ),
        throwsA(isA<FileSystemException>()),
      );
      expect(await original.readAsString(), 'keep original');
    } finally {
      await directory.delete(recursive: true);
    }
  });
}
