import 'main_tabs.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sornaz/helpers/app_data.dart';
import 'package:sornaz/screens/Home/ui/pages/home.dart';
import 'package:sornaz/screens/Notation/music_sheets_page.dart';
import 'package:sornaz/screens/Home/ui/pages/music_tools.dart';
import 'package:sornaz/screens/Social/user_panel.dart';
import 'package:sornaz/screens/Site/site_panel_page.dart';
import 'package:sornaz/screens/Social/social_widgets.dart';

class BottomNavBarWidget extends StatelessWidget {
  const BottomNavBarWidget({super.key, this.selectedIndex});
  final int? selectedIndex;
  @override
  Widget build(BuildContext context) {
    final data = context.watch<AppData>();
    final current = selectedIndex ?? data.bottomNavIndex.clamp(0, 4);
    return Directionality(
      textDirection: TextDirection.ltr,
      child: BottomNavigationBar(
        currentIndex: current,
        type: BottomNavigationBarType.fixed,
        backgroundColor: data.isDark
            ? const Color(0xff202020)
            : const Color(0xfff1f1f1),
        selectedItemColor: data.accent,
        unselectedItemColor: data.isDark ? Colors.white60 : Colors.black54,
        selectedFontSize: 10,
        unselectedFontSize: 10,
        onTap: (index) {
          if (index == current) return;
          final tabs = MainTabsScope.maybeOf(context);
          if (tabs != null) {
            tabs.select(index);
            return;
          }
          data.setBottomNavIndex(index);
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const [
                HomePage(),
                MusicSheetsPage(),
                SitePanelPage(),
                MusicToolsPage(),
                UserPanelPage(),
              ][index],
            ),
          );
        },
        items: [
          for (final item in [
            (Icons.home_outlined, Icons.home, 'خانه', 'Home'),
            (
              Icons.music_note_outlined,
              Icons.music_note,
              'نت‌های موسیقی',
              'Music Sheet',
            ),
            (
              Icons.dashboard_outlined,
              Icons.dashboard,
              'پنل کاربری',
              'User panel',
            ),
            (Icons.tune, Icons.tune, 'ابزار موسیقی', 'Music tools'),
            (Icons.person_outline, Icons.person, 'پروفایل', 'Profile'),
          ])
            BottomNavigationBarItem(
              icon: Icon(item.$1),
              activeIcon: Icon(item.$1),
              label: socialText(context, item.$3, item.$4),
            ),
        ],
      ),
    );
  }
}
