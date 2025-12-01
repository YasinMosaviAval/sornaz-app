// ignore_for_file: use_build_context_synchronously

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_pitch_detection/flutter_pitch_detection.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:sornaz/components/bottom_nav.dart';
import 'package:sornaz/helpers/app_colors.dart';
import 'package:sornaz/helpers/app_data.dart';
import 'package:sornaz/helpers/app_locale_provider.dart';
import 'package:sornaz/helpers/app_spacing.dart';
import 'package:sornaz/helpers/app_strings.dart';
import 'package:sornaz/helpers/app_translations.dart';

class TunerPage extends StatefulWidget {
  const TunerPage({super.key});

  @override
  State<TunerPage> createState() => _TunerPageState();
}

class _TunerPageState extends State<TunerPage> {
  final FlutterPitchDetection _pitch = FlutterPitchDetection();

  double frequency = 0.0;
  String note = AppStrings.epmty_text;
  double a4 = 440.0;
  bool initialized = false;
  double noteFreq = 0.0;

  final List<String> notes = [
    "C",
    "C#",
    "D",
    "D#",
    "E",
    "F",
    "F#",
    "G",
    "G#",
    "A",
    "A#",
    "B",
  ];

  double centDifference(double detectedFreq, double targetFreq) {
    return 1200 * (log(detectedFreq / targetFreq) / log(2));
  }

  Map<String, dynamic> analyze(double freq, double a4) {
    if (freq <= 0) return {"note": "--", "targetFreq": 0.0};

    double midi = 69 + 12 * log(freq / a4) / ln2;
    int midiNote = midi.round();

    String noteName = notes[midiNote % 12];

    double targetFreq = a4 * pow(2, (midiNote - 69) / 12).toDouble();

    return {"note": noteName, "targetFreq": targetFreq};
  }

  @override
  void initState() {
    super.initState();
    _startAutomatically();
  }

  Future<void> _startAutomatically() async {
    var status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) return;

    _pitch.startDetection();
    _pitch.onPitchDetected.listen(_onPitchDetected);

    setState(() {
      initialized = true;
    });
  }

  @override
  void dispose() {
    _pitch.stopDetection();
    super.dispose();
  }

  Map<String, dynamic> _analyzePitch(double freq) {
    if (freq <= 0) return {"note": "--", "cents": 0};

    double midi = 69 + 12 * log(freq / a4) / ln2;
    int midiNote = midi.round();

    String noteName = notes[midiNote % 12];

    double cents =
        1200 * log(freq / (a4 * pow(2, (midiNote - 69) / 12).toDouble())) / ln2;

    return {"note": noteName, "cents": cents.clamp(-50, 50)};
  }

  // ignore: strict_top_level_inference
  void _onPitchDetected(result) {
    double freq = result['frequency'].toDouble() ?? 0.0;

    final analyzed = _analyzePitch(freq);

    setState(() {
      frequency = freq;
      noteFreq = analyze(frequency, a4)["targetFreq"];
      note = analyzed["note"];
    });
  }

  int getOctave(double frequency) {
    if (frequency <= 0) return 4;

    final double octave = log(frequency / 440.0) / log(2) + 4;

    return octave.floor();
  }

  @override
  Widget build(BuildContext context) {
    final appData = Provider.of<AppData>(context);
    final isDark = appData.isDark;
    final localeProvider = Provider.of<LocaleProvider>(context, listen: false);
    // final theme = Theme.of(context);
    final bool isEnglish = localeProvider.locale.languageCode == 'en';

    final analyzed = _analyzePitch(frequency);
    double cents = analyzed["cents"].toDouble();

    bool inRange = cents.abs() <= 20;

    return Directionality(
      textDirection: isEnglish ? TextDirection.ltr : TextDirection.rtl,
      child: Scaffold(
        // appBar: ,
        backgroundColor: isDark
            ? AppColors.background_dark
            : AppColors.background_light,
        body:
            // Directionality(
            //   textDirection: TextDirection.rtl,
            //   child:
            Column(
              children: [
                const SizedBox(height: AppSpacing.space_36),
                ChangeFrequencyTitleWidget(a4: a4, isDark: isDark),
                changeFrequncySlider(isDark),
                const SizedBox(height: AppSpacing.space_24),
                frequencyNotesAndDifferences(isDark),
                FrequencyBoxViewerWidget(
                  inRange: inRange,
                  cents: cents,
                  isDark: isDark,
                ),
                DetectedFrequencyWidget(frequency: frequency, isDark: isDark),
              ],
            ),
        // ),
        bottomNavigationBar: const BottomNavBarWidget(),
      ),
    );
  }

  Padding frequencyNotesAndDifferences(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space_24),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      (note == AppStrings.epmty_text)
                          ? "0.00"
                          : centDifference(
                              frequency,
                              noteFreq,
                            ).toStringAsFixed(2),
                      // textDirection: TextDirection.ltr,
                      style: TextStyle(
                        fontSize: AppSpacing.space_20,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? AppColors.text_primary_dark
                            : AppColors.text_primary_light,
                      ),
                    ),
                    Text(
                      AppStrings.cents.translate(context),
                      // textDirection: TextDirection.ltr,
                      style: TextStyle(
                        fontSize: AppSpacing.space_16,
                        fontWeight: FontWeight.w300,
                        color: isDark
                            ? AppColors.text_secondary_dark
                            : AppColors.text_secondary_light,
                      ),
                    ),
                  ],
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      (note == AppStrings.epmty_text)
                          ? AppStrings.epmty_text
                          : getOctave(noteFreq).toString(),
                      style: TextStyle(
                        fontSize: AppSpacing.space_24,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? AppColors.text_primary_dark
                            : AppColors.text_primary_light,
                      ),
                    ),
                    SizedBox(width: AppSpacing.space_4),
                    Text(
                      note,
                      style: TextStyle(
                        fontSize: AppSpacing.space_48,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? AppColors.text_primary_dark
                            : AppColors.text_primary_light,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      noteFreq.toStringAsFixed(2),
                      // textDirection: TextDirection.ltr,
                      style: TextStyle(
                        fontSize: AppSpacing.space_20,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? AppColors.text_primary_dark
                            : AppColors.text_primary_light,
                      ),
                    ),
                    Text(
                      AppStrings.hertz.translate(context),
                      // textDirection: TextDirection.ltr,
                      style: TextStyle(
                        fontSize: AppSpacing.space_16,
                        fontWeight: FontWeight.w300,
                        color: isDark
                            ? AppColors.text_secondary_dark
                            : AppColors.text_secondary_light,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Slider changeFrequncySlider(bool isDark) {
    return Slider(
      value: a4,
      min: 420,
      max: 460,
      divisions: 40,
      inactiveColor: isDark ? AppColors.border_dark : AppColors.border_light,
      activeColor: isDark
          ? AppColors.text_secondary_dark
          : AppColors.text_secondary_light,
      thumbColor: isDark
          ? AppColors.text_primary_dark
          : AppColors.text_primary_light,

      label: " ${a4.toStringAsFixed(0)}  ${AppStrings.hz.translate(context)} ",
      onChanged: (v) => setState(() => a4 = v),
    );
  }
}

class FrequencyBoxViewerWidget extends StatelessWidget {
  const FrequencyBoxViewerWidget({
    super.key,
    required this.inRange,
    required this.cents,
    required this.isDark,
  });

  final bool inRange;
  final double cents;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space_0),
      child: Stack(
        children: [
          Container(
            height: AppSpacing.space_300,
            decoration: BoxDecoration(
              color: isDark ? AppColors.surface_dark : AppColors.surface_light,
            ),
          ),

          Positioned(
            left: (MediaQuery.of(context).size.width / 2) - AppSpacing.space_50,
            top: AppSpacing.space_0,
            bottom: AppSpacing.space_0,
            child: Container(
              width: AppSpacing.space_100,
              decoration: BoxDecoration(
                color: inRange
                    ? AppColors.success.withAlpha(100)
                    : AppColors.success.withAlpha(40),
              ),
            ),
          ),

          Positioned(
            left: MediaQuery.of(context).size.width / 2 - 1,
            top: AppSpacing.space_0,
            bottom: AppSpacing.space_0,
            child: Container(
              width: 1.5,
              color: AppColors.surface_dark.withAlpha(100),
            ),
          ),

          Positioned(
            left: (MediaQuery.of(context).size.width / 2) + (cents * 3),
            top: AppSpacing.space_0,
            bottom: AppSpacing.space_0,
            child: Container(
              width: AppSpacing.space_4,
              decoration: BoxDecoration(
                color: inRange ? Colors.green : Colors.red,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DetectedFrequencyWidget extends StatelessWidget {
  const DetectedFrequencyWidget({
    super.key,
    required this.frequency,
    required this.isDark,
  });

  final double frequency;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Text(
      "${frequency.toStringAsFixed(1)} ${AppStrings.hz.translate(context)}",
      // textDirection: TextDirection.ltr,
      style: TextStyle(
        fontSize: AppSpacing.space_24,
        color: isDark
            ? AppColors.text_primary_dark
            : AppColors.text_primary_light,
      ),
    );
  }
}

class ChangeFrequencyTitleWidget extends StatelessWidget {
  const ChangeFrequencyTitleWidget({
    super.key,
    required this.a4,
    required this.isDark,
  });

  final double a4;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space_24),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "${a4.toStringAsFixed(0)} ${AppStrings.hz.translate(context)}",
                  // textDirection: TextDirection.ltr,
                  style: TextStyle(
                    fontSize: AppSpacing.space_16,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppColors.text_primary_dark
                        : AppColors.text_primary_light,
                  ),
                ),
                SizedBox(width: AppSpacing.space_4),
                Text(
                  AppStrings.set_base_frequency.translate(context),
                  // textDirection: TextDirection.ltr,
                  style: TextStyle(
                    fontSize: AppSpacing.space_16,
                    color: isDark
                        ? AppColors.text_primary_dark
                        : AppColors.text_primary_light,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
