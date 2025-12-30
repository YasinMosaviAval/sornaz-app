import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sornaz/helpers/app_strings.dart';
import 'package:sornaz/helpers/app_translations.dart';

import '../provider/voice_recorder_provider.dart';
import '../services/file_service.dart';
import '../services/recording_service.dart';
import 'widgets/recording_timer.dart';
import 'widgets/recorder_controls.dart';
import 'widgets/recordings_list.dart';
import 'widgets/delete_confirm_dialog.dart';

class VoiceRecorderPage extends StatelessWidget {
  const VoiceRecorderPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => VoiceRecorderProvider(
        FileService(),
        RecordingService(),
      )..init(),
      child: const _VoiceRecorderView(),
    );
  }
}

class _VoiceRecorderView extends StatefulWidget {
  const _VoiceRecorderView();

  @override
  State<_VoiceRecorderView> createState() => _VoiceRecorderViewState();
}

class _VoiceRecorderViewState extends State<_VoiceRecorderView> {
  @override
  Widget build(BuildContext context) {
    final vm = context.watch<VoiceRecorderProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.voice_recorder_title.translate(context)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          const SizedBox(height: 24),

          // ⏱ Timer
          RecordingTimer(text: vm.timer),

          const SizedBox(height: 24),

          // 🎙 Controls
          RecorderControls(
            isRecording: vm.isRecording,
            onRecord: vm.start,
            onStop: vm.stop,
          ),

          const SizedBox(height: 24),
          const Divider(),

          // 📂 Recordings list
          Expanded(
            child: RecordingsList(
              files: vm.files,
              onPlay: (File file) async {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Play: ${file.path.split('/').last}',
                    ),
                    duration: const Duration(seconds: 1),
                  ),
                );
              },
              onDelete: (File file) async {
                final name = file.path.split('/').last.replaceAll('.m4a', '');

                final confirm = await showDeleteConfirmDialog(context, name);
                if (confirm != true) return;

                await file.delete();
                await vm.init();

                if (!context.mounted) return;

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Recording "$name" deleted'),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
