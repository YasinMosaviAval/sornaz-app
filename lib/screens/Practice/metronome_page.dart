import 'package:flutter/material.dart';
import 'package:sornaz/components/bottom_nav.dart';
import 'package:metronome/metronome.dart';

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
    metronome.destroy(); // تمیز کردن منابع
    super.dispose();
  }

  Future<void> initMetronome() async {
    await metronome.init(
      'assets/audio/tick.wav', // مسیر فایل صدای تیک معمولی – اضافه کن به assets
      accentedPath: 'assets/audio/accent.wav', // صدای accent – اضافه کن
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
    return Scaffold(
      appBar: AppBar(title: const Text("مترونوم")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('BPM: $bpm', style: const TextStyle(fontSize: 24)),
            Slider(
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
            ),
            Text('زمان‌بندی: $timeSignature/4'),
            Slider(
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
            ),
            Text('ولوم: ${volume.toInt()}%'),
            Slider(
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
            ),
            ElevatedButton(
              onPressed: initMetronome,
              child: Text(isInitialized ? 'راه‌اندازی مجدد' : 'راه‌اندازی'),
            ),
            ElevatedButton(
              onPressed: isInitialized ? togglePlayPause : null,
              child: Text(isPlaying ? 'توقف موقت' : 'پخش'),
            ),
            ElevatedButton(
              onPressed: isInitialized ? stopMetronome : null,
              child: const Text('توقف کامل'),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNavBarWidget(),
    );
  }
}
