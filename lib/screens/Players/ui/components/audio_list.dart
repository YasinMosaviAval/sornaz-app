import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sornaz/screens/Players/library/audio_library_manager.dart';
import 'package:sornaz/screens/Players/providers/audio_player_provider.dart';
import 'package:sornaz/screens/Players/providers/folder_navigator_provider.dart';
import 'package:sornaz/screens/Players/ui/components/flat_list_view.dart';
import 'package:sornaz/screens/Players/ui/components/folder_list_view.dart';

class AudioList extends StatelessWidget {
  const AudioList({super.key});

  @override
  Widget build(BuildContext context) {
    // final appData = Provider.of<AppData>(context);
    // final isDark = appData.isDark;

    return Consumer3<
      AudioPlayerProvider,
      FolderNavigatorProvider,
      AudioLibraryManager
    >(
      builder: (context, audio, folder, library, _) {
        if (library.isScanning)
          return Center(child: CircularProgressIndicator());
        if (audio.folderMode) {
          return const FolderView();
        }
        return const FlatListView();
      },
    );
  }
}
