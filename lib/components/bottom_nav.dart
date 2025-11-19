import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sornaz/helpers/app_data.dart';
import 'package:sornaz/screens/Articles/articles.dart';
import 'package:sornaz/screens/Players/music_palyer.dart';
import 'package:sornaz/screens/Practice/metronome_page.dart';
import 'package:sornaz/screens/Practice/tuner_page.dart';
import 'package:sornaz/screens/Profile/voice_recorder.dart';

class BottomNavBarWidget extends StatelessWidget {
  const BottomNavBarWidget({super.key});

  void _onItemTapped(BuildContext context, int index) {
    Widget targetPage;

    switch (index) {
      case 0:
        // targetPage = const HomePage();
        targetPage = const ArticlesPage();
        break;
      case 1:
        // targetPage = const MusicSheetsPage();
        targetPage = const MusicPlayerPage();
        break;
      case 2:
        targetPage = const MetronomePage();
        break;
      case 3:
        targetPage = const TunerPage();
        break;
      case 4:
        targetPage = const VoiceRecorderPage();
        // targetPage = const ProfilePage();
        break;
      default:
        // targetPage = const HomePage();
        targetPage = const ArticlesPage();
    }

    // رفتن به صفحه جدید
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => targetPage,
        transitionDuration: const Duration(milliseconds: 250), // انیمیشن سریع
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appData = Provider.of<AppData>(context);
    final isDark = appData.isDark;

    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      backgroundColor: isDark ? Colors.grey[900] : Colors.white,
      selectedItemColor: isDark ? Colors.yellow[700] : Colors.blue,
      unselectedItemColor: Colors.grey,
      onTap: (index) => _onItemTapped(context, index),
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        // BottomNavigationBarItem(
        //   icon: Icon(Icons.music_note),
        //   label: 'Music Sheet',
        // ),
        BottomNavigationBarItem(
          icon: Icon(Icons.library_music),
          label: 'Music Player',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.punch_clock),
          label: 'Metronome',
        ),
        BottomNavigationBarItem(icon: Icon(Icons.tune_rounded), label: 'Tuner'),
        // BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        BottomNavigationBarItem(
          icon: Icon(Icons.record_voice_over),
          label: 'Voice Recorder',
        ),
      ],
    );
  }
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  int _currentIndex = 0; // مدیریت ایندکس فعلی

  // لیست صفحات
  final List<Widget> _pages = [
    // const HomePage(),
    const ArticlesPage(),
    // const MusicSheetsPage(),
    const MusicPlayerPage(),
    const MetronomePage(),
    const TunerPage(),
    // const ProfilePage(),
    const VoiceRecorderPage(),
  ];

  @override
  Widget build(BuildContext context) {
    final appData = Provider.of<AppData>(context);
    final isDark = appData.isDark;

    return Scaffold(
      body: IndexedStack(
        // نمایش صفحه فعلی بدون از دست دادن state
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: isDark ? Colors.grey[900] : Colors.white,
        selectedItemColor: isDark ? Colors.yellow[700] : Colors.blue,
        unselectedItemColor: Colors.grey,
        currentIndex: _currentIndex, // هایلایت آیتم فعلی
        onTap: (index) {
          setState(() {
            _currentIndex = index; // تغییر ایندکس و صفحه
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          // BottomNavigationBarItem(
          //   icon: Icon(Icons.music_note),
          //   label: 'Music Sheet',
          // ),
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
          // BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
