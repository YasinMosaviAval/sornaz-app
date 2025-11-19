// ignore_for_file: use_build_context_synchronously

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
