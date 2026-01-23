import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sornaz/helpers/app_colors.dart';
import 'package:sornaz/helpers/app_data.dart';
import 'package:sornaz/helpers/app_spacing.dart';
import 'package:sornaz/helpers/app_strings.dart';
import 'package:sornaz/helpers/app_translations.dart';

class EqualizerTab extends StatelessWidget {
  const EqualizerTab({super.key});

  @override
  Widget build(BuildContext context) {
    final appData = Provider.of<AppData>(context);
    final isDark = appData.isDark;
    return Container(
      decoration: BoxDecoration(color: AppColors.music_player_equalizer_background_color(isDark: isDark)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space_24),
        child: Column(
          children: [
            AppSpacing.sizedBoxH48(),
            EqualizerSlider(label: AppStrings.bass.translate(context)),
            EqualizerSlider(label: AppStrings.mid.translate(context)),
            EqualizerSlider(label: AppStrings.treble.translate(context)),
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


