import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:sornaz/screens/Notation/analysis_audio.dart';
import 'package:sornaz/screens/Notation/music_analysis_ffi.dart';
import 'package:sornaz/screens/Notation/note_alignment.dart';
import 'package:sornaz/screens/Notation/performance_assessment.dart';
import 'package:sornaz/screens/Notation/performed_notes.dart';
import 'package:sornaz/screens/Notation/reference_timeline.dart';

void main() {
  final libraryPath =
      Platform.environment['SORNAZ_MA_TEST_LIBRARY'] ??
      (Platform.isWindows
          ? '.native-host-prod/Release/music_analysis_dsp.dll'
          : '.native-host-prod/libmusic_analysis_dsp.so');
  test(
    'short synthetic PCM through FFI, segmentation, alignment and assessment',
    skip: File(libraryPath).existsSync()
        ? false
        : 'Production host native library unavailable',
    () async {
      final directory = await Directory.systemTemp.createTemp('ma-phase7-');
      try {
        const rate = 44100;
        final file = File('${directory.path}/take.f32le');
        final data = ByteData(rate * 4);
        for (var i = 0; i < rate; i++) {
          final hz = i < rate ~/ 2 ? 440.0 : 493.883;
          data.setFloat32(
            i * 4,
            0.4 * math.sin(2 * math.pi * hz * i / rate),
            Endian.little,
          );
        }
        await file.writeAsBytes(data.buffer.asUint8List());
        final audio = PcmAudioData(
          file: file,
          format: PcmFormat.analysis,
          frames: rate,
          sourceMetadata: const AudioMetadata(
            sourceSampleRate: rate,
            sourceChannels: 1,
            duration: Duration(seconds: 1),
            mimeType: 'audio/pcm',
          ),
        );
        final notes = await const PerformedNoteSegmenter()
            .segment(
              MusicAnalysisFfi.open(libraryPath: libraryPath).extract(audio),
            )
            .toList();
        final score = const ReferenceTimelineParser().parse('''
<score-partwise version="4.0"><part-list><score-part id="P1"><part-name>Piano</part-name></score-part></part-list>
<part id="P1"><measure number="1"><attributes><divisions>1</divisions><time><beats>2</beats><beat-type>4</beat-type></time></attributes>
<note><pitch><step>A</step><octave>4</octave></pitch><duration>1</duration></note>
<note><pitch><step>B</step><octave>4</octave></pitch><duration>1</duration></note>
</measure></part></score-partwise>''');
        final alignment = const ReferenceNoteAligner().align(score, notes);
        final report = const PerformanceAssessor().assess(score, alignment);
        final matched = report.notes
            .where((n) => n.mark == AlignmentMark.matched)
            .toList();
        // Capture observed host-DSP numbers for the phase report.
        // ignore: avoid_print
        print('phase7 integration: performed=${notes.length}, matched=${matched.length}, '
            'pitchCents=${matched.map((n) => n.pitchCents).toList()}, '
            'medianRms=${report.medianSoundStrengthRms}, '
            'medianDurationRatio=${report.medianDurationRatio}');
        expect(matched.length, greaterThanOrEqualTo(2));
        expect(matched.first.pitchCents!.abs(), lessThan(100));
        expect(matched.last.pitchCents!.abs(), lessThan(100));
        expect(report.medianSoundStrengthRms, greaterThan(0));
        expect(report.medianDurationRatio, greaterThan(0));
      } finally {
        await directory.delete(recursive: true);
      }
    },
  );
}
