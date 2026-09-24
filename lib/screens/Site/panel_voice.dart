import 'dart:async';
import 'dart:io';
import 'dart:ui' show FontFeature;
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
    this.mine = false,
    this.playerFactory,
  });
  final PanelApi api;
  final String messageId;
  final bool mine;
  final AudioPlayer Function()? playerFactory;
  @override
  State<PanelVoicePlayback> createState() => _PanelVoicePlaybackState();
}

class _PanelVoicePlaybackState extends State<PanelVoicePlayback> {
  AudioPlayer? player;
  StreamSubscription<PlayerState>? stateSub;
  StreamSubscription<Duration>? positionSub;
  Duration position = Duration.zero, duration = Duration.zero;
  bool playing = false, loading = true, failed = false;
  Future<void>? preparing;
  @override
  void initState() {
    super.initState();
    prepare();
  }

  Future<void> prepare() => preparing ??= load();
  Future<void> load() async {
    try {
      final file = await ChatFiles.open(widget.api, widget.messageId);
      if (!mounted) return;
      final audio = widget.playerFactory?.call() ?? AudioPlayer();
      player = audio;
      stateSub = audio.playerStateStream.listen((state) {
        if (mounted)
          setState(() {
            playing =
                state.playing &&
                state.processingState != ProcessingState.completed;
            if (state.processingState == ProcessingState.completed)
              position = duration;
          });
      });
      positionSub = audio.positionStream.listen((value) {
        if (mounted) setState(() => position = value);
      });
      final length = await audio.setFilePath(file.path);
      if (mounted)
        setState(() {
          duration = length ?? Duration.zero;
          loading = false;
          failed = false;
        });
    } catch (_) {
      await stateSub?.cancel();
      await positionSub?.cancel();
      await player?.dispose();
      player = null;
      if (mounted)
        setState(() {
          loading = false;
          failed = true;
        });
    }
  }

  @override
  void dispose() {
    stateSub?.cancel();
    positionSub?.cancel();
    player?.dispose();
    super.dispose();
  }

  Future<void> toggle() async {
    if (loading) return;
    try {
      widget.api.checkAccount();
      if (failed) {
        setState(() {
          loading = true;
          failed = false;
        });
        preparing = null;
        await prepare();
      }
      if (!mounted || player == null || failed) return;
      if (playing) {
        await player!.pause();
      } else {
        if (player!.processingState == ProcessingState.completed)
          await player!.seek(Duration.zero);
        unawaited(
          player!.play().catchError((Object e) {
            if (mounted) socialError(context, e);
          }),
        );
      }
    } catch (e) {
      if (mounted) socialError(context, e);
    }
  }

  String clock(Duration value) =>
      '${value.inMinutes}:${(value.inSeconds % 60).toString().padLeft(2, '0')}';
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: 250,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: widget.mine
            ? colors.primaryContainer
            : colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              IconButton(
                tooltip: socialText(
                  context,
                  failed
                      ? 'تلاش دوباره'
                      : playing
                      ? 'توقف صدا'
                      : 'پخش صدا',
                  failed
                      ? 'Retry'
                      : playing
                      ? 'Pause audio'
                      : 'Play audio',
                ),
                onPressed: loading ? null : toggle,
                icon: loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        failed
                            ? Icons.refresh
                            : playing
                            ? Icons.pause
                            : Icons.play_arrow,
                      ),
              ),
              Expanded(
                child: SizedBox(
                  height: 32,
                  child: CustomPaint(
                    painter: MessageAudioWaveform(
                      progress: duration.inMilliseconds == 0
                          ? 0
                          : (position.inMilliseconds / duration.inMilliseconds)
                                .clamp(0, 1),
                      active: colors.primary,
                      inactive: colors.onSurface.withValues(alpha: .22),
                    ),
                  ),
                ),
              ),
            ],
          ),
          Directionality(
            textDirection: TextDirection.ltr,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  clock(position),
                  style: const TextStyle(
                    fontSize: 11,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
                Text(
                  clock(duration),
                  style: const TextStyle(
                    fontSize: 11,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class MessageAudioWaveform extends CustomPainter {
  MessageAudioWaveform({
    required this.progress,
    required this.active,
    required this.inactive,
  });
  final double progress;
  final Color active, inactive;
  static const pattern = [
    .2,
    .35,
    .65,
    .4,
    .8,
    .95,
    .55,
    .35,
    .7,
    .5,
    .25,
    .6,
    .85,
    .45,
    .7,
    .3,
  ];
  @override
  void paint(Canvas canvas, Size size) {
    void draw(Color color) {
      final pen = Paint()
        ..color = color
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round;
      for (var i = 0; i < 48; i++) {
        final x = (i + .5) * size.width / 48,
            h = pattern[i % pattern.length] * size.height;
        canvas.drawLine(
          Offset(x, (size.height - h) / 2),
          Offset(x, (size.height + h) / 2),
          pen,
        );
      }
    }

    draw(inactive);
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width * progress, size.height));
    draw(active);
    canvas.restore();
  }

  @override
  bool shouldRepaint(MessageAudioWaveform old) =>
      old.progress != progress ||
      old.active != active ||
      old.inactive != inactive;
}
