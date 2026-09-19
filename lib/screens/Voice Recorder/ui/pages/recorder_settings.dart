import 'package:sornaz/components/scroll_aware_scaffold.dart';
import 'package:sornaz/components/app_top_bar_direction.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sornaz/components/settings_section_header.dart';
import '../../provider/voice_recorder_provider.dart';

class RecorderSettingsPage extends StatefulWidget {
  const RecorderSettingsPage({super.key});
  @override
  State<RecorderSettingsPage> createState() => _RecorderSettingsPageState();
}

class _RecorderSettingsPageState extends State<RecorderSettingsPage> {
  @override
  Widget build(BuildContext context) {
    final vm = context.read<VoiceRecorderProvider>();
    return ScrollAwareScaffold(
      appBar: AppTopBarDirection(
        child: AppBar(title: const Text('تنظیمات ضبط صدا')),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SettingsSectionHeader(
            title: 'ابزار',
            leadingIcon: Icons.tune,
            children: [
              FutureBuilder(
                future: vm.fileService.location(),
                builder: (_, snapshot) => ListTile(
                  title: const Text(
                    'پوشه ذخیره صداها',
                    style: TextStyle(fontSize: 13),
                  ),
                  subtitle: Text(
                    Uri.decodeFull('${snapshot.data ?? ''}'),
                    style: const TextStyle(fontSize: 11),
                  ),
                  trailing: const Icon(Icons.folder_open),
                  onTap: vm.isRecording || vm.isPaused
                      ? null
                      : () async {
                          try {
                            await vm.fileService.chooseLocation();
                            await vm.refreshFiles();
                            if (mounted) setState(() {});
                          } catch (_) {
                            if (context.mounted)
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'دسترسی به پوشه انتخاب‌شده ممکن نشد.',
                                  ),
                                ),
                              );
                          }
                        },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
