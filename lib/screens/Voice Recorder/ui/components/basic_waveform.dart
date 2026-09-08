import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sornaz/helpers/app_colors.dart';
import 'package:sornaz/helpers/app_data.dart';
import 'package:sornaz/helpers/app_spacing.dart';
import 'package:sornaz/screens/Voice%20Recorder/ui/components/app_waveform_painter.dart';

class BasicWaveformWidget extends StatelessWidget {
  const BasicWaveformWidget({
    super.key,
    required List<double> amplitudes,
    required this.totalSamples,
    required bool isRecording,
    required bool isPaused,
  }) : _amplitudes = amplitudes,
       _isRecording = isRecording,
       _isPaused = isPaused;

  final int totalSamples;
  final List<double> _amplitudes;
  final bool _isRecording;
  final bool _isPaused;

  @override
  Widget build(BuildContext context) {
    final appData = Provider.of<AppData>(context);
    final isDark = appData.isDark;
    return Column(
      children: [
        Container(
          height: AppSpacing.space_250,
          decoration: BoxDecoration(
            color: AppColors.voice_recorder_basic_waveform_decoration_color(
              isDark: isDark,
            ),
          ),
          child: ClipRRect(
            child: CustomPaint(
              painter: WaveformPainter(
                _amplitudes,
                _isRecording && !_isPaused,
                context,
                isDark,
                totalSamples: totalSamples,
              ),
              size: Size.infinite,
            ),
          ),
        ),
      ],
    );
  }
}
