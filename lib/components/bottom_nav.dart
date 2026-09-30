import 'main_tabs.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sornaz/helpers/app_data.dart';
import 'package:sornaz/screens/Home/ui/pages/home.dart';
import 'package:sornaz/screens/Social/my_profile_page.dart';
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
    final inactive = data.isDark ? Colors.white60 : Colors.black54;
    final background = data.isDark
        ? const Color(0xff202020)
        : const Color(0xfff1f1f1);
    const items = [
      (Icons.home_outlined, Icons.home, 'خانه', 'Home'),
      (Icons.dashboard_outlined, Icons.dashboard, 'پنل کاربری', 'User panel'),
      (Icons.dynamic_feed_outlined, Icons.dynamic_feed, 'صحنه', 'Stage'),
      (Icons.tune, Icons.tune, 'ابزار موسیقی', 'Music tools'),
      (Icons.person_outline, Icons.person, 'پروفایل', 'Profile'),
    ];
    void select(int index) {
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
            SitePanelPage(),
            UserPanelPage(),
            MusicToolsPage(),
            MyProfilePage(),
          ][index],
        ),
      );
    }

    return Directionality(
      textDirection: TextDirection.ltr,
      child: ColoredBox(
        color: background,
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 48,
            child: Row(
              children: [
                for (var index = 0; index < items.length; index++)
                  Expanded(
                    child: InkWell(
                      onTap: () => select(index),
                      child: Semantics(
                        selected: index == current,
                        button: true,
                        label: socialText(
                          context,
                          items[index].$3,
                          items[index].$4,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              index == current
                                  ? items[index].$2
                                  : items[index].$1,
                              color: index == current ? data.accent : inactive,
                              size: 21,
                            ),
                            const SizedBox(height: 1),
                            Text(
                              socialText(
                                context,
                                items[index].$3,
                                items[index].$4,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 10,
                                height: 1.1,
                                color: index == current
                                    ? data.accent
                                    : inactive,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
