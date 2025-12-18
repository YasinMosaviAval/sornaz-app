import 'dart:io';
import 'package:flutter/material.dart';
import 'package:sornaz/screens/Profile/voice_recorder/utils/date_formatter.dart';

class RecordItemTile extends StatelessWidget {
  final File file;
  final VoidCallback onPlay;
  final VoidCallback onDelete;

  const RecordItemTile({
    super.key,
    required this.file,
    required this.onPlay,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final name = file.path.split('/').last.replaceAll('.m4a', '');
    final date = formatJalali(file.lastModifiedSync());

    return Card(
      child: ListTile(
        title: Text(name),
        subtitle: Text(date),
        leading: IconButton(
          icon: const Icon(Icons.play_arrow),
          onPressed: onPlay,
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete),
          onPressed: onDelete,
        ),
      ),
    );
  }
}
