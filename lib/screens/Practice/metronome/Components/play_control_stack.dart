/*
import 'package:flutter/material.dart';
import 'package:sornaz/helpers/app_colors.dart';
import 'package:sornaz/screens/Practice/metronome/controller/metronome_controller.dart';

class PlayControls extends StatelessWidget {
  final MetronomeController controller;
  final AnimationController pulseController;
  final bool isDark;
  final VoidCallback onTapTempo;
  final VoidCallback onPlayPause;

  const PlayControls({
    super.key,
    required this.controller,
    required this.pulseController,
    required this.isDark,
    required this.onTapTempo,
    required this.onPlayPause,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (controller.showTapTempo)
            AnimatedOpacity(
              opacity: controller.isPlaying ? 0 : 1,
              duration: const Duration(milliseconds: 400),
              child: GestureDetector(
                onTap: onTapTempo,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: controller.tapActive
                        ? (isDark
                            ? AppColors.primary_dark
                            : AppColors.primary_light)
                        : (isDark
                            ? AppColors.clicked_dark
                            : AppColors.clicked_light),
                  ),
                  child: const Icon(Icons.touch_app),
                ),
              ),
            ),

          ScaleTransition(
            scale: Tween(begin: 1.0, end: 1.1).animate(
              CurvedAnimation(
                parent: pulseController,
                curve: Curves.easeOut,
              ),
            ),
            child: GestureDetector(
              onTap: onPlayPause,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark
                      ? AppColors.clicked_dark
                      : AppColors.clicked_light,
                ),
                child: Icon(
                  controller.isPlaying ? Icons.pause : Icons.play_arrow,
                  size: 56,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
*/