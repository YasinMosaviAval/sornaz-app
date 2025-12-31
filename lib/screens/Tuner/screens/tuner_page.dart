import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sornaz/components/app_bar.dart';
import 'package:sornaz/components/bottom_nav.dart';
import 'package:sornaz/screens/Tuner/controller/tuner_provider.dart';
import 'package:sornaz/screens/Tuner/screens/tuner_settings.dart';
import 'package:sornaz/screens/Tuner/widgets/detected_frequency.dart';
import 'package:sornaz/screens/Tuner/widgets/frequency_box.dart';
import 'package:sornaz/screens/Tuner/widgets/frequency_info_row.dart';
import 'package:sornaz/screens/Tuner/widgets/piano_keyboard.dart';

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
      body: Column(
        children: [
          // ChangeFrequencyTitleWidget(a4: tuner.a4),
          // A4Slider(
          //   value: tuner.a4,
          //   onChanged: tuner.setA4,
          // ),
          FrequencyInfoRow(
            note: analyzed.note,
            cents: analyzed.cents,
            noteFreq: analyzed.targetFreq,
          ),
          FrequencyBox(
            cents: analyzed.cents,
            inRange: inRange,
          ),
          DetectedFrequency(
            frequency: tuner.frequency,
          ),
          const SizedBox(height: 16),
          // پیانو افقی
          Directionality(
            textDirection: TextDirection.ltr,
            child: Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: PianoKeyboard(
                  a4: tuner.a4,
                  octaves: 5,
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
