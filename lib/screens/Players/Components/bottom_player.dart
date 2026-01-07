import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sornaz/screens/Players/Components/audio_controls.dart';
import 'package:sornaz/screens/Players/Components/audio_slider.dart';
import 'package:sornaz/helpers/app_colors.dart';
import 'package:sornaz/helpers/app_data.dart';
import 'package:sornaz/helpers/app_spacing.dart';
import 'package:sornaz/screens/Players/audio/audio_player_provider.dart';

class BottomPlayerWidget extends StatelessWidget {
  const BottomPlayerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final appData = Provider.of<AppData>(context);
    final isDark = appData.isDark;
    final provider = context.watch<AudioPlayerProvider>();

    if (provider.currentIndex == -1) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(color: isDark? AppColors.surface_dark : AppColors.surface_light),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space_16, vertical: AppSpacing.space_4),
      child: Column(
        children: [
          AudioSlider(),
          AudioControls(),
        ],
      ),
    );
  }
}
