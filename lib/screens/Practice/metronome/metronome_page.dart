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
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [

              
              /// BPM + Tempo name

              Column(
                children: [
                  Row(
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
                  Text(
                    tempoName,
                    style: AppTypography.subtitle1(context),
                  ),
                ],
              ),


              const SizedBox(height: 36),

              Slider(
                value: bpm.toDouble(),
                min: 40,
                max: 200,
                onChanged: (v) {
                  setState(() => bpm = v.toInt());
                  _controller.setBpm(bpm);
                },
              ),

              const SizedBox(height: 75),

              // Text('Time Signature', style: AppTypography.body3(context)),

              SizedBox(
                width: 48,
                height: 48,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 0),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.hovered_dark : AppColors.hovered_light,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: DropdownButton<TimeSignatureOption>(
                    value: selectedTimeSignature,
                    isExpanded: true,
                    icon: const SizedBox.shrink(),
                    underline: const SizedBox(),
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

              
              const SizedBox(height: 75),

/*
              DropdownButton<NoteLength>(
                value: _controller.selectedNote,
                icon: const SizedBox.shrink(),
                underline: Container(height: 1, color: Colors.grey),
                items: noteLengths.map((note) {
                  return DropdownMenuItem<NoteLength>(
                    value: note,
                    child: Row(
                      children: [
                        note.icon,
                        const SizedBox(width: 8),
                        Text(note.name),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _controller.setNoteLength(value);
                    });
                  }
                },
              ),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: noteLengths.map((note) {
                  final isSelected = _controller.selectedNote == note;
                  return GestureDetector(
                    onTap: () => setState(() => _controller.setNoteLength(note)),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.blueAccent : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: note.icon,
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 24),
*/

/*
              // / Beat indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(
                  timeSignature,
                  (index) => Container(
                    margin: const EdgeInsets.all(4),
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _controller.currentBeat == index
                          ? isDark? AppColors.text_primary_dark : AppColors.text_primary_light
                          // : isDark? AppColors.text_secondary_dark : AppColors.text_secondary_light
                          : isDark? AppColors.hovered_dark : AppColors.hovered_light
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),
*/

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
                        color: isDark ? AppColors.hovered_dark : AppColors.hovered_light,
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
                              : (isDark ? AppColors.hovered_dark : AppColors.hovered_light),
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

/*
              // Stop button
              IconButton(
                iconSize: 36,
                icon: const Icon(Icons.stop),
                onPressed: () {
                  setState(() {
                    _controller.stop();
                  });
                },
              ),
*/

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
}

