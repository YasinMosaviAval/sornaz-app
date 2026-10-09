import 'package:flutter/material.dart';
import 'package:sornaz/screens/Social/social_widgets.dart';
import 'package:provider/provider.dart';
import '../../providers/audio_player_provider.dart';
import '../../scan/audio_file.dart';
import 'audio_item.dart';
import 'audio_selection.dart';

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
  final expanded = <String>{};
  @override
  void dispose() {
    if (widget.scrollController == null) controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = this.controller;
    final player = context.watch<AudioPlayerProvider>();
    final settings = player.settings;
    final visible = player.allFiles
        .where((f) => !settings.isHidden(f.file.path))
        .toList();
    int compare(AudioFile a, AudioFile b) => settings.musicSort == 'duration'
        ? a.duration.compareTo(b.duration)
        : settings.musicSort == 'added'
        ? a.addedAt.compareTo(b.addedAt)
        : a.fileName.toLowerCase().compareTo(b.fileName.toLowerCase());
    visible.sort(
      (a, b) => settings.musicSortAscending ? compare(a, b) : compare(b, a),
    );
    final path = player.currentAudio?.file.path;
    final changedTrack = path != lastPlaying;
    if (widget.folders && changedTrack && player.currentAudio != null) {
      expanded.add(player.currentAudio!.file.parent.path);
    }
    final groups = <String, List<AudioFile>>{};
    for (final file in visible) {
      groups.putIfAbsent(file.file.parent.path, () => []).add(file);
    }
    final folderNames = groups.keys.toList()..sort();
    if (settings.musicSort == 'count')
      folderNames.sort(
        (a, b) => groups[a]!.length.compareTo(groups[b]!.length),
      );
    if (settings.musicSort == 'duration')
      folderNames.sort(
        (a, b) => groups[a]!
            .fold<int>(0, (n, f) => n + f.duration.inMilliseconds)
            .compareTo(
              groups[b]!.fold<int>(0, (n, f) => n + f.duration.inMilliseconds),
            ),
      );
    if (settings.musicSort == 'added')
      folderNames.sort((a, b) {
        final aLatest = groups[a]!
            .map((f) => f.addedAt)
            .reduce((x, y) => x.isAfter(y) ? x : y);
        final bLatest = groups[b]!
            .map((f) => f.addedAt)
            .reduce((x, y) => x.isAfter(y) ? x : y);
        return aLatest.compareTo(bLatest);
      });
    if (!settings.musicSortAscending) {
      folderNames.setAll(0, folderNames.reversed.toList());
    }
    final files = visible
        .where((f) => f.fileName.toLowerCase().contains(player.searchQuery))
        .toList();
    final rows = <Object>[];
    if (widget.folders) {
      for (final folder in folderNames) {
        final matches = groups[folder]!
            .where((f) => f.fileName.toLowerCase().contains(player.searchQuery))
            .toList();
        if (matches.isEmpty &&
            !folder.toLowerCase().contains(player.searchQuery))
          continue;
        rows.add(folder);
        if (expanded.contains(folder)) rows.addAll(matches);
      }
    } else {
      rows.addAll(files);
    }
    if (path != lastPlaying) {
      lastPlaying = path;
      final at = rows.indexWhere((f) => f is AudioFile && f.file.path == path);
      if (at >= 0)
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || !controller.hasClients) return;
          final target =
              (at * 64 - (controller.position.viewportDimension - 64) / 2)
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
            itemCount: rows.length,
            itemBuilder: (context, i) {
              final row = rows[i];
              if (row is String) {
                return AudioRow(
                  title: row.split(RegExp(r'[/\\]')).last,
                  location: row,
                  duration: Duration.zero,
                  count: groups[row]!.length,
                  leadingIcon: expanded.contains(row)
                      ? Icons.folder
                      : Icons.folder_outlined,
                  isPlaying: expanded.contains(row),
                  onTap: () => setState(() {
                    if (!expanded.remove(row)) expanded.add(row);
                  }),
                  trailing: PopupMenuButton<String>(
                    onSelected: (_) => settings.setOption('hiddenPaths', [
                      ...settings.hiddenPaths,
                      row,
                    ]),
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        value: 'hide',
                        child: Text(
                          socialText(context, 'مخفی کردن پوشه', 'Hide folder'),
                        ),
                      ),
                    ],
                  ),
                );
              }
              final file = row as AudioFile;
              final queue = widget.folders
                  ? groups[file.file.parent.path]!
                  : files;
              final at = queue.indexOf(file);
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
                    player.playFromFolder(
                      queue,
                      at,
                      listKey: widget.folders ? file.file.parent.path : null,
                      lists: widget.folders
                          ? [
                              for (final name in folderNames)
                                MapEntry(name, groups[name]!),
                            ]
                          : null,
                    );
                  }
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
