import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sornaz/components/bottom_nav.dart';
import 'package:metronome/metronome.dart';
import 'package:sornaz/helpers/app_colors.dart';
import 'package:sornaz/helpers/app_data.dart';
import 'package:sornaz/helpers/app_locale_provider.dart';
import 'package:sornaz/helpers/app_spacing.dart';
import 'package:sornaz/helpers/app_strings.dart';
import 'package:sornaz/helpers/app_translations.dart';
import 'package:sornaz/helpers/app_typography.dart';

class MetronomePage extends StatefulWidget {
  const MetronomePage({super.key});

  @override
  State<MetronomePage> createState() => _MetronomePageState();
}

class _MetronomePageState extends State<MetronomePage> {
  final Metronome metronome = Metronome();
  bool isInitialized = false;
  bool isPlaying = false;
  int bpm = 120;
  int timeSignature = 4;
  double volume = 50.0;

  @override
  void dispose() {
    metronome.destroy();
    super.dispose();
  }

  Future<void> initMetronome() async {
    await metronome.init(
      'assets/audio/tick.wav',
      accentedPath: 'assets/audio/accent.wav',
      bpm: bpm,
      volume: volume.toInt(),
      enableTickCallback: true,
      timeSignature: timeSignature,
      sampleRate: 44100,
    );
    setState(() {
      isInitialized = metronome.isInitialized;
    });
  }

  void togglePlayPause() {
    if (isPlaying) {
      metronome.pause();
    } else {
      metronome.play();
    }
    setState(() {
      isPlaying = !isPlaying;
    });
  }

  void stopMetronome() {
    metronome.stop();
    setState(() {
      isPlaying = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final appData = Provider.of<AppData>(context);
    final isDark = appData.isDark;
    final localeProvider = Provider.of<LocaleProvider>(context, listen: false);
    final bool isEnglish = localeProvider.locale.languageCode == 'en';

    return Directionality(
      textDirection: isEnglish ? TextDirection.ltr : TextDirection.rtl,
      child: Scaffold(
        backgroundColor: isDark ? AppColors.background_dark : AppColors.background_light,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${AppStrings.bpm.translate(context)}: $bpm',
                style: AppTypography.metronomeBPM(context),
              ),
              setBPM(),
              Text(
                '${AppStrings.timing.translate(context)}: $timeSignature/4',
                style: AppTypography.metronomeTiming(context),
              ),
              setTimeSignature(),
              Text(
                '${AppStrings.volume.translate(context)}: ${volume.toInt()}%',
                style: AppTypography.metronomeVolume(context),
              ),
              setVolume(),
              SizedBox(height: AppSpacing.space_8),
              launchButton(isDark),
              SizedBox(height: AppSpacing.space_8),
              playButton(isDark),
              SizedBox(height: AppSpacing.space_8),
              stopButton(isDark),
            ],
          ),
        ),
        bottomNavigationBar: const BottomNavBarWidget(),
      ),
    );
  }

  Slider setBPM() {
    return Slider(
      value: bpm.toDouble(),
      min: 40,
      max: 200,
      onChanged: (value) {
        setState(() {
          bpm = value.toInt();
        });
        if (isInitialized) {
          metronome.setBPM(bpm);
        }
      },
    );
  }

  Slider setTimeSignature() {
    return Slider(
      value: timeSignature.toDouble(),
      min: 2,
      max: 8,
      divisions: 6,
      onChanged: (value) {
        setState(() {
          timeSignature = value.toInt();
        });
        if (isInitialized) {
          metronome.setTimeSignature(timeSignature);
        }
      },
    );
  }

  Slider setVolume() {
    return Slider(
      value: volume,
      min: 0,
      max: 100,
      onChanged: (value) {
        setState(() {
          volume = value;
        });
        if (isInitialized) {
          metronome.setVolume(volume.toInt());
        }
      },
    );
  }

  ElevatedButton launchButton(bool isDark) {
    return ElevatedButton(
      onPressed: initMetronome,
      style: ElevatedButton.styleFrom(
        backgroundColor: isDark
            ? AppColors.surface_dark
            : AppColors.surface_light,
        // foregroundColor: isDark
        //     ? AppColors.text_primary_dark
        //     : AppColors.text_primary_light, // رنگ متن
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space_24,
          vertical: AppSpacing.space_12,
        ), // پدینگ
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            AppSpacing.space_4,
          ), // گوشه‌های گرد
        ),
      ),
      child: Text(
        isInitialized
            ? AppStrings.launch_again.translate(context)
            : AppStrings.launch.translate(context),
        style: AppTypography.metronomeLaunchButton(context),
      ),
    );
  }

  ElevatedButton playButton(bool isDark) {
    return ElevatedButton(
      onPressed: isInitialized ? togglePlayPause : null,

      style: ElevatedButton.styleFrom(
        backgroundColor: isDark
            ? AppColors.surface_dark
            : AppColors.surface_light,
        // foregroundColor: isDark
        //     ? AppColors.text_primary_dark
        //     : AppColors.text_primary_light, // رنگ متن
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space_24,
          vertical: AppSpacing.space_12,
        ), // پدینگ
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            AppSpacing.space_4,
          ), // گوشه‌های گرد
        ),
      ),
      child: Text(
        isPlaying
            ? AppStrings.pause.translate(context)
            : AppStrings.play.translate(context),
        style: AppTypography.metronomePlayPauseButton(context),
      ),
    );
  }

  ElevatedButton stopButton(bool isDark) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: isDark
            ? AppColors.surface_dark
            : AppColors.surface_light,
        // foregroundColor: isDark
        //     ? AppColors.text_primary_dark
        //     : AppColors.text_primary_light, // رنگ متن
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space_24,
          vertical: AppSpacing.space_12,
        ), // پدینگ
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            AppSpacing.space_4,
          ), // گوشه‌های گرد
        ),
      ),
      onPressed: isInitialized ? stopMetronome : null,
      child: Text(
        AppStrings.stop.translate(context),
        style: AppTypography.metronomeStopButton(context),
      ),
    );
  }
}
