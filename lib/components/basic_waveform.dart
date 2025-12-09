import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sornaz/helpers/app_colors.dart';
import 'package:sornaz/helpers/app_data.dart';
import 'package:sornaz/helpers/app_spacing.dart';
import 'package:sornaz/helpers/app_waveform_painter.dart';

class BasicWaveformWidget extends StatelessWidget {
  const BasicWaveformWidget({
    super.key,
    required List<double> amplitudes,
    required bool isRecording,
    required bool isPaused,
  }) : _amplitudes = amplitudes,
       _isRecording = isRecording,
       _isPaused = isPaused;

  final List<double> _amplitudes;
  final bool _isRecording;
  final bool _isPaused;

  @override
  Widget build(BuildContext context) {
    final appData = Provider.of<AppData>(context);
    final isDark = appData.isDark;
    return Container(
      decoration: BoxDecoration(
        border: Border.symmetric(
          horizontal: BorderSide(width: 1, color: isDark ? AppColors.text_secondary_dark : AppColors.text_secondary_light),
        ),
      ),
      child: Column(
        children: [
          Container(
            height: AppSpacing.space_250,
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.background_dark
                  : AppColors.background_light,
              border: Border.symmetric(
                horizontal: BorderSide(width: 1, color: AppColors.border_light),
              ),
            ),
            child: ClipRRect(
              child: CustomPaint(
                painter: WaveformPainter(_amplitudes, _isRecording && !_isPaused, isDark),
                size: Size.infinite,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
