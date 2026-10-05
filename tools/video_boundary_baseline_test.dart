// Run with flutter test --no-pub tools/video_boundary_baseline_test.dart after
// extracting each video's untrimmed AAC track to .video_boundary_tmp/Vxx.s16le
// as interleaved 48-kHz stereo signed-16 PCM. The temporary files are local.
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:sornaz/screens/Notation/analysis_audio.dart';
import 'package:sornaz/screens/Notation/music_analysis_ffi.dart';
import 'package:sornaz/screens/Notation/music_analysis_features.dart';
import 'package:sornaz/screens/Notation/performed_notes.dart';

void main() {
  test('freeze video audio Phase 3 -> FFI -> segmentation baseline', () async {
    final ffi = MusicAnalysisFfi.open(
      libraryPath: '.native-host-prod/Release/music_analysis_dsp.dll',
    );
    final featuresOut = File('video_boundary_raw_features.csv').openWrite();
    final notesOut = File('video_segmentation_baseline.csv').openWrite();
    final extractionOut = File('video_audio_extraction.csv').openWrite();
    featuresOut.writeln(
      'case_id,start_sample,valid_samples,onset_sample,timestamp_seconds,pitch_hz,confidence,rms,energy,peak,onset_strength,onset_candidate,is_silent,is_partial',
    );
    notesOut.writeln(
      'case_id,segment_index,start_sample,end_sample,start_seconds,end_seconds,duration_seconds,representative_pitch_hz,fractional_midi,rounded_midi,mean_confidence,mean_rms',
    );
    extractionOut.writeln(
      'case_id,extracted_source_pcm_format,source_sample_rate,source_channels,decoded_source_frames,canonical_pcm_format,canonical_sample_rate,canonical_channels,canonical_frames,canonical_duration_seconds,feature_count,segment_count',
    );
    for (var i = 1; i <= 4; i++) {
      final id = 'V${i.toString().padLeft(2, '0')}';
      final input = File('.video_boundary_tmp/$id.s16le');
      final sourceFrames = input.lengthSync() ~/ 4;
      final canonical = File('.video_boundary_tmp/$id.f32le');
      final frames = await convertS16ToAnalysisPcm(
        input.openRead(),
        canonical,
        sampleRate: 48000,
        channels: 2,
      );
      expect(canonical.lengthSync(), frames * 4);
      final pcm = PcmAudioData(
        file: canonical,
        format: PcmFormat.analysis,
        frames: frames,
        sourceMetadata: AudioMetadata(
          sourceSampleRate: 48000,
          sourceChannels: 2,
          duration: Duration(
            microseconds: (sourceFrames * 1000000 / 48000).round(),
          ),
          mimeType: 'video/mp4',
        ),
      );
      final features = await ffi.extract(pcm).toList();
      for (final f in features) {
        featuresOut.writeln(
          '$id,${f.frameStartSample},${f.frameValidSamples},${f.onsetSample},${f.timestampSeconds},${f.pitchHz},${f.pitchConfidence},${f.rms},${f.energy},${f.peakAbs},${f.onsetStrength},${f.onsetCandidate ? 1 : 0},${f.isSilent ? 1 : 0},${f.isPartial ? 1 : 0}',
        );
      }
      final notes = await const PerformedNoteSegmenter()
          .segment(Stream<RawAudioFeature>.fromIterable(features))
          .toList();
      for (var j = 0; j < notes.length; j++) {
        final n = notes[j], midi = n.midiPitch;
        notesOut.writeln(
          '$id,${j + 1},${(n.startSeconds * 44100).round()},${(n.endSeconds * 44100).round()},${n.startSeconds},${n.endSeconds},${n.durationSeconds},${440 * math.pow(2, (midi - 69) / 12)},$midi,${midi.round()},${n.pitchConfidence},${n.rms}',
        );
      }
      extractionOut.writeln(
        '$id,s16le,48000,2,$sourceFrames,f32le,44100,1,$frames,${frames / 44100},${features.length},${notes.length}',
      );
      await pcm.dispose();
      stdout.writeln(
        '$id sourceFrames=$sourceFrames canonicalFrames=$frames features=${features.length} notes=${notes.length}',
      );
    }
    await featuresOut.close();
    await notesOut.close();
    await extractionOut.close();
  }, timeout: const Timeout(Duration(minutes: 10)));
}
