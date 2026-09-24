import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:record/record.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import '../Social/social_widgets.dart';
import '../Social/social_api.dart';
import 'panel_api.dart';
import 'chat_media.dart';

class PanelVoiceButton extends StatefulWidget {
  const PanelVoiceButton({
    super.key,
    required this.enabled,
    required this.onRecorded,
    this.onRecording,
    this.onAmplitude,
  });
  final bool enabled;
  final ValueChanged<PlatformFile> onRecorded;
  final ValueChanged<bool>? onRecording;
  final ValueChanged<double>? onAmplitude;
  @override
  State<PanelVoiceButton> createState() => _PanelVoiceButtonState();
}

class _PanelVoiceButtonState extends State<PanelVoiceButton> {
  AudioRecorder? recorder;
  bool recording = false, busy = false;
  final temporaryFiles = <String>[];
  StreamSubscription<Amplitude>? levels;
  @override
  void dispose() {
    levels?.cancel();
    final active = recorder;
    unawaited(() async {
      try {
        await active?.dispose();
      } catch (_) {}
      for (final path in temporaryFiles) {
        try {
          final file = File(path);
          if (await file.exists()) await file.delete();
        } catch (_) {}
      }
    }());
    super.dispose();
  }

  Future<void> toggle() async {
    if (busy) return;
    setState(() => busy = true);
    try {
      if (recording) {
        final path = await recorder!.stop();
        if (!mounted) return;
        setState(() => recording = false);
        await levels?.cancel();
        widget.onRecording?.call(false);
        if (path != null) {
          final size = await File(path).length();
          if (!mounted) return;
          widget.onRecorded(
            PlatformFile(
              name: path.split(Platform.pathSeparator).last,
              path: path,
              size: size,
            ),
          );
        }
      } else {
        recorder ??= AudioRecorder();
        if (!await recorder!.hasPermission()) {
          throw SocialException('اجازهٔ استفاده از میکروفن داده نشده است.');
        }
        final dir = await getTemporaryDirectory();
        if (!mounted) return;
        final path =
            '${dir.path}${Platform.pathSeparator}voice-${DateTime.now().millisecondsSinceEpoch}.m4a';
        temporaryFiles.add(path);
        await recorder!.start(
          const RecordConfig(
            encoder: AudioEncoder.aacLc,
            bitRate: 96000,
            sampleRate: 44100,
          ),
          path: path,
        );
        if (mounted) setState(() => recording = true);
        if (mounted) {
          widget.onRecording?.call(true);
          levels = recorder!
              .onAmplitudeChanged(const Duration(milliseconds: 80))
              .listen((sample) {
                if (mounted)
                  widget.onAmplitude?.call(
                    ((sample.current + 60) / 60).clamp(0.03, 1),
                  );
              });
        }
      }
    } catch (e) {
      if (mounted) socialError(context, e);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: socialText(
      context,
      recording ? 'پایان ضبط پیام' : 'ضبط پیام صوتی',
      recording ? 'Finish recording' : 'Record voice message',
    ),
    onPressed: busy || !widget.enabled && !recording ? null : toggle,
    icon: Icon(
      recording ? Icons.stop_circle : Icons.mic_none,
      color: recording ? Theme.of(context).colorScheme.error : null,
    ),
  );
}

class VoiceMessageWaveform extends CustomPainter {
  VoiceMessageWaveform(this.levels, this.color);
  final List<double> levels;
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final pen = Paint()
      ..color = color
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < levels.length; i++) {
      final x = size.width - (levels.length - i) * 4;
      if (x < 0) continue;
      final height = levels[i] * size.height;
      canvas.drawLine(
        Offset(x, (size.height - height) / 2),
        Offset(x, (size.height + height) / 2),
        pen,
      );
    }
  }

  @override
  bool shouldRepaint(VoiceMessageWaveform old) =>
      old.levels != levels || old.color != color;
}

class PanelVoicePlayback extends StatefulWidget {
  const PanelVoicePlayback({
    super.key,
    required this.api,
    required this.messageId,
  });
  final PanelApi api;
  final String messageId;
  @override
  State<PanelVoicePlayback> createState() => _PanelVoicePlaybackState();
}

class _PanelVoicePlaybackState extends State<PanelVoicePlayback> {
  AudioPlayer? player;
  StreamSubscription<PlayerState>? subscription;
  bool playing = false, busy = false;
  @override
  void dispose() {
    subscription?.cancel();
    player?.dispose();
    super.dispose();
  }

  Future<void> toggle() async {
    if (busy) return;
    setState(() => busy = true);
    try {
      widget.api.checkAccount();
      if (player == null) {
        player = AudioPlayer();
        subscription = player!.playerStateStream.listen((state) {
          if (mounted) {
            setState(
              () => playing =
                  state.playing &&
                  state.processingState != ProcessingState.completed,
            );
          }
        });
        final file = await ChatFiles.open(widget.api, widget.messageId);
        await player!.setFilePath(file.path);
      }
      if (!mounted) return;
      widget.api.checkAccount();
      if (playing) {
        await player!.pause();
      } else {
        if (player!.processingState == ProcessingState.completed) {
          await player!.seek(Duration.zero);
        }
        unawaited(
          player!.play().catchError((Object e) {
            if (mounted) socialError(context, e);
          }),
        );
      }
    } catch (e) {
      await subscription?.cancel();
      subscription = null;
      await player?.dispose();
      player = null;
      playing = false;
      if (mounted) socialError(context, e);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => TextButton.icon(
    onPressed: busy ? null : toggle,
    icon: Icon(playing ? Icons.pause : Icons.play_arrow),
    label: Text(
      socialText(
        context,
        playing ? 'توقف صدا' : 'پخش صدا',
        playing ? 'Pause audio' : 'Play audio',
      ),
    ),
  );
}
