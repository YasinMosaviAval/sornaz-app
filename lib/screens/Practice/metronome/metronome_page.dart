import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sornaz/components/bottom_nav.dart';
import 'package:sornaz/helpers/app_colors.dart';
import 'package:sornaz/helpers/app_data.dart';
import 'package:sornaz/helpers/app_locale_provider.dart';
import 'package:sornaz/helpers/app_spacing.dart';
import 'package:sornaz/helpers/app_strings.dart';
import 'package:sornaz/helpers/app_typography.dart';
import 'package:sornaz/screens/Practice/metronome/metronome_controller.dart';
import 'package:sornaz/screens/Practice/metronome/metronome_settings_page.dart';
import 'package:sornaz/screens/Practice/metronome/note_length.dart';
import 'package:sornaz/screens/Practice/metronome/tempo_terms.dart';
import 'package:sornaz/screens/Practice/metronome/time_signature_option.dart';
class MetronomePage extends StatefulWidget {
  const MetronomePage({super.key});

  @override
  State<MetronomePage> createState() => _MetronomePageState();
}

class _MetronomePageState extends State<MetronomePage> with SingleTickerProviderStateMixin {
  final MetronomeController _controller = MetronomeController();

  late AnimationController _pulseController;

  int bpm = 120;
  int timeSignature = 4;
  late TimeSignatureOption selectedTimeSignature;

  String formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  int selectedMinutes = 0;
  int selectedSeconds = 0;
  int selectedBars = 4;

  TimeOfDay? selectedTime; // <-- اضافه کردن این خط

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );

    _controller.onBeat = () {
      _pulseController.forward(from: 0);
      setState(() {});
    };

    _controller.init();

    
    selectedTimeSignature = timeSignatures.firstWhere(
      (t) => t.beats == 4 && t.noteValue == 4,
    );

    _controller.onPracticeTick = () => setState(() {});
    _controller.onPracticeFinished = () {
      // مثلاً SnackBar یا Dialog
    };

    _controller.setPracticeTimer(
      minutes: selectedMinutes,
      seconds: selectedSeconds,
    );

  }

  @override
  void dispose() {
    _pulseController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appData = Provider.of<AppData>(context);
    final isDark = appData.isDark;
    final localeProvider = Provider.of<LocaleProvider>(context, listen: false);
    final isEnglish = localeProvider.locale.languageCode == AppStrings.localization_en;

    final tempoName = getTempoName(bpm);

    return Directionality(
      textDirection: isEnglish ? TextDirection.ltr : TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: IconButton(
            icon: const Icon(Icons.settings),
            color: isDark? AppColors.text_primary_dark : AppColors.text_primary_light,
            iconSize: 36,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MetronomeSettingsPage(controller: _controller),
                ),
              );
            },
          ),
          automaticallyImplyLeading: false,
          backgroundColor: isDark? AppColors.surface_dark : AppColors.surface_light,
        ),
        backgroundColor: isDark? AppColors.background_dark : AppColors.background_light,
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              /// BPM + Tempo name
              Column(
                children: [
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          bpm.toString(),
                          style: AppTypography.body0(context),
                        ),
                        AppSpacing.sizedBoxW8(),
                        Text(
                          'BPM',
                          style: AppTypography.subtitle3(context),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    tempoName,
                    style: AppTypography.subtitle1(context),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              Slider(
                value: bpm.toDouble(),
                min: 40,
                max: 200,
                activeColor: isDark? AppColors.primary_dark : AppColors.primary_light,
                inactiveColor: isDark? AppColors.text_secondary_dark : AppColors.text_secondary_light,
                onChanged: (v) {
                  setState(() => bpm = v.toInt());
                  _controller.setBpm(bpm);
                },
              ),

              const SizedBox(height: 56),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Directionality(
                  textDirection: TextDirection.ltr,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SizedBox(
                        width: 48,
                        height: 48,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 0),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.clicked_dark : AppColors.clicked_light,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: DropdownButton<TimeSignatureOption>(
                            value: selectedTimeSignature,
                            isExpanded: true,
                            icon: const SizedBox.shrink(),
                            underline: const SizedBox(),
                            dropdownColor: isDark? AppColors.surface_dark : AppColors.surface_light,
                            items: timeSignatures.map((option) {
                              return DropdownMenuItem(
                                value: option,
                                child: Center(
                                  child: Text(
                                    option.label,
                                    style: AppTypography.body2(context),
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value == null) return;
                              setState(() {
                                selectedTimeSignature = value;
                                _controller.setTimeSignature(value.beats);
                              });
                            },
                          ),
                        ),
                      ),

                      Row(
                        children: noteLengths.map((note) {
                          final isSelected = _controller.selectedNote == note;
                          return GestureDetector(
                            onTap: () => setState(() => _controller.setNoteLength(note)),
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 8),
                              child: note.icon(color: isSelected 
                                ? isDark ? AppColors.text_primary_dark : AppColors.text_primary_light
                                : isDark ? AppColors.unselected_item_dark : AppColors.unselected_item_light,
                                isSelectedIcon: isSelected
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 56),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ChoiceChip(
                    label: Text('Timer'),
                    labelStyle: TextStyle(
                      color: isDark? AppColors.text_primary_light : AppColors.text_primary_dark,
                    ),
                    selected: _controller.stopMode == StopMode.timer,
                    checkmarkColor: isDark? AppColors.text_primary_light : AppColors.text_primary_dark,
                    selectedColor: isDark? AppColors.primary_dark : AppColors.primary_light,
                    backgroundColor: isDark? AppColors.clicked_dark : AppColors.clicked_light,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _controller.enableTimerMode(
                            minutes: selectedMinutes,
                            seconds: selectedSeconds,
                          );
                        } else {
                          _controller.disableStopConditions();
                        }
                      });
                    },
                  ),
                  const SizedBox(width: 12),
                  ChoiceChip(
                    label: const Text('Bars'),
                    selected: _controller.stopMode == StopMode.bars,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _controller.enableBarsMode(selectedBars);
                        } else {
                          _controller.disableStopConditions();
                        }
                      });
                    },
                  ),
                ],
              ),

              const SizedBox(height: 8),

              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IgnorePointer(
                      ignoring: _controller.stopMode != StopMode.timer,
                      child: Opacity(
                        opacity: _controller.stopMode == StopMode.timer ? 1 : 0.3,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _minutesDropdown(),
                            const SizedBox(width: 12),
                            _secondsDropdown(),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                    IgnorePointer(
                      ignoring: _controller.stopMode != StopMode.bars,
                      child: Opacity(
                        opacity: _controller.stopMode == StopMode.bars ? 1.0 : 0.3,
                        child: DropdownButton<int>(
                          value: selectedBars,
                          alignment: Alignment.center,
                          items: List.generate(
                            64,
                            (i) => DropdownMenuItem(
                              value: i + 2,
                              child: Text('${i + 1} Bars'),
                            ),
                          ),
                          onChanged: _controller.stopMode == StopMode.bars
                              ? (v) {
                                  if (v == null) return;
                                  setState(() {
                                    selectedBars = v;
                                    _controller.enableBarsMode(v);
                                  });
                                }
                              : null,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 48),

              /// Play / Pause button with pulse
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _controller.tapTempo();
                        bpm = _controller.bpm;
                      });
                    },
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDark ? AppColors.clicked_dark : AppColors.clicked_light,
                      ),
                      child: Icon(
                        Icons.touch_app,
                        size: 32,
                        color: isDark ? AppColors.text_primary_dark : AppColors.text_primary_light,
                      ),
                    ),
                  ),

                  ScaleTransition(
                    scale: Tween(begin: 1.0, end: 1.1).animate(
                      CurvedAnimation(
                        parent: _pulseController,
                        curve: Curves.easeOut,
                      ),
                    ),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _controller.isPlaying ? _controller.stop() : _controller.start();
                        });
                      },
                      child: Container(
                        width: AppSpacing.space_100,
                        height: AppSpacing.space_100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _controller.isAccentBeat
                              ? isDark ? AppColors.primary_dark : AppColors.primary_light
                              : (isDark ? AppColors.clicked_dark : AppColors.clicked_light),
                        ),
                        child: Icon(
                          _controller.isPlaying ? Icons.pause : Icons.play_arrow,
                          size: AppSpacing.space_56,
                          color: _controller.isAccentBeat
                              ? isDark ? AppColors.surface_dark : AppColors.surface_light
                              : isDark ? AppColors.text_primary_dark : AppColors.text_primary_light,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        bottomNavigationBar: const BottomNavBarWidget(),
      ),
    );
  }

    String getTempoName(int bpm) {
    return tempoTerms
        .firstWhere(
          (term) => bpm >= term.min && bpm <= term.max,
          orElse: () => const TempoTerm('—', 0, 0),
        )
        .name;
  }

Widget _minutesDropdown() {
  return DropdownButton<int>(
    value: selectedMinutes,
    items: List.generate(
      60,
      (i) => DropdownMenuItem(
        value: i,
        child: Text('$i min'),
      ),
    ),
    onChanged: (v) {
      if (v == null) return;
      setState(() {
        selectedMinutes = v;
        _controller.enableTimerMode(
          minutes: selectedMinutes,
          seconds: selectedSeconds,
        );
      });
    },
  );
}

Widget _secondsDropdown() {
  return DropdownButton<int>(
    value: selectedSeconds,
    items: List.generate(
      60,
      (i) => DropdownMenuItem(
        value: i,
        child: Text('$i sec'),
      ),
    ),
    onChanged: (v) {
      if (v == null) return;
      setState(() {
        selectedSeconds = v;
        _controller.enableTimerMode(
          minutes: selectedMinutes,
          seconds: selectedSeconds,
        );
      });
    },
  );
}


}

