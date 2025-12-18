// import 'dart:io';

import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:provider/provider.dart';
import 'dart:math';

import 'package:sornaz/helpers/app_colors.dart';
import 'package:sornaz/helpers/app_data.dart';
import 'package:sornaz/helpers/app_strings.dart';
import 'package:sornaz/helpers/app_translations.dart';

class WaveformViewer extends StatefulWidget {
  final List<int> samples;
  final Color color;

  const WaveformViewer({
    super.key,
    required this.samples,
    this.color = Colors.blue,
  });

  @override
  State<WaveformViewer> createState() => _WaveformViewerState();
}

class _WaveformViewerState extends State<WaveformViewer> {
  double zoom = 1.0;
  final ScrollController scroll = ScrollController();

  @override
  Widget build(BuildContext context) {
    final width = widget.samples.length / 100 * zoom;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            controller: scroll,
            scrollDirection: Axis.horizontal,
            child: CustomPaint(
              size: Size(width, 200),
              painter: WavePainter(widget.samples, widget.color),
            ),
          ),
        ),

        Slider(
          min: 1.0,
          max: 8.0,
          value: zoom,
          label: AppStrings.waveform_widget_zoom_label.translate(context),
          onChanged: (v) => setState(() => zoom = v),
        ),
      ],
    );
  }
}

class WavePainter extends CustomPainter {
  final List<int> samples;
  final Color color;

  WavePainter(this.samples, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;

    final mid = size.height / 2;
    final step = samples.length ~/ size.width;

    for (int x = 0; x < size.width; x++) {
      final sample = samples[x * step].abs();
      final norm = (sample / 32768);

      final y = norm * (size.height / 2);

      canvas.drawLine(
        Offset(x.toDouble(), mid - y),
        Offset(x.toDouble(), mid + y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant WavePainter oldDelegate) => true;
}

class WaveformPlayerView extends StatefulWidget {
  final List<int> samples;
  final Duration duration;
  final String filePath;
  final Color color;

  const WaveformPlayerView({
    super.key,
    required this.samples,
    required this.duration,
    required this.filePath,
    this.color = Colors.blue,
  });

  @override
  State<WaveformPlayerView> createState() => _WaveformPlayerViewState();
}

class _WaveformPlayerViewState extends State<WaveformPlayerView> {
  late AudioPlayer player;

  double zoom = 1.0;
  double playheadX = 0.0;
  late ScrollController scrollController;

  @override
  void initState() {
    super.initState();
    player = AudioPlayer();
    scrollController = ScrollController();

    player.onPositionChanged.listen((position) {
      final percent = position.inMilliseconds / widget.duration.inMilliseconds;
      setState(() {
        playheadX = percent * widget.samples.length * zoom / 2;
      });

      // اسکرول خودکار
      if (scrollController.hasClients) {
        scrollController.animateTo(
          max(0, playheadX - 120),
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    player.dispose();
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appData = Provider.of<AppData>(context);
    final isDark = appData.isDark;
    
    final waveformWidth = widget.samples.length * zoom / 2;

    return Column(
      children: [
        // دکمه پخش
        Row(
          children: [
            IconButton(
              icon: Icon(Icons.play_arrow, color: isDark? AppColors.text_primary_dark: AppColors.text_primary_light),
              onPressed: () async {
                await player.stop();
                await player.play(DeviceFileSource(widget.filePath));
              },
            ),
            IconButton(
              icon: Icon(Icons.pause, color: isDark? AppColors.text_primary_dark: AppColors.text_primary_light),
              onPressed: () async {
                await player.pause();
              },
            ),
          ],
        ),

        Expanded(
          child: GestureDetector(
            onScaleUpdate: (details) {
              setState(() {
                zoom = (zoom * details.scale).clamp(0.5, 8.0);
              });
            },
            child: SingleChildScrollView(
              controller: scrollController,
              scrollDirection: Axis.horizontal,
              child: CustomPaint(
                size: Size(waveformWidth, 200),
                painter: WaveformPainter(
                  samples: widget.samples,
                  color: widget.color,
                  playheadX: playheadX,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class WaveformPainter extends CustomPainter {
  final List<int> samples;
  final Color color;
  final double playheadX;

  WaveformPainter({
    required this.samples,
    required this.color,
    required this.playheadX,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 1
      ..color = color;

    final midY = size.height / 2;

    final step = max(1, samples.length ~/ size.width);

    for (int i = 0; i < samples.length; i += step) {
      final x = i / step;
      final normalized = samples[i] / 32768.0;

      final y = normalized * (size.height / 2);

      canvas.drawLine(Offset(x, midY - y), Offset(x, midY + y), paint);
    }

    final playheadPaint = Paint()
      ..color = Colors.red
      ..strokeWidth = 2;

    canvas.drawLine(
      Offset(playheadX, 0),
      Offset(playheadX, size.height),
      playheadPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
