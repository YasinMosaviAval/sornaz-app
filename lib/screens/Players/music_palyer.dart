import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sornaz/components/audio_list.dart';
import 'package:sornaz/components/audio_player_search_bar.dart';
import 'package:sornaz/components/bottom_player.dart';
import 'package:sornaz/helpers/app_locale_provider.dart';
import 'package:sornaz/provider/audio_player_provider.dart';
import 'package:sornaz/components/bottom_nav.dart';

class MusicPlayerPage extends StatelessWidget {
  const MusicPlayerPage({super.key});

  @override
  Widget build(BuildContext context) {
    // final appData = Provider.of<AppData>(context);
    // final isDark = appData.isDark;
    final localeProvider = Provider.of<LocaleProvider>(context, listen: false);
    final bool isEnglish = localeProvider.locale.languageCode == 'en';

    return Directionality(
      textDirection: isEnglish ? TextDirection.ltr : TextDirection.rtl,
      child: ChangeNotifierProvider(
        create: (_) => AudioPlayerProvider()..loadFiles(),
        child: Scaffold(
          appBar: SearchBarWidget(),
          body: Column(
            children: [
              Expanded(child: AudioList()),
              BottomPlayerWidget(),
            ],
          ),
          bottomNavigationBar: const BottomNavBarWidget(),
        ),
      ),
    );
  }
}
