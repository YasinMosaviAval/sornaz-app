import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:sornaz/audio/library/audio_library_manager.dart';
import 'package:sornaz/classes/my_app.dart';
import 'package:sornaz/helpers/app_data.dart';
import 'package:provider/provider.dart';
import 'package:sornaz/helpers/app_locale_provider.dart';
import 'package:sornaz/audio/audio_player_provider.dart';
import 'package:sornaz/audio/folder_navigator_provider.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();

  final libraryManager = AudioLibraryManager();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppData()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
        ChangeNotifierProvider(create: (_) => libraryManager),
        ChangeNotifierProvider(
          create: (_) => AudioPlayerProvider(libraryManager: libraryManager),
        ),
        ChangeNotifierProvider(create: (_) => FolderNavigatorProvider()),
      ],
      child: const MyApp(),
    ),
  );
}
