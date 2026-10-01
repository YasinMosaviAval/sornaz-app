import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:sornaz/screens/Notation/analysis_audio.dart';

class FakeDecoder implements AnalysisAudioDecoder {
  FakeDecoder(this.decoded);
  final DecodedPcmFile decoded;
  bool cancelled = false;
  @override
  Future<DecodedPcmFile> decode(
    AnalysisAudioSource source,
    AnalysisCancellation cancellation,
  ) async => decoded;
  @override
  Future<void> cancel() async => cancelled = true;
}

Uint8List s16(List<int> samples) {
  final bytes = ByteData(samples.length * 2);
  for (var i = 0; i < samples.length; i++) {
    bytes.setInt16(i * 2, samples[i], Endian.little);
  }
  return bytes.buffer.asUint8List();
}

List<double> floats(Uint8List bytes) {
  final data = ByteData.sublistView(bytes);
  return [
    for (var offset = 0; offset < bytes.length; offset += 4)
      data.getFloat32(offset, Endian.little),
  ];
}

void main() {
  late Directory directory;
  setUp(
    () async =>
        directory = await Directory.systemTemp.createTemp('analysis-test-'),
  );
  tearDown(() async {
    if (await directory.exists()) await directory.delete(recursive: true);
  });

  test(
    'stereo downmix preserves relative amplitude and signed polarity',
    () async {
      final file = File('${directory.path}/output.f32le');
      final frames = await convertS16ToAnalysisPcm(
        Stream.value(s16([16384, 16384, -16384, -16384])),
        file,
        sampleRate: 44100,
        channels: 2,
      );
      expect(frames, 2);
      expect(floats(await file.readAsBytes()), [0.5, -0.5]);
    },
  );

  test(
    'resampling spans chunk boundaries without loading entire stream',
    () async {
      final file = File('${directory.path}/output.f32le');
      final bytes = s16([0, 16384, 0]);
      final frames = await convertS16ToAnalysisPcm(
        Stream.fromIterable([
          bytes.sublist(0, 1),
          bytes.sublist(1, 4),
          bytes.sublist(4),
        ]),
        file,
        sampleRate: 22050,
        channels: 1,
      );
      expect(frames, 6);
      expect(floats(await file.readAsBytes()), [0, 0.25, 0.5, 0.25, 0, 0]);
    },
  );

  test('incomplete PCM frame fails and deletes partial output', () async {
    final file = File('${directory.path}/partial.f32le');
    await expectLater(
      convertS16ToAnalysisPcm(
        Stream.value([0, 1, 2]),
        file,
        sampleRate: 44100,
        channels: 2,
      ),
      throwsA(
        isA<AnalysisAudioException>().having(
          (error) => error.code,
          'code',
          AnalysisAudioErrorCode.invalidData,
        ),
      ),
    );
    expect(await file.exists(), false);
  });

  test('preparer reports missing source before invoking decoder', () async {
    final decoder = FakeDecoder(
      DecodedPcmFile(
        File('${directory.path}/unused.s16le'),
        const AudioMetadata(
          sourceSampleRate: 44100,
          sourceChannels: 1,
          duration: Duration.zero,
          mimeType: 'audio/mp4a-latm',
        ),
      ),
    );
    final preparer = AnalysisAudioPreparer(decoder, workspace: directory);
    await expectLater(
      preparer.prepare(
        AnalysisAudioSource.file('${directory.path}/missing.m4a'),
      ),
      throwsA(
        isA<AnalysisAudioException>().having(
          (error) => error.code,
          'code',
          AnalysisAudioErrorCode.missingFile,
        ),
      ),
    );
  });

  test(
    'source abstraction classifies public recording URI without recorder',
    () {
      expect(
        AnalysisAudioSource.fromLocation('content://media/1').isContentUri,
        true,
      );
      expect(
        AnalysisAudioSource.fromLocation('/private/1.m4a').isContentUri,
        false,
      );
    },
  );

  test(
    'preparer consumes decoded temp, retains original and owns output',
    () async {
      final original = File('${directory.path}/recording.m4a')
        ..writeAsBytesSync([1, 2, 3]);
      final decoded = File('${directory.path}/decoded.s16le')
        ..writeAsBytesSync(s16([0, 16384]));
      final decoder = FakeDecoder(
        DecodedPcmFile(
          decoded,
          const AudioMetadata(
            sourceSampleRate: 44100,
            sourceChannels: 1,
            duration: Duration(milliseconds: 1),
            mimeType: 'audio/mp4a-latm',
          ),
        ),
      );
      final output = await AnalysisAudioPreparer(
        decoder,
        workspace: directory,
      ).prepare(AnalysisAudioSource.file(original.path));
      expect(output.format.sampleRate, 44100);
      expect(output.format.channels, 1);
      expect(output.frames, 2);
      expect(floats(await output.file.readAsBytes()), [0, 0.5]);
      expect(await decoded.exists(), false);
      expect(await original.readAsBytes(), [1, 2, 3]);
      await output.dispose();
      expect(await output.file.exists(), false);
    },
  );

  test(
    'invalid decoded format reports error and cleans temporary file',
    () async {
      final original = File('${directory.path}/recording.m4a')
        ..writeAsBytesSync([1]);
      final decoded = File('${directory.path}/decoded.s16le')
        ..writeAsBytesSync(s16([1]));
      final decoder = FakeDecoder(
        DecodedPcmFile(
          decoded,
          const AudioMetadata(
            sourceSampleRate: 0,
            sourceChannels: 1,
            duration: Duration.zero,
            mimeType: 'audio/mp4a-latm',
          ),
        ),
      );
      await expectLater(
        AnalysisAudioPreparer(
          decoder,
          workspace: directory,
        ).prepare(AnalysisAudioSource.file(original.path)),
        throwsA(
          isA<AnalysisAudioException>().having(
            (error) => error.code,
            'code',
            AnalysisAudioErrorCode.unsupportedFormat,
          ),
        ),
      );
      expect(await decoded.exists(), false);
      expect(await original.exists(), true);
    },
  );

  test('pre-cancelled work fails without modifying the source', () async {
    final original = File('${directory.path}/recording.m4a')
      ..writeAsBytesSync([1, 2]);
    final token = AnalysisCancellation()..cancel();
    final decoder = FakeDecoder(
      DecodedPcmFile(
        File('${directory.path}/unused.s16le'),
        const AudioMetadata(
          sourceSampleRate: 44100,
          sourceChannels: 1,
          duration: Duration.zero,
          mimeType: 'audio/mp4a-latm',
        ),
      ),
    );
    await expectLater(
      AnalysisAudioPreparer(
        decoder,
        workspace: directory,
      ).prepare(AnalysisAudioSource.file(original.path), cancellation: token),
      throwsA(
        isA<AnalysisAudioException>().having(
          (error) => error.code,
          'code',
          AnalysisAudioErrorCode.cancelled,
        ),
      ),
    );
    expect(await original.readAsBytes(), [1, 2]);
  });

  test('cancellation during streaming removes partial PCM output', () async {
    final cancellation = AnalysisCancellation();
    final file = File('${directory.path}/cancel.f32le');
    final input = StreamController<List<int>>();
    final result = convertS16ToAnalysisPcm(
      input.stream,
      file,
      sampleRate: 44100,
      channels: 1,
      cancellation: cancellation,
    );
    input.add(s16([100, 100]));
    await Future<void>.delayed(Duration.zero);
    cancellation.cancel();
    input.add(s16([100]));
    await input.close();
    await expectLater(
      result,
      throwsA(
        isA<AnalysisAudioException>().having(
          (error) => error.code,
          'code',
          AnalysisAudioErrorCode.cancelled,
        ),
      ),
    );
    expect(await file.exists(), false);
  });
}
