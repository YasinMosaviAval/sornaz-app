import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sornaz/helpers/app_colors.dart';
import 'package:sornaz/helpers/app_data.dart';
import 'package:sornaz/helpers/app_spacing.dart';

class EqualizerTab extends StatelessWidget {
  const EqualizerTab({super.key});

  @override
  Widget build(BuildContext context) {
    final appData = Provider.of<AppData>(context);
    final isDark = appData.isDark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.background_dark : AppColors.background_light
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space_24),
        child: Column(
          children: [
            AppSpacing.sizedBoxH48(),
            EqualizerSlider(label: 'Bass'),
            EqualizerSlider(label: 'Mid'),
            EqualizerSlider(label: 'Treble'),
          ],
        ),
      ),
    );
  }
}

class EqualizerSlider extends StatelessWidget {
  final String label;
  const EqualizerSlider({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        Slider(
          min: -10,
          max: 10,
          value: 0,
          padding: EdgeInsets.fromLTRB(
            AppSpacing.space_0, 
            AppSpacing.space_4, 
            AppSpacing.space_0, 
            AppSpacing.space_24,
          ),
          onChanged: (_) {},
        ),
      ],
    );
  }
}


