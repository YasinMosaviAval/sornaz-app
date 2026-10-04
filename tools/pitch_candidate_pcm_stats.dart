// Bounded-memory host audit of Phase 3 output; source files are never edited.
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

void main() {
  final out = File('pitch_candidate_pcm_stats.csv').openWrite();
  out.writeln(
    'caseId,pcmFormat,pcmFrames,pcmSeconds,rms,peak,clippedFrames,'
    'leadingBelow003Seconds,trailingBelow003Seconds',
  );
  final dir = Directory('.pitch_candidate_tmp');
  for (final file in dir.listSync().whereType<File>()) {
    if (!file.path.endsWith('.f32le')) continue;
    final id = file.uri.pathSegments.last.replaceFirst('.f32le', '');
    final handle = file.openSync();
    var frames = 0;
    var sumSq = 0.0;
    var peak = 0.0;
    var clipped = 0;
    var leadingHops = 0;
    var trailingHops = 0;
    var seenAboveThreshold = false;
    try {
      while (true) {
        final bytes = handle.readSync(512 * 4);
        if (bytes.isEmpty) break;
        if (bytes.length % 4 != 0) throw FormatException('partial float32');
        final data = ByteData.sublistView(Uint8List.fromList(bytes));
        var localSq = 0.0;
        for (var i = 0; i < bytes.length; i += 4) {
          final sample = data.getFloat32(i, Endian.little);
          if (!sample.isFinite) throw FormatException('non-finite PCM');
          final abs = sample.abs();
          peak = math.max(peak, abs);
          if (abs >= 1) clipped++;
          localSq += sample * sample;
          frames++;
        }
        sumSq += localSq;
        final below = math.sqrt(localSq / (bytes.length ~/ 4)) < .003;
        if (below) {
          if (!seenAboveThreshold) leadingHops++;
          trailingHops++;
        } else {
          seenAboveThreshold = true;
          trailingHops = 0;
        }
      }
    } finally {
      handle.closeSync();
    }
    out.writeln(
      '$id,mono-44100-f32le,$frames,${frames / 44100},'
      '${math.sqrt(sumSq / frames)},$peak,$clipped,'
      '${leadingHops * 512 / 44100},${trailingHops * 512 / 44100}',
    );
  }
  out.close();
}
