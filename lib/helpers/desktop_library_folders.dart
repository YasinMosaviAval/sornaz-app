import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sornaz/screens/Social/social_widgets.dart';

import 'desktop_library_paths.dart';

class DesktopLibraryFolders extends StatefulWidget {
  const DesktopLibraryFolders({super.key, this.video = false});
  final bool video;
  @override
  State<DesktopLibraryFolders> createState() => _DesktopLibraryFoldersState();
}

class _DesktopLibraryFoldersState extends State<DesktopLibraryFolders> {
  List<String>? folders;
  bool busy = false;
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final value = await desktopLibraryFolders(widget.video);
    if (mounted) setState(() => folders = value);
  }

  Future<void> change([String? remove]) async {
    setState(() => busy = true);
    try {
      final next = List<String>.from(folders ?? []);
      if (remove != null) {
        next.remove(remove);
      } else {
        final selected = await FilePicker.platform.getDirectoryPath();
        if (selected == null) return;
        final resolved = await Directory(selected).resolveSymbolicLinks();
        if (!next.contains(resolved)) next.add(resolved);
      }
      if (!await (await SharedPreferences.getInstance()).setStringList(
        widget.video ? 'desktop.videoFolders' : 'desktop.audioFolders',
        next,
      )) {
        throw StateError('Could not save library folders');
      }
      if (mounted) setState(() => folders = next);
    } catch (error) {
      if (mounted) socialError(context, error);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => SocialScaffold(
    title: socialText(context, 'پوشه‌های کتابخانه', 'Library folders'),
    body: folders == null
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(12),
            children: [
              Text(
                socialText(
                  context,
                  'پوشه‌های انتخابی علاوه بر پوشهٔ پیش‌فرض ویندوز اسکن می‌شوند. حذف از این فهرست فایل‌های شما را حذف نمی‌کند.',
                  'Selected folders are scanned alongside the default Windows folder. Removing a folder here keeps its files.',
                ),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              for (final folder in folders!)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    folder,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  trailing: IconButton(
                    onPressed: busy ? null : () => change(folder),
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
                ),
              FilledButton(
                onPressed: busy ? null : change,
                child: Text(socialText(context, 'افزودن پوشه', 'Add folder')),
              ),
            ],
          ),
  );
}
