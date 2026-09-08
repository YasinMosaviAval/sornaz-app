import 'package:sornaz/screens/Social/social_widgets.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sornaz/components/app_bar.dart';
import 'package:sornaz/components/bottom_nav.dart';
import 'package:sornaz/helpers/app_colors.dart';
import 'package:sornaz/helpers/app_data.dart';
import 'package:sornaz/helpers/app_spacing.dart';
import 'package:sornaz/screens/Tuner/controller/tuner_provider.dart';
import 'package:sornaz/screens/Tuner/ui/pages/tuner_settings.dart';
import 'package:sornaz/screens/Tuner/ui/components/detected_frequency.dart';
import 'package:sornaz/screens/Tuner/ui/components/frequency_box.dart';
import 'package:sornaz/screens/Tuner/ui/components/frequency_info_row.dart';
import 'package:sornaz/screens/Tuner/ui/components/piano_keyboard.dart';

class TunerPage extends StatelessWidget {
  const TunerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _TunerView();
  }
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

    return Scaffold(
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
            Padding(padding: const EdgeInsets.all(16), child: Text(socialText(context, 'تشخیص فرکانس میکروفون در این نسخهٔ ویندوز فعال نیست؛ می‌توانید از کیبورد برای پخش نت مرجع استفاده کنید.', 'Microphone pitch detection is not available in this Windows version. Use the keyboard to play reference notes.'), textAlign: TextAlign.center)),
          FrequencyInfoRow(
            note: analyzed.note,
            cents: analyzed.cents,
            noteFreq: analyzed.targetFreq,
          ),
          FrequencyBox(
            cents: analyzed.cents,
            inRange: inRange,
          ),
          AppSpacing.sizedBoxH16(),
          DetectedFrequency(frequency: tuner.frequency),
          const SizedBox(height: 16),
          Directionality(
            textDirection: TextDirection.ltr,
            child: Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: PianoKeyboard(
                  a4: tuner.a4,
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const BottomNavBarWidget(),
    );
  }
}
