import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sornaz/screens/Social/social_widgets.dart';

class NotationSettingsPage extends StatefulWidget {
  const NotationSettingsPage({super.key});
  @override
  State<NotationSettingsPage> createState() => _NotationSettingsPageState();
}

class _NotationSettingsPageState extends State<NotationSettingsPage> {
  static const channel = MethodChannel('sornaz/notation_storage');
  String location = 'Sornaz/Music Sheets';
  bool busy = false;
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final value = await channel.invokeMethod<String>('location');
      if (mounted && value != null) setState(() => location = value);
    } catch (_) {}
  }

  Future<void> choose() async {
    setState(() => busy = true);
    try {
      final value = await channel.invokeMethod<String>('choose');
      if (value != null && mounted) {
        await load();
      }
    } catch (e) {
      if (mounted) socialError(context, e);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => SocialScaffold(
    title: socialText(context, 'تنظیمات نت‌نویسی', 'Notation settings'),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  socialText(context, 'محل ذخیره‌سازی', 'Storage location'),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                Text(location, textDirection: TextDirection.ltr),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: busy ? null : choose,
                  icon: const Icon(Icons.folder_open),
                  label: Text(
                    socialText(context, 'تغییر پوشه', 'Change folder'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
