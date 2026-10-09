import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sornaz/screens/Social/social_widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sornaz/helpers/app_appearance.dart';

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

  Future<int?> chooseOption(String title, List<(int, String)> options) =>
      showDialog<int>(
        context: context,
        builder: (dialog) => SimpleDialog(
          shape: RoundedRectangleBorder(borderRadius: appRadius(dialog)),
          title: Text(title, style: Theme.of(dialog).textTheme.bodyMedium),
          children: [
            for (final option in options)
              SimpleDialogOption(
                onPressed: () => Navigator.pop(dialog, option.$1),
                child: Text(
                  option.$2,
                  style: Theme.of(dialog).textTheme.bodyMedium,
                ),
              ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) => SocialScaffold(
    title: socialText(context, 'تنظیمات نت‌نویسی', 'Notation settings'),
    body: ListView(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      children: [
        ListTile(
          title: Text(
            socialText(context, 'حالت انتخاب کشش نت', 'Note duration mode'),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          trailing: Text(
            socialText(
              context,
              switch (durationMode) {
                2 => 'حالت دوم',
                3 => 'حالت سوم',
                _ => 'حالت اول',
              },
              switch (durationMode) {
                2 => 'Mode two',
                3 => 'Mode three',
                _ => 'Mode one',
              },
            ),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          onTap: () async => setDurationMode(
            await chooseOption(
              socialText(context, 'حالت انتخاب کشش نت', 'Note duration mode'),
              [
                (1, socialText(context, 'حالت اول', 'Mode one')),
                (2, socialText(context, 'حالت دوم', 'Mode two')),
                (3, socialText(context, 'حالت سوم', 'Mode three')),
              ],
            ),
          ),
        ),
        ListTile(
          title: Text(
            socialText(
              context,
              'نمایش نت‌ها روی کلیدهای پیانو',
              'Piano key note labels',
            ),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          trailing: Text(
            pianoLabelMode == 2
                ? socialText(context, 'نت‌های گام', 'Scale notes only')
                : socialText(context, 'تمام نت‌ها', 'All notes'),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          onTap: () async => setPianoLabelMode(
            await chooseOption(
              socialText(
                context,
                'نمایش نت‌ها روی کلیدهای پیانو',
                'Piano key note labels',
              ),
              [
                (1, socialText(context, 'تمام نت‌ها', 'All notes')),
                (2, socialText(context, 'نت‌های گام', 'Scale notes only')),
              ],
            ),
          ),
        ),
        ListTile(
          title: Text(
            socialText(context, 'محل ذخیره‌سازی', 'Storage location'),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          subtitle: Text(
            Uri.decodeFull(location),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          trailing: const Icon(Icons.folder_open),
          onTap: busy ? null : choose,
        ),
      ],
    ),
  );
}
