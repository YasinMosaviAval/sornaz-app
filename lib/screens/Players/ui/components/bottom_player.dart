import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sornaz/screens/Players/providers/audio_player_provider.dart';
import 'package:sornaz/screens/Players/ui/components/audio_controls.dart';
import 'package:sornaz/screens/Players/ui/components/audio_slider.dart';
import 'package:sornaz/helpers/app_colors.dart';
import 'package:sornaz/helpers/app_data.dart';
import 'package:sornaz/helpers/app_spacing.dart';

class BottomPlayerWidget extends StatelessWidget {
  const BottomPlayerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final appData = Provider.of<AppData>(context);
    final isDark = appData.isDark;
    final provider = context.watch<AudioPlayerProvider>();

    if (provider.currentIndex == -1) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(color: AppColors.music_player_bottom_player_background_color(isDark: isDark)),
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
