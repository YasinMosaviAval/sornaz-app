import 'package:flutter/material.dart';
import 'package:sornaz/components/waveform_painter_with_ticks.dart';
import 'package:sornaz/helpers/app_colors.dart';
import 'package:sornaz/helpers/app_spacing.dart';
import 'package:sornaz/helpers/app_waveform_painter.dart';

class BasicWaveformWidget extends StatelessWidget {
  const BasicWaveformWidget({
    super.key,
    required this.isDark,
    required List<double> amplitudes,
    required bool isRecording,
    required bool isPaused,
  }) : _amplitudes = amplitudes,
       _isRecording = isRecording,
       _isPaused = isPaused;

  final bool isDark;
  final List<double> _amplitudes;
  final bool _isRecording;
  final bool _isPaused;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: AppSpacing.space_20,
          // width: double.infinity,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: AppSpacing.space_10,
                child: VerticalDivider(
                  thickness: 1,
                  color: AppColors.border_light,
                  width: AppSpacing.space_10,
                ),
              ),
              SizedBox(
                height: AppSpacing.space_10,
                child: VerticalDivider(
                  thickness: 1,
                  color: AppColors.border_light,
                  width: AppSpacing.space_10,
                ),
              ),
              SizedBox(
                height: AppSpacing.space_10,
                child: VerticalDivider(
                  thickness: 1,
                  color: AppColors.border_light,
                  width: AppSpacing.space_10,
                ),
              ),
              VerticalDivider(
                thickness: 1,
                color: AppColors.border_light,
                width: AppSpacing.space_10,
              ),
            ],
          ),
        ),

        Container(
          height: AppSpacing.space_150,
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.space_10),
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
              painter: WaveformPainter(_amplitudes, _isRecording && !_isPaused),
              size: Size.infinite,
            ),
          ),
        ),

        SizedBox(
          height: AppSpacing.space_150,
          child: CustomPaint(
            painter: WaveformPainterWithTicksAndTime(
              _amplitudes,
              _isRecording && !_isPaused,
            ),
            size: Size.infinite,
          ),
        ),

        Container(
          height: AppSpacing.space_150,
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.space_10),
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
              painter: WaveformPainterWithTicks(
                _amplitudes,
                _isRecording && !_isPaused,
              ),
              size: Size.infinite,
            ),
          ),
        ),
      ],
    );
  }
}
