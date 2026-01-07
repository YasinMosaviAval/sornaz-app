import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:sornaz/screens/Players/audio/cache/audio_cache_factory.dart';
import 'package:sornaz/screens/Players/audio/library/audio_library_manager.dart';
import 'package:sornaz/screens/Players/audio/scan/audio_file_hive.dart';
import 'package:sornaz/classes/my_app.dart';
import 'package:sornaz/helpers/app_data.dart';
import 'package:provider/provider.dart';
import 'package:sornaz/helpers/app_locale_provider.dart';
import 'package:sornaz/screens/Players/audio/audio_player_provider.dart';
import 'package:sornaz/screens/Players/audio/folder_navigator_provider.dart';
import 'package:sornaz/screens/Articles/provider/articles_provider.dart';
import 'package:sornaz/screens/Tuner/controller/tuner_provider.dart';
import 'package:sornaz/screens/Voice%20Recorder/voice_recorder/provider/voice_recorder_provider.dart';
import 'package:sornaz/screens/Voice%20Recorder/voice_recorder/services/file_service.dart';
import 'package:sornaz/screens/Voice%20Recorder/voice_recorder/services/playback_service.dart';
import 'package:sornaz/screens/Voice%20Recorder/voice_recorder/services/recording_service.dart';

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
        ChangeNotifierProvider(create: (_) => ArticlesProvider()),
        ChangeNotifierProvider(create: (_) => FolderNavigatorProvider()),
        ChangeNotifierProvider(create: (_) => libraryManager),
        ChangeNotifierProvider(create: (_) => AudioPlayerProvider(libraryManager: libraryManager),),
        ChangeNotifierProvider(create: (_) => VoiceRecorderProvider(FileService(), RecordingService(), PlaybackService())..init()),
      ],
      child: const MyApp(),
    ),
  );
}