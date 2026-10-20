import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pdf;
import 'package:image/image.dart' as image;
import 'package:video_player/video_player.dart';
import 'package:just_audio/just_audio.dart' as just;
import 'package:audioplayers/audioplayers.dart' as audio;
import 'package:metadata_god/metadata_god.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'screens/Players/services/music_audio_handler.dart';
import 'helpers/desktop_media_channel.dart';
import 'helpers/desktop_audio_duration.dart';
import 'screens/Players/services/video_audio_export.dart';
import 'screens/Notation/analysis_audio.dart';
import 'screens/Notation/music_analysis_ffi.dart';

/// Opt-in native integration checks, run from the built Windows executable.
/// Uses synthetic media only; never opens accounts, the camera or microphone.
Future<void> runDesktopSmoke(String reportPath) async {
  runApp(const SizedBox.shrink());
  final results = <String, Object>{};
  final directory = await Directory(
    p.join(
      (await getTemporaryDirectory()).path,
      'sornaz-desktop-smoke-${DateTime.now().microsecondsSinceEpoch}',
    ),
  ).create(recursive: true);
  Future<void> check(String name, Future<void> Function() action) async {
    try {
      await action().timeout(const Duration(seconds: 90));
      results[name] = 'passed';
    } catch (error, stack) {
      results[name] = {'error': '$error', 'stack': '$stack'};
    }
    await File(
      reportPath,
    ).writeAsString(const JsonEncoder.withIndent('  ').convert(results));
  }

  void require(bool value, String message) {
    if (!value) throw StateError(message);
  }

  final wav = File(p.join(directory.path, 'آزمون صدا.wav'));
  final video = File(p.join(directory.path, 'آزمون ویدیو.mp4'));
  try {
    await check('platform_secure_storage', () async {
      const storage = FlutterSecureStorage();
      final key =
          'sornaz.desktop.smoke.${DateTime.now().microsecondsSinceEpoch}';
      try {
        await storage.write(key: key, value: 'synthetic-test-value');
        require(
          await storage.read(key: key) == 'synthetic-test-value',
          'Secure storage round trip failed',
        );
      } finally {
        await storage.delete(key: key);
      }
    });
    await check('platform_system_media_controls', () async {
      final handler = await AudioService.init<MusicAudioHandler>(
        builder: () => MusicAudioHandler(),
        config: const AudioServiceConfig(
          androidNotificationChannelId: 'com.example.sornaz.music',
          androidNotificationChannelName: 'Sornaz music',
        ),
      );
      handler.mediaItem.add(
        MediaItem(id: 'smoke-test', title: 'Sornaz synthetic media test'),
      );
      handler.playbackState.add(
        PlaybackState(
          controls: [MediaControl.play, MediaControl.stop],
          processingState: AudioProcessingState.ready,
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 200));
      await handler.stop();
    });
    await check('native_audio_generation', () async {
      await DesktopMedia.run([
        '-f',
        'lavfi',
        '-i',
        'sine=frequency=440:duration=1',
        '-ar',
        '44100',
        '-ac',
        '1',
        wav.path,
      ]);
      require(await wav.length() > 44000, 'Synthetic audio missing');
      require(
        await DesktopMedia.duration(wav.path) > 900,
        'FFprobe duration incorrect',
      );
    });
    await check('native_video_generation_and_thumbnail', () async {
      await DesktopMedia.run([
        '-f',
        'lavfi',
        '-i',
        'color=c=blue:s=320x240:r=15:d=1',
        '-i',
        wav.path,
        '-c:v',
        'mpeg4',
        '-q:v',
        '3',
        '-c:a',
        'aac',
        '-shortest',
        video.path,
      ]);
      final bytes = await DesktopMedia.invoke(
        'sornaz/story_media',
        'thumbnail',
        {'uri': video.uri.toString(), 'video': true, 'size': 160, 'timeMs': 0},
      );
      require(
        bytes is List<int> && bytes.isNotEmpty,
        'Video thumbnail missing',
      );
    });
    await check('platform_video_playback', () async {
      final player = VideoPlayerController.file(video);
      try {
        await player.initialize();
        await player.setVolume(0);
        require(
          player.value.duration.inMilliseconds > 800,
          'Video duration missing',
        );
        await player.play();
        await Future<void>.delayed(const Duration(milliseconds: 300));
        await player.pause();
        await player.seekTo(const Duration(milliseconds: 500));
        require(player.value.isInitialized, 'Video playback failed');
      } finally {
        await player.dispose();
      }
    });
    await check('platform_recording_playback', () async {
      final player = just.AudioPlayer();
      try {
        final duration = await readyAudioDuration(
          player,
          await player.setFilePath(wav.path),
        );
        require(
          (duration?.inMilliseconds ?? 0) > 900,
          'Recording preview duration missing',
        );
        await player.setClip(
          start: const Duration(milliseconds: 100),
          end: const Duration(milliseconds: 700),
        );
        require(
          player.duration == const Duration(milliseconds: 600),
          'Clipped preview duration is incorrect',
        );
        await player.seek(const Duration(milliseconds: 200));
        await player.setVolume(0);
        unawaited(player.play());
        await Future<void>.delayed(const Duration(milliseconds: 200));
        await player.pause();
      } finally {
        await player.dispose();
      }
    });
    await check('platform_music_playback', () async {
      final player = audio.AudioPlayer();
      try {
        await player.setSource(audio.DeviceFileSource(wav.path));
        await player.setVolume(0);
        require(
          ((await player.getDuration())?.inMilliseconds ?? 0) > 900,
          'Music duration missing',
        );
        await player.resume();
        await Future<void>.delayed(const Duration(milliseconds: 200));
        await player.pause();
      } finally {
        await player.dispose();
      }
    });
    await check('platform_metronome_assets', () async {
      final player = just.AudioPlayer();
      try {
        final duration = await readyAudioDuration(
          player,
          await player.setAsset('assets/audio/tick.wav'),
        );
        require(
          duration != null && duration > Duration.zero,
          'Metronome sample duration missing',
        );
        await player.setVolume(0);
        unawaited(player.play());
        await Future<void>.delayed(
          duration! + const Duration(milliseconds: 100),
        );
        await player.seek(Duration.zero);
        await Future<void>.delayed(const Duration(milliseconds: 20));
        await player.pause();
      } finally {
        await player.dispose();
      }
    });
    for (final format in AudioExportFormat.values) {
      await check('audio_export_${format.name}', () async {
        final output = File(p.join(directory.path, 'export.${format.name}'));
        await DesktopMedia.run(
          VideoAudioExport.arguments(video.path, output.path, format),
        );
        require(await output.length() > 0, 'Export is empty');
        require(
          await DesktopMedia.duration(output.path) > 800,
          'Export duration incorrect',
        );
      });
    }
    await check('crop_and_recording_splice', () async {
      final crop = await DesktopMedia.invoke('sornaz/audio_crop', 'render', {
        'source': wav.path,
        'start': 100,
        'end': 700,
      });
      try {
        final original = await wav.copy(
          p.join(directory.path, 'recording.wav'),
        );
        await DesktopMedia.splice(original.path, '$crop', 100);
        require(
          await DesktopMedia.duration(original.path) > 800,
          'Spliced recording truncated',
        );
      } finally {
        if (await File('$crop').exists()) await File('$crop').delete();
      }
    });
    await check('waveform_and_equalizer', () async {
      final peaks = await DesktopMedia.waveform(wav.path);
      require(
        peaks.length >= 9 && peaks.any((v) => v > .01),
        'Waveform is empty',
      );
      final output = File(p.join(directory.path, 'equalized.wav'));
      await DesktopMedia.run([
        '-i',
        wav.path,
        '-af',
        'equalizer=f=440:t=o:w=1:g=6,alimiter=limit=0.95',
        output.path,
      ]);
      require(await output.length() > 0, 'Equalizer output missing');
    });
    await check('story_overlay_export', () async {
      final overlay = image.Image(width: 320, height: 240, numChannels: 4);
      image.fill(overlay, color: image.ColorRgba8(255, 0, 0, 80));
      final selected =
          await DesktopMedia.invoke('sornaz/story_media', 'select', {
                'uri': video.uri.toString(),
                'video': true,
              })
              as Map;
      String? rendered;
      try {
        final result =
            await DesktopMedia.invoke('sornaz/story_media', 'exportVideo', {
                  'path': selected['path'],
                  'overlay': image.encodePng(overlay),
                  'cover': false,
                })
                as Map;
        rendered = '${result['path']}';
        require(await File(rendered).length() > 0, 'Story export missing');
      } finally {
        await DesktopMedia.invoke('sornaz/story_media', 'delete', {
          'paths': [selected['path'], if (rendered != null) rendered],
        });
      }
    });
    await check('private_pdf_renderer', () async {
      final document = pdf.Document()
        ..addPage(pdf.Page(build: (_) => pdf.Text('Private PDF smoke test')));
      final file = await File(
        p.join(directory.path, 'private.pdf'),
      ).writeAsBytes(await document.save());
      final rendered = await const MethodChannel('sornaz/private_pdf')
          .invokeMapMethod<String, dynamic>('render', {
            'path': file.path,
            'page': 0,
          });
      require(
        rendered?['count'] == 1 && (rendered?['bytes'] as List).isNotEmpty,
        'PDF did not render',
      );
    });
    await check('rust_metadata', () async {
      await MetadataGod.initialize();
      final metadata = await MetadataGod.readMetadata(file: wav.path);
      require(
        (metadata.duration?.inMilliseconds ?? 0) > 900,
        'Rust metadata unavailable',
      );
    });
    await check('native_analysis_engine', () async {
      final pcm = await AnalysisAudioPreparer(
        PlatformAnalysisAudioDecoder(),
      ).prepare(AnalysisAudioSource.file(wav.path));
      try {
        final features = await MusicAnalysisFfi.open().extract(pcm).toList();
        require(features.isNotEmpty, 'Analysis engine produced no features');
        require(pcm.frames > 40000, 'Analysis PCM missing');
      } finally {
        await pcm.dispose();
      }
    });
    if (Platform.isIOS) {
      await check('ios_native_metronome', () async {
        const channel = MethodChannel('sornaz/metronome');
        final ticks = <dynamic>[];
        final subscription = const EventChannel(
          'sornaz/metronome/events',
        ).receiveBroadcastStream().listen(ticks.add);
        try {
          await channel.invokeMethod<void>('start', {
            'bpm': 300,
            'beats': 1,
            'subdivisions': 2,
            'accent': 0.0,
            'tick': 0.0,
            'sub': 0.0,
            'bars': 1,
            'seconds': 0,
          });
          await Future<void>.delayed(const Duration(milliseconds: 600));
          require(
            ticks.any((event) => (event as Map)['beat'] == 1),
            'Native audio-clock tick missing',
          );
          require(
            ticks.any((event) => (event as Map)['finished'] == true),
            'Native bar stop missing',
          );
        } finally {
          await channel.invokeMethod<void>('stop');
          await subscription.cancel();
        }
      });
      await check('ios_photos_round_trip', () async {
        final before =
            (await DesktopMedia.invokeIOS('sornaz/device_videos', 'list', {})
                    as List)
                .map((row) => (row as Map)['uri'])
                .toSet();
        final staged = await DesktopMedia.draft('mp4');
        String? selected;
        try {
          await video.copy(staged.path);
          await DesktopMedia.invokeIOS('sornaz/story_media', 'save', {
            'path': staged.path,
            'video': true,
          });
          final after =
              await DesktopMedia.invokeIOS('sornaz/device_videos', 'list', {})
                  as List;
          final created = after
              .cast<Map>()
              .where((row) => !before.contains(row['uri']))
              .toList();
          require(created.length == 1, 'Synthetic Photos asset was not listed');
          final uri = created.single['uri'] as String;
          final thumbnail = await DesktopMedia.invokeIOS(
            'sornaz/story_media',
            'thumbnail',
            {'uri': uri, 'video': true, 'size': 240},
          );
          require(
            (thumbnail as List).isNotEmpty,
            'Photos thumbnail is missing',
          );
          selected = await DesktopMedia.iosMaterialize(uri);
          require(
            await DesktopMedia.duration(selected) > 800,
            'Photos video was not materialized',
          );
        } finally {
          if (selected != null && await File(selected).exists())
            await File(selected).delete();
          if (await staged.exists()) await staged.delete();
        }
        // The synthetic asset stays in this disposable CI simulator; never
        // request deletion of arbitrary assets or interact with real accounts.
      });
    }
  } finally {
    await directory.delete(recursive: true);
    await File(
      reportPath,
    ).writeAsString(const JsonEncoder.withIndent('  ').convert(results));
  }
  // Close through the UI thread so COM/media plugins are disposed before COM
  // shuts down. dart:io exit bypasses that lifecycle on a Dart worker thread.
  if (Platform.isWindows) {
    await const MethodChannel(
      'sornaz/video_controls',
    ).invokeMethod<void>('closeWindow');
  }
}

Future<void> runIosSmoke() async => runDesktopSmoke(
  p.join((await getTemporaryDirectory()).path, 'sornaz-ios-smoke.json'),
);
