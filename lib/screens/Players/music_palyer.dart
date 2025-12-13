import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sornaz/components/audio_list.dart';
import 'package:sornaz/components/audio_player_search_bar.dart';
import 'package:sornaz/components/bottom_player.dart';
import 'package:sornaz/helpers/app_locale_provider.dart';
import 'package:sornaz/provider/audio_player_provider.dart';
import 'package:sornaz/components/bottom_nav.dart';
import 'package:sornaz/provider/folder_navigator_provider.dart';
import 'package:sornaz/services/audio_file_loader.dart';
/*
class MusicPlayerPage extends StatelessWidget {
  const MusicPlayerPage({super.key});

  @override
  Widget build(BuildContext context) {
    final localeProvider = Provider.of<LocaleProvider>(context, listen: false);
    final bool isEnglish = localeProvider.locale.languageCode == 'en';
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AudioPlayerProvider()),
        ChangeNotifierProvider(create: (_) => FolderNavigatorProvider()),
      ],
      child: Directionality(
        textDirection: isEnglish ? TextDirection.ltr : TextDirection.rtl,
        child: ChangeNotifierProvider(
          create: (_) => AudioPlayerProvider(),
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

      )
    );
  }
}
*/

class MusicPlayerPage extends StatefulWidget {
  const MusicPlayerPage({super.key});

  @override
  State<MusicPlayerPage> createState() => _MusicPlayerPageState();
}

class _MusicPlayerPageState extends State<MusicPlayerPage> {

  @override
  void initState() {
    super.initState();

    // صبر تا frame ساخته شود و providerها آماده باشند
    WidgetsBinding.instance.addPostFrameCallback((_) {
      pickAndLoad(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final localeProvider = Provider.of<LocaleProvider>(context, listen: false);
    final bool isEnglish = localeProvider.locale.languageCode == 'en';

    return Directionality(
      textDirection: isEnglish ? TextDirection.ltr : TextDirection.rtl,
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
    );
  }
}

// ================================================
// تابع انتخاب پوشه و بارگذاری فایل‌ها
// ================================================
void pickAndLoad(BuildContext context) async {
  final path = await AudioFileLoader.pickDirectory();
  if (path == null) return;

  final folderNav = Provider.of<FolderNavigatorProvider>(context, listen: false);
  final audioProvider = Provider.of<AudioPlayerProvider>(context, listen: false);

  final dir = Directory(path);

  // 1️⃣ ست کردن root پوشه در FolderNavigator
  await folderNav.setRoot(dir);

  // 2️⃣ بارگذاری فایل‌ها با مدت زمان واقعی
  final files = await AudioFileLoader.loadFromDirectory(dir);

  // 3️⃣ ست کردن لیست فایل‌ها در AudioPlayerProvider
  audioProvider.setFileList(files);
}
