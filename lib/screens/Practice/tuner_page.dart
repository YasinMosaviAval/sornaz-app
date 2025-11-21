// ignore_for_file: use_build_context_synchronously
/*
import 'package:flutter/material.dart';
import 'package:sornaz/components/bottom_nav.dart';
import 'package:flutter_pitch_detection/flutter_pitch_detection.dart';
import 'package:permission_handler/permission_handler.dart';

class TunerPage extends StatefulWidget {
  const TunerPage({super.key});

  @override
  State<TunerPage> createState() => _TunerPageState();
}

class _TunerPageState extends State<TunerPage> {
  final FlutterPitchDetection _pitchDetector = FlutterPitchDetection();
  double frequency = 0.0;
  String note = '';
  bool isListening = false;

  @override
  void dispose() {
    _pitchDetector.stopDetection();
    super.dispose();
  }

  Future<void> _requestPermissionAndStart() async {
    var status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('اجازه دسترسی به میکروفون لازم است')),
      );
      return;
    }
    _pitchDetector.startDetection();
    _pitchDetector.onPitchDetected.listen(_onPitchDetected);
    setState(() => isListening = true);
  }

  void _onPitchDetected(Map<String, dynamic> result) {
    setState(() {
      frequency = result['frequency'] ?? 0.0;
      note = result['note'] ?? '--';
    });
  }

  void _stopListening() {
    _pitchDetector.stopDetection();
    setState(() {
      isListening = false;
      frequency = 0.0;
      note = '--';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("تیونر")),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                note,
                style: const TextStyle(
                  fontSize: 100,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${frequency.toStringAsFixed(1)} Hz',
                style: const TextStyle(fontSize: 28),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: isListening
                    ? _stopListening
                    : _requestPermissionAndStart,
                child: Text(isListening ? 'توقف تیونر' : 'شروع تیونر'),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const BottomNavBarWidget(),
    );
  }
}
*/

/*
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sornaz/components/bottom_nav.dart';
import 'package:flutter_pitch_detection/flutter_pitch_detection.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:math' as math;

import 'package:sornaz/helpers/app_data.dart';

class TunerPage extends StatefulWidget {
  const TunerPage({super.key});
  @override
  State<TunerPage> createState() => _TunerPageState();
}

class _TunerPageState extends State<TunerPage>
    with SingleTickerProviderStateMixin {
  final FlutterPitchDetection _pitchDetector = FlutterPitchDetection();

  double frequency = 0.0;
  String note = '--';
  double cents = 0.0; // اختلاف با نت اصلی به واحد cent
  bool isListening = false;

  late AnimationController _pulseController;

  // نت‌های استاندارد (A4 = 440 Hz)
  final List<String> notes = [
    'C',
    'C#',
    'D',
    'D#',
    'E',
    'F',
    'F#',
    'G',
    'G#',
    'A',
    'A#',
    'B',
  ];
  final double a4Frequency = 440.0;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _requestPermissionAndStart();
  }

  Future<void> _requestPermissionAndStart() async {
    var status = await Permission.microphone.request();
    if (!status.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('اجازه دسترسی به میکروفون لازم است')),
        );
      }
      return;
    }

    await _pitchDetector.startDetection();
    _pitchDetector.onPitchDetected.listen(_onPitchDetected);
    if (mounted) setState(() => isListening = true);
  }

  void _onPitchDetected(Map<String, dynamic> result) {
    if (!mounted) return;
    final double freq = result['frequency'] ?? 0.0;
    if (freq < 50 || freq > 2000) return; // نویز فیلتر شود

    final String detectedNote = _getClosestNote(freq);
    final double noteFreq = _noteFrequency(detectedNote);
    final double centsDiff = _calculateCents(freq, noteFreq);

    setState(() {
      frequency = freq;
      note = detectedNote;
      cents = centsDiff;
    });
  }

  String _getClosestNote(double freq) {
    if (freq <= 0) return '--';
    double minDiff = double.infinity;
    String closest = 'A';
    for (int i = 0; i < 96; i++) {
      // ۸ اکتاو
      final double noteFreq = a4Frequency * math.pow(2, (i - 49) / 12);
      final double diff = (freq - noteFreq).abs();
      if (diff < minDiff) {
        minDiff = diff;
        closest = notes[i % 12];
      }
    }
    return closest;
  }

  double _noteFrequency(String note) {
    final int index = notes.indexOf(note);
    if (index == -1) return a4Frequency;
    return a4Frequency * math.pow(2, (index - 9) / 12); // A = index 9
  }

  double _calculateCents(double detectedFreq, double targetFreq) {
    if (detectedFreq <= 0 || targetFreq <= 0) return 0;
    return 1200 * math.log(detectedFreq / targetFreq) / math.ln2;
  }

  @override
  void dispose() {
    _pitchDetector.stopDetection();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appData = Provider.of<AppData>(context);
    final isDark = !appData.isDark;
    final bool isFlat = cents < -5;
    final bool isSharp = cents > 5;
    final bool isInTune = cents.abs() <= 5;

    return Scaffold(
      appBar: AppBar(title: const Text('تیونر حرفه‌ای')),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          children: [
            const SizedBox(height: 60),

            // نت تشخیص داده شده
            Text(
              note,
              style: TextStyle(
                fontSize: 120,
                fontWeight: FontWeight.bold,
                color: isInTune
                    ? Colors.green
                    : (isFlat ? Colors.red : Colors.orange),
              ),
            ),

            // فرکانس نت اصلی
            Text(
              '${_noteFrequency(note).toStringAsFixed(1)} Hz',
              style: const TextStyle(fontSize: 24, color: Colors.grey),
            ),

            const SizedBox(height: 40),

            // کادر مرکزی با خط نشانگر
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Container(
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(40),
                  border: Border.all(color: Colors.grey[700]!, width: 2),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // خط مرکزی (درست)
                    Container(width: 4, color: Colors.green, height: 60),

                    // خط متحرک بر اساس cent
                    AnimatedAlign(
                      duration: const Duration(milliseconds: 100),
                      alignment: Alignment(cents.clamp(-50, 50) / 50, 0),
                      child: Container(
                        width: 6,
                        height: 70,
                        decoration: BoxDecoration(
                          color: isInTune ? Colors.green : Colors.red,
                          borderRadius: BorderRadius.circular(3),
                          boxShadow: [
                            BoxShadow(
                              color: (isInTune ? Colors.green : Colors.red)
                                  .withOpacity(0.6),
                              blurRadius: 20,
                              spreadRadius: _pulseController.value * 10,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),

            // نمایش اختلاف به cent
            Text(
              '${cents >= 0 ? '+' : ''}${cents.toStringAsFixed(1)} cent',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w600,
                color: isInTune
                    ? Colors.green
                    : (cents > 0 ? Colors.orange : Colors.red),
              ),
            ),

            const Spacer(),

            // نشانگر وضعیت
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: isListening ? Colors.green : Colors.grey[800],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isListening ? Icons.mic : Icons.mic_off,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    isListening
                        ? 'در حال گوش دادن...'
                        : 'بدون دسترسی به میکروفون',
                    style: const TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNavBarWidget(),
    );
  }
}
*/

/*
import 'package:flutter/material.dart';
import 'package:sornaz/components/bottom_nav.dart';
import 'package:flutter_pitch_detection/flutter_pitch_detection.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:math' as math;

class TunerPage extends StatefulWidget {
  const TunerPage({super.key});
  @override
  State<TunerPage> createState() => _TunerPageState();
}

class _TunerPageState extends State<TunerPage>
    with SingleTickerProviderStateMixin {
  final FlutterPitchDetection _pitchDetector = FlutterPitchDetection();

  double frequency = 0.0;
  String note = '--';
  int octave = 4;
  double targetFrequency = 440.0;
  double cents = 0.0;
  bool isListening = false;

  late AnimationController _pulseController;

  final List<String> notes = [
    'C',
    'C#',
    'D',
    'D#',
    'E',
    'F',
    'F#',
    'G',
    'G#',
    'A',
    'A#',
    'B',
  ];
  final double a4Frequency = 440.0;
  final double toleranceCents = 20.0; // محدوده مجاز

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 20),
    )..repeat(reverse: true);
    _requestPermissionAndStart();
  }

  Future<void> _requestPermissionAndStart() async {
    var status = await Permission.microphone.request();
    if (!status.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('اجازه دسترسی به میکروفون لازم است')),
        );
      }
      return;
    }
    await _pitchDetector.startDetection();
    _pitchDetector.onPitchDetected.listen(_onPitchDetected);
    if (mounted) setState(() => isListening = true);
  }

  void _onPitchDetected(Map<String, dynamic> result) {
    if (!mounted) return;
    final double freq = result['frequency'] ?? 0.0;
    if (freq < 50 || freq > 2000) return;

    final (String n, int o, double target) = _getClosestNoteAndOctave(freq);
    final double c = _calculateCents(freq, target);

    setState(() {
      frequency = freq;
      note = n;
      octave = o;
      targetFrequency = target;
      cents = c;
    });
  }

  (String, int, double) _getClosestNoteAndOctave(double freq) {
    double minDiff = double.infinity;
    String bestNote = 'A';
    int bestOctave = 4;
    double bestFreq = a4Frequency;

    for (int octave = 0; octave <= 8; octave++) {
      for (int i = 0; i < 12; i++) {
        final int semitone = octave * 12 + i - 9;
        final double noteFreq = a4Frequency * math.pow(2, semitone / 12.0);
        final double diff = (freq - noteFreq).abs();
        if (diff < minDiff) {
          minDiff = diff;
          bestNote = notes[i];
          bestOctave = octave;
          bestFreq = noteFreq;
        }
      }
    }
    return (bestNote, bestOctave, bestFreq);
  }

  double _calculateCents(double detected, double target) {
    if (detected <= 0 || target <= 0) return 0;
    return 1200 * math.log(detected / target) / math.ln2;
  }

  @override
  void dispose() {
    _pitchDetector.stopDetection();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool inTolerance = cents.abs() <= toleranceCents;
    final bool isFlat = cents < -toleranceCents;
    final bool isSharp = cents > toleranceCents;

    return Scaffold(
      backgroundColor: Colors.black,
      // appBar: AppBar(
      //   title: const Text('تیونر حرفه‌ای'),
      //   backgroundColor: Colors.black,
      //   foregroundColor: Colors.white,
      //   elevation: 0,
      // ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          children: [
            const Spacer(flex: 2),

            // نت + اکتاو
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  note,
                  style: TextStyle(
                    fontSize: 140,
                    fontWeight: FontWeight.bold,
                    color: inTolerance
                        ? Colors.green.shade400
                        : (isFlat ? Colors.red.shade400 : Colors.orange),
                  ),
                ),
                Text(
                  '$octave',
                  style: const TextStyle(fontSize: 60, color: Colors.grey),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // فرکانس دقیق نت
            Text(
              '${targetFrequency.toStringAsFixed(2)} Hz',
              style: const TextStyle(fontSize: 28, color: Colors.grey),
            ),

            const SizedBox(height: 60),

            // کادر اصلی تیونر (مثل Tuner T1)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Container(
                height: 120,
                decoration: BoxDecoration(
                  color: inTolerance
                      ? Colors.green.withOpacity(0.15)
                      : Colors.grey[900],
                  borderRadius: BorderRadius.circular(60),
                  border: Border.all(
                    color: inTolerance
                        ? Colors.green.shade400
                        : Colors.grey[700]!,
                    width: 3,
                  ),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // خط مرکزی (دقیق)
                    Container(
                      width: 4,
                      height: 90,
                      color: Colors.green.shade400,
                    ),

                    // محدوده ±20 cent (دو خط عمودی)
                    Positioned(
                      left: 100 * (20 / 50), // 50 cent = عرض کامل
                      child: Container(
                        width: 2,
                        height: 80,
                        color: Colors.grey[600],
                      ),
                    ),
                    Positioned(
                      right: 100 * (20 / 50),
                      child: Container(
                        width: 2,
                        height: 80,
                        color: Colors.grey[600],
                      ),
                    ),

                    // نشانگر متحرک
                    AnimatedAlign(
                      duration: const Duration(milliseconds: 100),
                      alignment: Alignment(cents.clamp(-50, 50) / 50, 0),
                      child: Container(
                        width: 10,
                        height: 100,
                        decoration: BoxDecoration(
                          color: inTolerance
                              ? Colors.green.shade400
                              : Colors.red,
                          borderRadius: BorderRadius.circular(5),
                          boxShadow: [
                            BoxShadow(
                              color: (inTolerance ? Colors.green : Colors.red)
                                  .withOpacity(0.8),
                              blurRadius: 30,
                              spreadRadius: _pulseController.value * 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 40),

            // اختلاف به cent
            Text(
              '${cents >= 0 ? '+' : ''}${cents.toStringAsFixed(1)} cent',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: inTolerance
                    ? Colors.green.shade400
                    : (cents > 0 ? Colors.orange : Colors.red.shade400),
              ),
            ),

            const Spacer(flex: 3),

            // وضعیت میکروفون
            Container(
              margin: const EdgeInsets.all(30),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: isListening
                    ? Colors.green.withOpacity(0.2)
                    : Colors.red.withOpacity(0.2),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: isListening ? Colors.green : Colors.red,
                  width: 2,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isListening ? Icons.mic : Icons.mic_off,
                    color: isListening ? Colors.green : Colors.red,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    isListening ? 'در حال گوش دادن...' : 'میکروفون غیرفعال',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: isListening ? Colors.green : Colors.red,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNavBarWidget(),
    );
  }
}
*/

/*
import 'package:flutter/material.dart';
import 'package:sornaz/components/bottom_nav.dart';
import 'package:flutter_pitch_detection/flutter_pitch_detection.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:math';

class TunerPage extends StatefulWidget {
  const TunerPage({super.key});

  @override
  State<TunerPage> createState() => _TunerPageState();
}

class _TunerPageState extends State<TunerPage> {
  final FlutterPitchDetection _pitchDetector = FlutterPitchDetection();

  double frequency = 0.0;
  String detectedNote = '--';
  double cents = 0.0;
  double targetFrequency = 0.0;

  @override
  void initState() {
    super.initState();
    _requestPermissionAndStart();
  }

  @override
  void dispose() {
    _pitchDetector.stopDetection();
    super.dispose();
  }

  Future<void> _requestPermissionAndStart() async {
    var status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('اجازهٔ دسترسی به میکروفون لازم است.')),
      );
      return;
    }

    _pitchDetector.startDetection();
    _pitchDetector.onPitchDetected.listen(_onPitchDetected);
  }

  // لیست نت‌ها
  static const List<String> noteNames = [
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

  // محاسبه نزدیک‌ترین نت
  void _onPitchDetected(Map<String, dynamic> result) {
    double freq = result["frequency"] ?? 0.0;

    if (freq == 0.0) {
      setState(() {
        detectedNote = "--";
        targetFrequency = 0.0;
        cents = 0.0;
      });
      return;
    }

    // محاسبه شماره MIDI (A4=440Hz => midi 69)
    double midi = 69 + 12 * log(freq / 440) / log(2);
    int nearestMidi = midi.round();

    // نت مربوطه
    int noteIndex = nearestMidi % 12;
    int octave = (nearestMidi ~/ 12) - 1;

    String noteName = "${noteNames[noteIndex]}$octave";

    // فرکانس نت اصلی
    num noteFreq = 440 * pow(2, (nearestMidi - 69) / 12);

    // اختلاف سنت
    double centDiff = 1200 * log(freq / noteFreq) / ln2;

    setState(() {
      frequency = freq;
      detectedNote = noteName;
      targetFrequency = noteFreq.toDouble();
      cents = centDiff;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("تیونر")),
      bottomNavigationBar: const BottomNavBarWidget(),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ====== نت اصلی =======
              Text(
                detectedNote,
                style: const TextStyle(
                  fontSize: 90,
                  fontWeight: FontWeight.bold,
                ),
              ),

              // ====== فرکانس =======
              Text(
                targetFrequency == 0
                    ? "-- Hz"
                    : "${targetFrequency.toStringAsFixed(2)} Hz",
                style: const TextStyle(fontSize: 22),
              ),

              const SizedBox(height: 30),

              // ====== نوار تیونر =======
              _buildTunerMeter(),

              const SizedBox(height: 30),

              // ====== فرکانس فعلی =======
              Text(
                frequency == 0
                    ? "در حال گوش دادن..."
                    : "فرکانس شنیده‌شده: ${frequency.toStringAsFixed(1)} Hz",
                style: const TextStyle(fontSize: 18),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ویجت نوار تیونر (نمایش مقدار سنت)
  Widget _buildTunerMeter() {
    double position = (cents / 50).clamp(-1, 1); // هر 50 سنت یک طرف

    return Container(
      width: MediaQuery.of(context).size.width * 0.85,
      height: 70,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // خط وسط
          Container(width: 3, height: 70, color: Colors.black),

          // خط متحرک (اشاره‌گر)
          Align(
            alignment: Alignment(position, 0),
            child: Container(width: 3, height: 70, color: Colors.red),
          ),
        ],
      ),
    );
  }
}
*/

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_pitch_detection/flutter_pitch_detection.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:sornaz/components/bottom_nav.dart';
import 'package:sornaz/helpers/app_colors.dart';
import 'package:sornaz/helpers/app_data.dart';
import 'package:sornaz/helpers/app_spacing.dart';

class TunerPage extends StatefulWidget {
  const TunerPage({super.key});

  @override
  State<TunerPage> createState() => _TunerPageState();
}

class _TunerPageState extends State<TunerPage> {
  final FlutterPitchDetection _pitch = FlutterPitchDetection();

  double frequency = 0.0;
  String note = "";
  double a4 = 440.0;
  bool initialized = false;
  double noteFreq = 0.0;

  /// نت‌های استاندارد کروماتیک
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

  /// تبدیل فرکانس به نت و محاسبه اختلاف سنت
  Map<String, dynamic> _analyzePitch(double freq) {
    if (freq <= 0) return {"note": "--", "cents": 0};

    // محاسبه شماره MIDI
    double midi = 69 + 12 * log(freq / a4) / ln2;
    int midiNote = midi.round();

    String noteName = notes[midiNote % 12];

    // اختلاف سنت با نزدیک‌ترین نت
    double cents =
        1200 * log(freq / (a4 * pow(2, (midiNote - 69) / 12).toDouble())) / ln2;

    return {"note": noteName, "cents": cents.clamp(-50, 50)};
  }

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

    // فرمول استاندارد MIDI برای اکتاو
    final double octave = log(frequency / 440.0) / log(2) + 4;

    // استفاده از floor یا round بر اساس استاندارد
    return octave.floor(); // یا octave.round() اگر می‌خوای دقیق‌تر باشه
  }

  @override
  Widget build(BuildContext context) {
    final appData = Provider.of<AppData>(context);
    final isDark = appData.isDark;
    final analyzed = _analyzePitch(frequency);
    double cents = analyzed["cents"].toDouble();
    // double cents = (analyzed["cents"] as num).toDouble();

    bool inRange = cents.abs() <= 20;

    return Scaffold(
      // appBar: AppBar(title: const Text("تیونر")),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          children: [
            const SizedBox(height: 40),

            /// تغییر فرکانس A4
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.space_24,
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "${a4.toStringAsFixed(0)} Hz",
                          textDirection: TextDirection.ltr,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(width: AppSpacing.space_4),
                        Text(
                          "تنظیم فرکانس مبنا (A4): ",
                          textDirection: TextDirection.ltr,
                          style: TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Slider(
              value: a4,
              min: 420,
              max: 460,
              divisions: 40,
              inactiveColor: isDark
                  ? AppColors.border_dark
                  : AppColors.border_light,
              activeColor: isDark
                  ? AppColors.text_secondary_dark
                  : AppColors.text_secondary_light,
              thumbColor: isDark
                  ? AppColors.text_primary_dark
                  : AppColors.text_primary_light,

              label: " ${a4.toStringAsFixed(0)}  Hz ",
              onChanged: (v) => setState(() => a4 = v),
            ),

            const SizedBox(height: 20),

            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.space_24,
              ),
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
                              (note == "")
                                  ? "0.00"
                                  : centDifference(
                                      frequency,
                                      noteFreq,
                                    ).toStringAsFixed(2),
                              textDirection: TextDirection.ltr,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w500,
                                color: isDark
                                    ? AppColors.text_primary_dark
                                    : AppColors.text_primary_light,
                              ),
                            ),
                            Text(
                              "CENTS",
                              textDirection: TextDirection.ltr,
                              style: TextStyle(
                                fontSize: 16,
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
                              (note == "")
                                  ? ""
                                  : getOctave(noteFreq).toString(),
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(width: AppSpacing.space_4),
                            Text(
                              note,
                              style: const TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              noteFreq.toStringAsFixed(2),
                              textDirection: TextDirection.ltr,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w500,
                                color: isDark
                                    ? AppColors.text_primary_dark
                                    : AppColors.text_primary_light,
                              ),
                            ),
                            Text(
                              "HERTZ",
                              textDirection: TextDirection.ltr,
                              style: TextStyle(
                                fontSize: 16,
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
            ),

            /// نوار سنت مشابه Tuner T1
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 0),
              child: Stack(
                children: [
                  Container(
                    height: 300,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      // borderRadius: BorderRadius.circular(12),
                    ),
                  ),

                  // محدوده ±20 سنت
                  Positioned(
                    left: (MediaQuery.of(context).size.width / 2) - 50,
                    top: 0,
                    bottom: 0,
                    child: Container(
                      width: 100,
                      decoration: BoxDecoration(
                        color: inRange
                            ? AppColors.success.withAlpha(100)
                            : AppColors.success.withAlpha(40),
                        // : isDark
                        // ? AppColors.surface_dark
                        // : AppColors.surface_light,
                        // borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),

                  // خط مرکزی
                  Positioned(
                    left: MediaQuery.of(context).size.width / 2 - 1,
                    top: 0,
                    bottom: 0,
                    child: Container(
                      width: 1.5,
                      color: AppColors.surface_dark.withAlpha(100),
                    ),
                  ),

                  // نشانگر فرکانس
                  Positioned(
                    left:
                        (MediaQuery.of(context).size.width / 2) +
                        (cents * 3), // هر سنت = 3px
                    top: 0,
                    bottom: 0,
                    child: Container(
                      width: 4,
                      decoration: BoxDecoration(
                        color: inRange ? Colors.green : Colors.red,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Text(
            //   "${frequency.toStringAsFixed(1)} Hz",
            //   textDirection: TextDirection.ltr,
            //   style: const TextStyle(fontSize: 24),
            // ),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNavBarWidget(),
    );
  }
}
