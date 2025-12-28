// ignore_for_file: unused_field

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sornaz/components/bottom_nav.dart';
import 'package:sornaz/helpers/app_colors.dart';
import 'package:sornaz/helpers/app_data.dart';
import 'package:sornaz/helpers/app_locale_provider.dart';
import 'package:sornaz/helpers/app_spacing.dart';
import 'package:sornaz/helpers/app_strings.dart';
import 'package:sornaz/helpers/app_typography.dart';
import 'package:sornaz/screens/Practice/metronome/Components/bpm_header.dart';
import 'package:sornaz/screens/Practice/metronome/Components/bpm_slider.dart';
import 'package:sornaz/screens/Practice/metronome/Components/stop_mode_section.dart';
import 'package:sornaz/screens/Practice/metronome/Components/time_signature_row.dart';
import 'package:sornaz/screens/Practice/metronome/controller/metronome_controller.dart';
import 'package:sornaz/screens/Practice/metronome/screens/metronome_settings_page.dart';
import 'package:sornaz/screens/Practice/metronome/classes/tempo_terms.dart';
import 'package:sornaz/screens/Practice/metronome/classes/time_signature_option.dart';
class MetronomePage extends StatefulWidget {
  const MetronomePage({super.key});

  @override
  State<MetronomePage> createState() => _MetronomePageState();
}

class _MetronomePageState extends State<MetronomePage> with TickerProviderStateMixin  {
  final MetronomeController _controller = MetronomeController();
  late AnimationController _uiController;
  late Animation<double> _tapOpacity;
  late Animation<double> _tapScale;
  late Animation<Offset> _playButtonOffset;

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

    _uiController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _tapOpacity = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(parent: _uiController, curve: Curves.easeOut),
    );

    _tapScale = Tween<double>(begin: 1, end: 0.7).animate(
      CurvedAnimation(parent: _uiController, curve: Curves.easeOut),
    );

    _playButtonOffset = Tween<Offset>(
      begin: const Offset(0, 0),
      end: const Offset(0, 0),
    ).animate(
      CurvedAnimation(parent: _uiController, curve: Curves.easeOutCubic),
    );

  }

  @override
  void dispose() {
    _uiController.dispose();
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
        appBar: _MetronomeAppBar(isDark, _controller),
        backgroundColor: isDark? AppColors.background_dark : AppColors.background_light,
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              BpmHeader(bpm: bpm, tempoName: tempoName),

              const SizedBox(height: 16),

              BpmSlider(
                bpm: bpm,
                isDark: isDark,
                onChanged: (value) {
                  setState(() => bpm = value);
                  _controller.setBpm(value);
                },
              ),

              const SizedBox(height: 56),

              TimeSignatureSection(
                controller: _controller,
                selected: selectedTimeSignature,
                isDark: isDark,
                onChanged: (value) {
                  setState(() {
                    selectedTimeSignature = value;
                    _controller.setTimeSignature(value.beats);
                  });
                },
              ),
              
              const SizedBox(height: 56),

              StopModeSection(
                controller: _controller,
                isDark: isDark,
                selectedBars: selectedBars,
                selectedMinutes: selectedMinutes,
                selectedSeconds: selectedSeconds,
                onBarsChanged: (v) {
                  setState(() => selectedBars = v);
                  _controller.enableBarsMode(v);
                },
                onTimerChanged: (m, s) {
                  setState(() {
                    selectedMinutes = m;
                    selectedSeconds = s;
                  });
                  _controller.enableTimerMode(minutes: m, seconds: s);
                },
              ),

              const SizedBox(height: 8),

              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_controller.showTimerStopwatch)
                      IgnorePointer(
                        ignoring: _controller.stopMode != StopMode.timer,
                        child: Opacity(
                          opacity: _controller.stopMode == StopMode.timer ? 1 : 0.3,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _minutesDropdown(isDark),
                              const SizedBox(width: 12),
                              _secondsDropdown(isDark),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(width: 48),
                    if (_controller.showBarsStopwatch)
                      _barsDropdown(isDark),
                  ],
                ),
              ),

              const SizedBox(height: 48),

              SizedBox(
                height: 120,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (_controller.showTapTempo)
                      AnimatedOpacity(
                        duration: const Duration(milliseconds: 500),
                        opacity: _controller.isPlaying ? 0 : 1,
                        child: Align(
                          alignment: const Alignment(0.5, 0),
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _controller.tapTempo();
                                bpm = _controller.bpm;
                              });
                            },
                            child: AnimatedBuilder(
                              animation: _controller,
                              builder: (context, child) {
                                return Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: _controller.tapActive
                                        ? (isDark ? AppColors.primary_dark : AppColors.primary_light)
                                        : (isDark ? AppColors.clicked_dark : AppColors.clicked_light),
                                  ),
                                  child: Icon(
                                    Icons.touch_app,
                                    size: 32,
                                    color: _controller.tapActive
                                        ? (isDark ?  AppColors.text_primary_light : AppColors.text_primary_dark)
                                        : (isDark ?  AppColors.text_primary_dark : AppColors.text_primary_light),
                                  ),
                                );
                              },
                            )
                          ),
                        ),
                      ),
                    SlideTransition(
                      position: _playButtonOffset,
                      child: AnimatedAlign(
                        duration: const Duration(milliseconds: 500),
                        alignment: _controller.showTapTempo
                          ? _controller.isPlaying ? Alignment(0, 0) : Alignment(-0.5, 0)
                          : _controller.isPlaying ? Alignment(0, 0) : Alignment(0, 0),
                        curve: Curves.easeOutCubic,
                        child: ScaleTransition(
                        scale: Tween(begin: 1.0, end: 1.1).animate(
                          CurvedAnimation(
                            parent: _pulseController,
                            curve: Curves.easeOut,
                          ),
                        ),
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              if (_controller.isPlaying) {
                                _controller.stop();
                              } else {
                                _controller.start();
                              }
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
                    ),
                    )
                  ],
                ),
              )

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

  Widget _minutesDropdown(bool isDark) {
    return DropdownButton<int>(
      value: selectedMinutes,
      dropdownColor: isDark ? AppColors.surface_dark : AppColors.surface_light,
      iconEnabledColor: isDark ? AppColors.text_secondary_dark : AppColors.text_secondary_light,
      iconDisabledColor: isDark ? AppColors.text_secondary_dark : AppColors.text_secondary_light,
      underline: null,
      items: List.generate(
        60,
        (i) => DropdownMenuItem(
          value: i,
          child: Text(
            '$i min',
            style: AppTypography.body2(context),
          ),
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

  Widget _secondsDropdown(bool isDark) {
      return DropdownButton<int>(
        value: selectedSeconds,
        dropdownColor: isDark ? AppColors.surface_dark : AppColors.surface_light,
        iconEnabledColor: isDark ? AppColors.text_secondary_dark : AppColors.text_secondary_light,
        iconDisabledColor: isDark ? AppColors.text_secondary_dark : AppColors.text_secondary_light,
        underline: null,
        items: List.generate(
          60,
          (i) => DropdownMenuItem(
            value: i,
            child: Text(
              '$i sec',
              style: AppTypography.body2(context),
            ),
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

  IgnorePointer _barsDropdown(bool isDark) {
    return IgnorePointer(
      ignoring: _controller.stopMode != StopMode.bars,
      child: Opacity(
        opacity: _controller.stopMode == StopMode.bars ? 1.0 : 0.3,
        child: DropdownButton<int>(
          value: selectedBars,
          dropdownColor: isDark ? AppColors.surface_dark : AppColors.surface_light,
          iconEnabledColor: isDark ? AppColors.text_secondary_dark : AppColors.text_secondary_light,
          iconDisabledColor: isDark ? AppColors.text_secondary_dark : AppColors.text_secondary_light,
          underline: null,
          items: List.generate(
            64,
            (i) => DropdownMenuItem(
              value: i + 2,
              child: Text(
                '${i + 1} Bars',
                style: AppTypography.body2(context)
              ),
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
    );
  }

}

class _MetronomeAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  final bool isDark;
  final MetronomeController controller;

  const _MetronomeAppBar(this.isDark, this.controller);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor:
          isDark ? AppColors.surface_dark : AppColors.surface_light,
      title: IconButton(
        icon: const Icon(Icons.settings),
        iconSize: AppSpacing.space_32,
        color: isDark
            ? AppColors.text_primary_dark
            : AppColors.text_primary_light,
        onPressed: () async {
          final result = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  MetronomeSettingsPage(controller: controller),
            ),
          );
          if (result != null) {
            // فقط برای rebuild
          }
        },
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
