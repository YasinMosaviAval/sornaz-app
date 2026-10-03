import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:sornaz/screens/Notation/analysis_audio.dart';
import 'package:sornaz/screens/Notation/music_analysis_calibration.dart';
import 'package:sornaz/screens/Notation/music_analysis_ffi.dart';
import 'package:sornaz/screens/Notation/performance_assessment.dart';

class _FixtureDecoder implements AnalysisAudioDecoder {
  _FixtureDecoder(this.file);
  final File file;
  @override
  Future<DecodedPcmFile> decode(
    AnalysisAudioSource source,
    AnalysisCancellation cancellation,
  ) async {
    cancellation.throwIfCancelled();
    return DecodedPcmFile(
      file,
      const AudioMetadata(
        sourceSampleRate: 44100,
        sourceChannels: 1,
        duration: Duration(seconds: 1),
        mimeType: 'audio/wav',
      ),
    );
  }

  @override
  Future<void> cancel() async {}
}

void main() {
  final libraryPath =
      Platform.environment['SORNAZ_MA_TEST_LIBRARY'] ??
      (Platform.isWindows
          ? '.native-host-prod/Release/music_analysis_dsp.dll'
          : '.native-host-prod/libmusic_analysis_dsp.so');
  test(
    'Phase 3 -> Phase 5 -> alignment -> structured JSON and CSV',
    skip: File(libraryPath).existsSync() ? false : 'Production host DLL absent',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'ma-calibration-',
      );
      try {
        final original = File('${directory.path}/original.wav');
        await original.writeAsBytes([1, 2, 3]);
        final raw = File('${directory.path}/decoded.s16le');
        const rate = 44100;
        final bytes = ByteData(rate * 2);
        for (var i = 0; i < rate; i++) {
          final hz = i < rate ~/ 2 ? 440.0 : 493.883;
          bytes.setInt16(
            i * 2,
            (15000 * math.sin(2 * math.pi * hz * i / rate)).round(),
            Endian.little,
          );
        }
        await raw.writeAsBytes(bytes.buffer.asUint8List());
        final runner = MusicAnalysisCalibrationRunner(
          AnalysisAudioPreparer(_FixtureDecoder(raw), workspace: directory),
          MusicAnalysisFfi.open(libraryPath: libraryPath),
        );
        final result = await runner.run(
          CalibrationCase(
            id: 'take_1',
            instrument: 'synthetic_sine',
            source: AnalysisAudioSource.file(original.path),
            musicXml:
                '''<score-partwise version="4.0"><part-list><score-part id="P1"><part-name>Piano</part-name></score-part></part-list><part id="P1"><measure number="1"><attributes><divisions>1</divisions><time><beats>2</beats><beat-type>4</beat-type></time></attributes><note><pitch><step>A</step><octave>4</octave></pitch><duration>1</duration></note><note><pitch><step>B</step><octave>4</octave></pitch><duration>1</duration></note></measure></part></score-partwise>''',
            truthByReferenceId: const {
              'P1:0:0': CalibrationTruthNote(
                midiPitch: 69,
                startSeconds: 0,
                endSeconds: 0.5,
              ),
            },
          ),
        );
        expect(await original.readAsBytes(), [1, 2, 3]);
        expect(await raw.exists(), false);
        final json = result.toJson();
        expect(json['schemaVersion'], 1);
        expect(json['pcmFormat'], 'mono-44100-f32le');
        expect(json['pcmFrames'], rate);
        expect(json['rawFeatureFrames'], greaterThan(0));
        expect(json['dspEngine'], 'open');
        final notes = json['notes'] as List<dynamic>;
        expect(notes.length, greaterThanOrEqualTo(2));
        expect(notes.first['pitchErrorVsTruthCents'], isA<double>());
        expect(notes.last['truthMidiPitch'], isNull);
        expect(result.toCsv(), contains('onsetBeatOffset'));
        await result.writeTo(directory);
        expect(
          jsonDecode(
            await File('${directory.path}/take_1.json').readAsString(),
          )['caseId'],
          'take_1',
        );
        expect(
          (await File('${directory.path}/take_1.csv').readAsLines()).length,
          notes.length + 1,
        );
      } finally {
        await directory.delete(recursive: true);
      }
    },
  );

  test('unsafe case IDs cannot be used as output paths', () async {
    final result = CalibrationResult(
      '../escape',
      '',
      const PerformanceReport(
        notes: [],
        markCounts: {},
        estimatedQuarterBpm: null,
        medianAbsolutePitchCents: null,
        medianAbsoluteOnsetBeats: null,
        medianDurationRatio: null,
        medianSoundStrengthRms: null,
      ),
      const {},
    );
    final dir = await Directory.systemTemp.createTemp('ma-safe-');
    try {
      await expectLater(result.writeTo(dir), throwsFormatException);
    } finally {
      await dir.delete(recursive: true);
    }
  });
}
