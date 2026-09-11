import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/audio_player_provider.dart';
import '../../providers/folder_navigator_provider.dart';
import 'audio_item.dart';
import 'audio_selection.dart';
import 'bottom_player.dart';
import 'search_bar.dart';

class FlatListView extends StatefulWidget {
  const FlatListView({super.key, this.scrollController, this.folders = false});
  final ScrollController? scrollController;
  final bool folders;
  @override
  State<FlatListView> createState() => _FlatListViewState();
}

class _FlatListViewState extends State<FlatListView> {
  late final controller = widget.scrollController ?? ScrollController();
  final selected = <String>{};
  String? lastPlaying;
  @override
  void dispose() {
    if (widget.scrollController == null) controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final player = context.watch<AudioPlayerProvider>();
    final nav = context.watch<FolderNavigatorProvider>();
    final knownFiles = {for (final f in player.allFiles) f.file.path: f};
    final files = widget.folders
        ? nav.audioFiles
              .where(
                (f) => f.fileName.toLowerCase().contains(player.searchQuery),
              )
              .map((f) => knownFiles[f.file.path] ?? f)
              .toList()
        : player.filteredFiles;
    final folders = widget.folders ? nav.subFolders : <dynamic>[];
    final path = player.currentAudio?.file.path;
    if (path != lastPlaying) {
      lastPlaying = path;
      final at = files.indexWhere((f) => f.file.path == path);
      if (at >= 0)
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || !controller.hasClients) return;
          final target =
              ((at + folders.length) * 64 -
                      (controller.position.viewportDimension - 64) / 2)
                  .clamp(0.0, controller.position.maxScrollExtent);
          controller.animateTo(
            target,
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeInOutCubic,
          );
        });
    }
    return Column(
      children: [
        const SearchBarWidget(),
        if (widget.folders && nav.isLoading) const LinearProgressIndicator(),
        if (widget.folders &&
            !nav.isLoading &&
            (nav.error != null || nav.rootDir == null))
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              nav.error ??
                  'پوشه‌ای در دسترس نیست. دسترسی به حافظه را بررسی کنید.',
            ),
          ),
        if (selected.isNotEmpty)
          Row(
            children: [
              IconButton(
                onPressed: () => setState(selected.clear),
                icon: const Icon(Icons.close),
              ),
              Text('${selected.length}'),
              const Spacer(),
              IconButton(
                onPressed: () => setState(
                  () => selected.addAll(files.map((f) => f.file.path)),
                ),
                icon: const Icon(Icons.select_all),
              ),
              AudioActionsMenu(
                files: files
                    .where((f) => selected.contains(f.file.path))
                    .toList(),
                after: () {
                  if (mounted) setState(selected.clear);
                },
              ),
            ],
          ),
        Expanded(
          child: ListView.builder(
            controller: controller,
            padding: EdgeInsets.zero,
            itemExtent: 64,
            itemCount: folders.length + files.length,
            itemBuilder: (context, i) {
              if (i < folders.length)
                return ListTile(
                  leading: const Icon(Icons.folder_outlined),
                  title: Text(folders[i].path.split('/').last),
                  onTap: () => nav.enterRealFolder(folders[i]),
                );
              final at = i - folders.length, file = files[at];
              return AudioItem(
                audio: file,
                index: at,
                isPlaying: player.currentAudio?.file.path == file.file.path,
                selected: selected.contains(file.file.path),
                onLongPress: () => setState(() => selected.add(file.file.path)),
                onTap: () {
                  if (selected.isNotEmpty) {
                    setState(
                      () => selected.contains(file.file.path)
                          ? selected.remove(file.file.path)
                          : selected.add(file.file.path),
                    );
                  } else if (player.currentAudio?.file.path == file.file.path) {
                    player.isPlaying ? player.pause() : player.resume();
                  } else {
                    player.playFromFolder(files, at);
                  }
                },
              );
            },
          ),
        ),
        const BottomPlayerWidget(),
      ],
    );
  }
}
