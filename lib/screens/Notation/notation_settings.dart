import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sornaz/screens/Social/social_widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotationSettingsPage extends StatefulWidget {
  const NotationSettingsPage({super.key});
  @override
  State<NotationSettingsPage> createState() => _NotationSettingsPageState();
}

class _NotationSettingsPageState extends State<NotationSettingsPage> {
  static const channel = MethodChannel('sornaz/notation_storage');
  String location = 'Sornaz/Music Sheets';
  bool busy = false;
  int durationMode = 1;
  int pianoLabelMode = 1;
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        durationMode = prefs.getInt('notation.durationMode') ?? 1;
        pianoLabelMode = prefs.getInt('notation.pianoLabelMode') ?? 1;
      });
    }
    try {
      final value = await channel.invokeMethod<String>('location');
      if (mounted) {
        setState(() {
          if (value != null) location = value;
        });
      }
    } catch (_) {}
  }

  Future<void> setPianoLabelMode(int? value) async {
    if (value == null) return;
    setState(() => pianoLabelMode = value);
    await (await SharedPreferences.getInstance()).setInt(
      'notation.pianoLabelMode',
      value,
    );
  }

  Future<void> setDurationMode(int? value) async {
    if (value == null) return;
    setState(() => durationMode = value);
    await (await SharedPreferences.getInstance()).setInt(
      'notation.durationMode',
      value,
    );
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
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(
            socialText(context, 'حالت انتخاب کشش نت', 'Note duration mode'),
          ),
          trailing: DropdownButton<int>(
            value: durationMode,
            onChanged: setDurationMode,
            items: [
              DropdownMenuItem(
                value: 1,
                child: Text(socialText(context, 'حالت اول', 'Mode one')),
              ),
              DropdownMenuItem(
                value: 2,
                child: Text(socialText(context, 'حالت دوم', 'Mode two')),
              ),
              DropdownMenuItem(
                value: 3,
                child: Text(socialText(context, 'حالت سوم', 'Mode three')),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(
            socialText(
              context,
              'نمایش نت‌ها روی کلیدهای پیانو',
              'Piano key note labels',
            ),
          ),
          trailing: DropdownButton<int>(
            value: pianoLabelMode,
            onChanged: setPianoLabelMode,
            items: [
              DropdownMenuItem(
                value: 1,
                child: Text(socialText(context, 'تمام نت‌ها', 'All notes')),
              ),
              DropdownMenuItem(
                value: 2,
                child: Text(
                  socialText(context, 'نت‌های گام', 'Scale notes only'),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
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
