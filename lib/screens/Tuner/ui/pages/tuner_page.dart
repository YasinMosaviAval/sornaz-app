import 'package:sornaz/components/scroll_aware_scaffold.dart';
import 'package:sornaz/screens/Social/social_widgets.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sornaz/screens/Players/providers/audio_player_provider.dart';
import 'package:sornaz/screens/Players/services/player_settings.dart';
import 'package:sornaz/components/app_bar.dart';

import 'package:sornaz/helpers/app_colors.dart';
import 'package:sornaz/helpers/app_data.dart';
import 'package:sornaz/helpers/app_spacing.dart';
import 'package:sornaz/screens/Tuner/controller/tuner_provider.dart';
import 'package:sornaz/screens/Tuner/ui/pages/tuner_settings.dart';
import 'package:sornaz/screens/Tuner/ui/components/detected_frequency.dart';
import 'package:sornaz/screens/Tuner/ui/components/frequency_box.dart';
import 'package:sornaz/screens/Tuner/ui/components/frequency_info_row.dart';
import 'package:sornaz/screens/Tuner/ui/components/piano_keyboard.dart';

class TunerPage extends StatefulWidget {
  const TunerPage({super.key});

  @override
  State<TunerPage> createState() => _TunerPageState();
}

class _TunerPageState extends State<TunerPage> with WidgetsBindingObserver {
  late TunerProvider tuner;
  @override
  void initState() {
    super.initState();
    tuner = context.read<TunerProvider>();
    WidgetsBinding.instance.addObserver(this);
    final music = context.read<AudioPlayerProvider?>();
    if (music == null) {
      tuner.start();
    } else {
      music.interrupt(PlaybackInterruption.tuner).then((_) {
        if (mounted) tuner.start();
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      tuner.start();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      tuner.stop();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    tuner.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const _TunerView();
}

class _TunerView extends StatelessWidget {
  const _TunerView();

  @override
  Widget build(BuildContext context) {
    final appData = context.watch<AppData>();
    final isDark = appData.isDark;

    final tuner = context.watch<TunerProvider>();
    final analyzed = tuner.analyzePitch(tuner.frequency);
    final inRange = analyzed.cents.abs() <= 20;

    return ScrollAwareScaffold(
      appBar: SornazAppBar(
        showBackButton: false,
        centerIcon: Icons.settings,
        onCenterIconPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const TunerSettingsPage()),
          );
        },
      ),
      backgroundColor: AppColors.tuner_page_background_color(isDark: isDark),
      body: Column(
        children: [
          if (!tuner.supportsPitchDetection)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                socialText(
                  context,
                  'تشخیص فرکانس میکروفون در این نسخهٔ ویندوز فعال نیست؛ می‌توانید از کیبورد برای پخش نت مرجع استفاده کنید.',
                  'Microphone pitch detection is not available in this Windows version. Use the keyboard to play reference notes.',
                ),
                textAlign: TextAlign.center,
              ),
            ),
          if (tuner.detectionError != null)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Text(
                    socialText(
                      context,
                      tuner.detectionError == 'permission'
                          ? 'برای تشخیص فرکانس، دسترسی به میکروفون را فعال کنید.'
                          : 'دریافت صدای میکروفون متوقف شد. دوباره تلاش کنید.',
                      tuner.detectionError == 'permission'
                          ? 'Allow microphone access to detect pitch.'
                          : 'Microphone input stopped. Please try again.',
                    ),
                  ),
                  TextButton(
                    onPressed: tuner.start,
                    child: Text(socialText(context, 'تلاش مجدد', 'Retry')),
                  ),
                ],
              ),
            ),
          FrequencyInfoRow(
            note: analyzed.note,
            cents: analyzed.cents,
            noteFreq: analyzed.targetFreq,
          ),
          FrequencyBox(cents: analyzed.cents, inRange: inRange),
          AppSpacing.sizedBoxH16(),
          DetectedFrequency(frequency: tuner.frequency),
          const SizedBox(height: 16),
          Directionality(
            textDirection: TextDirection.ltr,
            child: Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: PianoKeyboard(a4: tuner.a4),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
