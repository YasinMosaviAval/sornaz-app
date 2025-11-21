import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sornaz/components/bottom_nav.dart';
import 'package:metronome/metronome.dart';
import 'package:sornaz/helpers/app_colors.dart';
import 'package:sornaz/helpers/app_data.dart';

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
    final appData = Provider.of<AppData>(context);
    final isDark = appData.isDark;
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
              child: Text(
                'توقف کامل',
                style: TextStyle(
                  color: isDark
                      ? AppColors.text_secondary_dark
                      : AppColors.text_secondary_light,
                ),
              ),
            ),
          ],
        ),
      ),
      /*
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: isDark ? Colors.grey[900] : Colors.white,
        selectedItemColor: isDark ? Colors.yellow[700] : Colors.blue,
        unselectedItemColor: Colors.grey,
        currentIndex: _currentIndex, // ← آیکن فعلی هایلایت می‌شود
        onTap: (index) {
          setState(() {
            _currentIndex = index; // ← تغییر ایندکس
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.library_music),
            label: 'Music Player',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.punch_clock),
            label: 'Metronome',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.tune_rounded),
            label: 'Tuner',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.record_voice_over),
            label: 'Voice Recorder',
          ),
        ],
      ),
      */
      bottomNavigationBar: const BottomNavBarWidget(),
    );
  }
}
