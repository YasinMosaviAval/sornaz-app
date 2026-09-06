import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:sornaz/classes/my_app.dart';
import 'package:sornaz/helpers/app_data.dart';
import 'package:provider/provider.dart';
import 'package:sornaz/helpers/app_locale_provider.dart';
import 'package:sornaz/screens/Articles/provider/articles_provider.dart';
import 'package:sornaz/screens/Authentication/providers/auth_session.dart';
import 'package:sornaz/screens/Players/cache/audio_cache_factory.dart';
import 'package:sornaz/screens/Players/library/audio_library_manager.dart';
import 'package:sornaz/screens/Players/providers/audio_player_provider.dart';
import 'package:sornaz/screens/Players/providers/folder_navigator_provider.dart';
import 'package:sornaz/screens/Players/scan/audio_file_hive.dart';
import 'package:sornaz/screens/Tuner/controller/tuner_provider.dart';
import 'package:sornaz/screens/Voice%20Recorder/provider/voice_recorder_provider.dart';
import 'package:sornaz/screens/Voice%20Recorder/services/file_service.dart';
import 'package:sornaz/screens/Voice%20Recorder/services/playback_service.dart';
import 'package:sornaz/screens/Voice%20Recorder/services/recording_service.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  Hive.registerAdapter(AudioFileHiveAdapter());

  final cache = await AudioCacheFactory.getCache();
  final cachedFiles = await cache.loadCachedFiles();
  final libraryManager = AudioLibraryManager();

  if (cachedFiles.isNotEmpty) libraryManager.allFiles = cachedFiles;

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppData()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
        ChangeNotifierProvider(create: (_) => TunerProvider()..start()),
        ChangeNotifierProxyProvider<LocaleProvider, ArticlesProvider>(
          create: (_) => ArticlesProvider(),
          update: (_, locale, library) =>
              library!..setLocale(locale.locale.languageCode),
        ),
        ChangeNotifierProvider(create: (_) => AuthSession()..restore()),
        ChangeNotifierProvider(create: (_) => FolderNavigatorProvider()),
        ChangeNotifierProvider(create: (_) => libraryManager),
        ChangeNotifierProvider(
          create: (_) => AudioPlayerProvider(libraryManager: libraryManager),
        ),
        ChangeNotifierProvider(
          create: (_) => VoiceRecorderProvider(
            FileService(),
            RecordingService(),
            PlaybackService(),
          )..init(),
        ),
      ],
      child: const MyApp(),
    ),
  );
}
