import 'package:flutter_test/flutter_test.dart';
import 'package:sornaz/screens/Players/services/video_audio_export.dart';

void main() {
  test(
    'audio conversion selects a real codec and excludes video for each format',
    () {
      const expected = {
        AudioExportFormat.mp3: 'libmp3lame',
        AudioExportFormat.m4a: 'aac',
        AudioExportFormat.wav: 'pcm_s16le',
        AudioExportFormat.flac: 'flac',
        AudioExportFormat.ogg: 'libvorbis',
      };
      for (final entry in expected.entries) {
        final args = VideoAudioExport.arguments(
          '/some input/video.mp4',
          '/some output/audio.${entry.key.name}',
          entry.key,
        );
        expect(args, containsAllInOrder(['-i', '/some input/video.mp4']));
        expect(args, containsAllInOrder(['-map', '0:a:0', '-vn']));
        expect(args, containsAllInOrder(['-codec:a', entry.value]));
        expect(args.last, '/some output/audio.${entry.key.name}');
      }
    },
  );
}
