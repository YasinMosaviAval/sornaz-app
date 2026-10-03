import 'dart:ffi' as ffi;
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:sornaz/screens/Notation/analysis_audio.dart';
import 'package:sornaz/screens/Notation/music_analysis_ffi.dart';

class _FixtureDecoder implements AnalysisAudioDecoder {
  _FixtureDecoder(this.decoded);
  final DecodedPcmFile decoded;
  @override
  Future<DecodedPcmFile> decode(
    AnalysisAudioSource source,
    AnalysisCancellation cancellation,
  ) async => decoded;
  @override
  Future<void> cancel() async {}
}

void main() {
  final libraryPath =
      Platform.environment['SORNAZ_MA_TEST_LIBRARY'] ??
      (Platform.isWindows
          ? '.native-host-prod/Release/music_analysis_dsp.dll'
          : '.native-host-prod/libmusic_analysis_dsp.so');
  final libraryExists = File(libraryPath).existsSync();
  final integrationSkip = libraryExists
      ? false
      : 'Build the Aubio-free native host library and set SORNAZ_MA_TEST_LIBRARY.';

  late Directory directory;
  setUp(
    () async => directory = await Directory.systemTemp.createTemp('ma-ffi-'),
  );
  tearDown(() async {
    if (await directory.exists()) await directory.delete(recursive: true);
  });

  PcmAudioData audio(
    List<double> samples, {
    PcmFormat format = PcmFormat.analysis,
  }) {
    final bytes = ByteData(samples.length * 4);
    for (var i = 0; i < samples.length; i++) {
      bytes.setFloat32(i * 4, samples[i], Endian.little);
    }
    final file = File('${directory.path}/test.f32le')
      ..writeAsBytesSync(bytes.buffer.asUint8List());
    return PcmAudioData(
      file: file,
      format: format,
      frames: samples.length,
      sourceMetadata: const AudioMetadata(
        sourceSampleRate: 44100,
        sourceChannels: 1,
        duration: Duration(seconds: 1),
        mimeType: 'audio/mp4',
      ),
    );
  }

  test('missing native library has a categorized error', () {
    expect(
      () => MusicAnalysisFfi.open(libraryPath: '${directory.path}/missing.dll'),
      throwsA(
        isA<MusicAnalysisException>().having(
          (error) => error.code,
          'code',
          MusicAnalysisErrorCode.libraryUnavailable,
        ),
      ),
    );
  });

  group('real production native library', () {
    late MusicAnalysisFfi analyzer;
    setUp(() => analyzer = MusicAnalysisFfi.open(libraryPath: libraryPath));

    test('contains only the open engine', () {
      final library = ffi.DynamicLibrary.open(libraryPath);
      final engines = library
          .lookupFunction<ffi.Uint32 Function(), int Function()>(
            'ma_available_engines',
          );
      expect(engines(), 1);
    });

    test('streams a 440 Hz sine with copied, timed raw features', () async {
      final samples = List<double>.generate(
        44100,
        (i) => 0.5 * math.sin(2 * math.pi * 440 * i / 44100),
      );
      final source = audio(samples);
      final features = await analyzer.extract(source).toList();
      expect(features, hasLength(87));
      expect(features.first.frameStartSample, 0);
      expect(features.last.frameStartSample, 86 * 512);
      expect(features.last.frameValidSamples, 44100 - 86 * 512);
      expect(features.last.isPartial, isTrue);
      final voiced = features
          .where((f) => f.timestampSeconds > 0.25 && f.pitchHz > 0)
          .toList();
      expect(voiced, isNotEmpty);
      final errors = voiced.map((f) => (f.pitchHz - 440).abs()).toList()
        ..sort();
      expect(errors[errors.length ~/ 2], lessThan(5));
      expect(features[10].rms, closeTo(0.3535, 0.03));
      expect(features[10].energy, closeTo(0.125, 0.02));
      expect(features[10].peakAbs, inInclusiveRange(0.49, 0.51));
      expect(features[10].pitchConfidence, inInclusiveRange(0, 1));
      expect(features[10].timestampSeconds, closeTo(10 * 512 / 44100, 1e-9));
      expect(await source.file.exists(), isTrue);
      await source.dispose();
      expect(await source.file.exists(), isFalse);
    });

    test(
      'consumes the actual Phase 3 prepared PCM without altering source',
      () async {
        final original = File('${directory.path}/original.m4a')
          ..writeAsBytesSync([1, 2, 3]);
        final decoded = File('${directory.path}/decoded.s16le');
        final signed = ByteData(44100 * 2);
        for (var i = 0; i < 44100; i++) {
          signed.setInt16(
            i * 2,
            (0.5 * 32767 * math.sin(2 * math.pi * 440 * i / 44100)).round(),
            Endian.little,
          );
        }
        decoded.writeAsBytesSync(signed.buffer.asUint8List());
        final prepared = await AnalysisAudioPreparer(
          _FixtureDecoder(
            DecodedPcmFile(
              decoded,
              const AudioMetadata(
                sourceSampleRate: 44100,
                sourceChannels: 1,
                duration: Duration(seconds: 1),
                mimeType: 'audio/mp4',
              ),
            ),
          ),
          workspace: directory,
        ).prepare(AnalysisAudioSource.file(original.path));
        try {
          final features = await analyzer.extract(prepared).toList();
          final voiced = features
              .where((f) => f.timestampSeconds > 0.25 && f.pitchHz > 0)
              .toList();
          expect(features, hasLength(87));
          expect(voiced, isNotEmpty);
          expect((voiced.first.pitchHz - 440).abs(), lessThan(5));
          expect(await decoded.exists(), isFalse);
          expect(await original.readAsBytes(), [1, 2, 3]);
        } finally {
          await prepared.dispose();
        }
      },
    );

    test('keeps silence and clipping amplitudes intact', () async {
      final silence = await analyzer
          .extract(audio(List.filled(512, 0)))
          .toList();
      expect(silence.single.isSilent, isTrue);
      expect(silence.single.pitchHz, 0);
      expect(silence.single.rms, 0);
      final clipping = await analyzer
          .extract(audio(List.filled(1024, 1)))
          .toList();
      expect(clipping.last.clippingFraction, closeTo(1, 1e-6));
      expect(clipping.last.signalQuality, closeTo(0, 1e-6));
    });

    test(
      'cancels between emitted frames and frees its native context',
      () async {
        final token = AnalysisCancellation();
        final source = audio(List<double>.filled(44100, 0.25));
        var received = 0;
        await expectLater(
          analyzer.extract(source, cancellation: token).listen((_) {
            received++;
            if (received == 1) token.cancel();
          }).asFuture<void>(),
          throwsA(
            isA<MusicAnalysisException>().having(
              (error) => error.code,
              'code',
              MusicAnalysisErrorCode.cancelled,
            ),
          ),
        );
        expect(received, 1);
        expect(await source.file.exists(), isTrue);
        // A new context still works after cancellation.
        expect(await analyzer.extract(audio(List.filled(512, 0))).length, 1);
      },
    );

    test('rejects an absent file and a pre-cancelled request', () async {
      final missing = audio([0]);
      await missing.file.delete();
      await expectLater(
        analyzer.extract(missing).toList(),
        throwsA(
          isA<MusicAnalysisException>().having(
            (error) => error.code,
            'code',
            MusicAnalysisErrorCode.missingFile,
          ),
        ),
      );
      final token = AnalysisCancellation()..cancel();
      final source = audio([0]);
      await expectLater(
        analyzer.extract(source, cancellation: token).toList(),
        throwsA(
          isA<MusicAnalysisException>().having(
            (error) => error.code,
            'code',
            MusicAnalysisErrorCode.cancelled,
          ),
        ),
      );
      expect(await source.file.exists(), isTrue);
    });

    test('rejects wrong PCM format, length and a non-finite sample', () async {
      final wrongFormat = audio([
        0,
      ], format: const PcmFormat(sampleRate: 48000));
      await expectLater(
        analyzer.extract(wrongFormat).toList(),
        throwsA(
          isA<MusicAnalysisException>().having(
            (error) => error.code,
            'code',
            MusicAnalysisErrorCode.unsupportedFormat,
          ),
        ),
      );
      final truncated = audio([0, 0])..file.writeAsBytesSync([0, 0, 0, 0]);
      await expectLater(
        analyzer.extract(truncated).toList(),
        throwsA(
          isA<MusicAnalysisException>().having(
            (error) => error.code,
            'code',
            MusicAnalysisErrorCode.invalidPcm,
          ),
        ),
      );
      final nonFinite = audio([double.nan]);
      await expectLater(
        analyzer.extract(nonFinite).toList(),
        throwsA(
          isA<MusicAnalysisException>().having(
            (error) => error.code,
            'code',
            MusicAnalysisErrorCode.invalidPcm,
          ),
        ),
      );
    });
  }, skip: integrationSkip);
}
