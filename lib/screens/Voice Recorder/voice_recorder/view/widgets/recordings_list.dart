import 'dart:io';
import 'package:flutter/material.dart';
import 'record_item_tile.dart';

class RecordingsList extends StatelessWidget {
  final List<File> files;
  final void Function(File) onPlay;
  final void Function(File) onDelete;

  const RecordingsList({
    super.key,
    required this.files,
    required this.onPlay,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (files.isEmpty) {
      return const Center(child: Text('No recordings'));
    }

    return ListView.builder(
      itemCount: files.length,
      itemBuilder: (_, i) {
        final file = files[i];
        return RecordItemTile(
          file: file,
          onPlay: () => onPlay(file),
          onDelete: () => onDelete(file),
        );
      },
    );
  }
}
