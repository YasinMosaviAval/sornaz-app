// Host-only reproduction of the existing Phase 3 converter for exact-window
// native diagnostics. Audio is decoded from the same videos beforehand.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sornaz/screens/Notation/analysis_audio.dart';

void main() {
  test('prepare canonical video PCM without changing production', () async {
    final output = Directory('.raw_voicing_tmp')..createSync();
    for (var i = 1; i <= 4; ++i) {
      final id = 'V${i.toString().padLeft(2, '0')}';
      final input = File('.video_boundary_tmp/$id.s16le');
      final pcm = File('${output.path}/$id.f32le');
      final count = await convertS16ToAnalysisPcm(
        input.openRead(),
        pcm,
        sampleRate: 48000,
        channels: 2,
      );
      expect(pcm.lengthSync(), count * 4);
      stdout.writeln('$id canonicalFrames=$count');
    }
  });
}
