import 'package:flutter/material.dart';
import 'app_async_state.dart';

class NoFilesFoundWidget extends StatelessWidget {
  const NoFilesFoundWidget({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return AppEmptyState(message: message, icon: Icons.folder_open_outlined);
  }
}
