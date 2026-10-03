import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:sornaz/screens/Notation/analysis_audio.dart';
import 'package:sornaz/screens/Notation/music_analysis_ffi.dart';
import 'package:sornaz/screens/Notation/note_alignment.dart';
import 'package:sornaz/screens/Notation/performed_notes.dart';
import 'package:sornaz/screens/Notation/reference_timeline.dart';

void main() {
  final libraryPath =
      Platform.environment['SORNAZ_MA_TEST_LIBRARY'] ??
      (Platform.isWindows
          ? '.native-host-prod/Release/music_analysis_dsp.dll'
          : '.native-host-prod/libmusic_analysis_dsp.so');
  test(
    'synthetic PCM file -> open native features -> performed notes -> alignment',
    skip: File(libraryPath).existsSync()
        ? false
        : 'Production host native library unavailable',
    () async {
      final directory = await Directory.systemTemp.createTemp('ma-phase6-');
      final file = File('${directory.path}/two-tones.f32le');
      try {
        const sampleRate = 44100;
        final samples = ByteData(sampleRate * 4);
        for (var i = 0; i < sampleRate; i++) {
          final hz = i < sampleRate ~/ 2 ? 440.0 : 493.883;
          samples.setFloat32(
            i * 4,
            0.45 * math.sin(2 * math.pi * hz * i / sampleRate),
            Endian.little,
          );
        }
        await file.writeAsBytes(samples.buffer.asUint8List());
        final pcm = PcmAudioData(
          file: file,
          format: PcmFormat.analysis,
          frames: sampleRate,
          sourceMetadata: const AudioMetadata(
            sourceSampleRate: sampleRate,
            sourceChannels: 1,
            duration: Duration(seconds: 1),
            mimeType: 'audio/pcm',
          ),
        );
        final notes = await const PerformedNoteSegmenter()
            .segment(
              MusicAnalysisFfi.open(libraryPath: libraryPath).extract(pcm),
            )
            .toList();
        expect(notes.length, greaterThanOrEqualTo(2));
        expect(notes.first.midiPitch, closeTo(69, 1));
        expect(notes.last.midiPitch, closeTo(71, 1));
        final score = const ReferenceTimelineParser().parse('''
<score-partwise version="4.0"><part-list><score-part id="P1"><part-name>Piano</part-name></score-part></part-list>
<part id="P1"><measure number="1"><attributes><divisions>1</divisions><time><beats>2</beats><beat-type>4</beat-type></time></attributes>
<note><pitch><step>A</step><octave>4</octave></pitch><duration>1</duration></note>
<note><pitch><step>B</step><octave>4</octave></pitch><duration>1</duration></note>
</measure></part></score-partwise>''');
        final result = const ReferenceNoteAligner().align(score, notes);
        expect(
          result.events.where((e) => e.mark == AlignmentMark.matched).length,
          greaterThanOrEqualTo(2),
        );
      } finally {
        await directory.delete(recursive: true);
      }
    },
  );
}
