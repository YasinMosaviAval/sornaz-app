import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sornaz/components/expanding_search_bar.dart';
import 'package:sornaz/components/settings_section_header.dart';
import '../../providers/audio_player_provider.dart';
import '../../providers/folder_navigator_provider.dart';
import 'breadcrumb.dart';

class SearchBarWidget extends StatelessWidget implements PreferredSizeWidget {
  const SearchBarWidget({super.key});
  @override
  Size get preferredSize => const Size.fromHeight(56);
  @override
  Widget build(BuildContext context) => ExpandingSearchBar(
    title: const BreadcrumbWidget(),
    onChanged: context.read<AudioPlayerProvider>().filter,
    onSettings: () => Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PlayerSettingsPage()),
    ),
  );
}

class PlayerSettingsPage extends StatelessWidget {
  const PlayerSettingsPage({super.key});
  @override
  Widget build(BuildContext context) {
    final folder = context.watch<FolderNavigatorProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('تنظیمات پخش موسیقی')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SettingsSectionHeader(
            title: 'ابزار',
            leadingIcon: Icons.tune,
            children: [
              SwitchListTile(
                title: const Text(
                  'فقط پوشه‌های دارای آهنگ',
                  style: TextStyle(fontSize: 13),
                ),
                value: folder.showOnlyFoldersWithAudio,
                onChanged: (_) => folder.toggleShowOnlyAudioFolders(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
