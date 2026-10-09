import 'dart:io';

import 'package:ffmpeg_kit_flutter_new_audio/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new_audio/return_code.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

enum AudioExportFormat { mp3, m4a, wav, flac, ogg }

class VideoAudioExport {
  static const _channel = MethodChannel('sornaz/device_videos');

  static List<String> arguments(
    String input,
    String output,
    AudioExportFormat format,
  ) => [
    '-y',
    '-i',
    input,
    '-map',
    '0:a:0',
    '-vn',
    switch (format) {
      AudioExportFormat.mp3 => '-codec:a',
      AudioExportFormat.m4a => '-codec:a',
      AudioExportFormat.wav => '-codec:a',
      AudioExportFormat.flac => '-codec:a',
      AudioExportFormat.ogg => '-codec:a',
    },
    switch (format) {
      AudioExportFormat.mp3 => 'libmp3lame',
      AudioExportFormat.m4a => 'aac',
      AudioExportFormat.wav => 'pcm_s16le',
      AudioExportFormat.flac => 'flac',
      AudioExportFormat.ogg => 'libvorbis',
    },
    if (format == AudioExportFormat.mp3) ...['-q:a', '2'],
    if (format == AudioExportFormat.m4a) ...['-b:a', '192k'],
    output,
  ];

  static Future<String> convert(String uri, AudioExportFormat format) async {
    final source = await _channel.invokeMethod<String>('stageAudioSource', {
      'uri': uri,
    });
    if (source == null) throw StateError('Could not read video');
    final output = File(
      '${(await getTemporaryDirectory()).path}/audio-export-${DateTime.now().microsecondsSinceEpoch}.${format.name}',
    );
    try {
      final session = await FFmpegKit.executeWithArguments(
        arguments(source, output.path, format),
      );
      if (!ReturnCode.isSuccess(await session.getReturnCode()) ||
          !await output.exists() ||
          await output.length() == 0) {
        throw StateError(
          'Audio conversion failed: ${await session.getOutput()}',
        );
      }
      return await _channel.invokeMethod<String>('saveAudioExport', {
            'path': output.path,
            'format': format.name,
          }) ??
          (throw StateError('Could not save audio'));
    } finally {
      final staged = File(source);
      if (await staged.exists()) await staged.delete();
      if (await output.exists()) await output.delete();
    }
  }
}
