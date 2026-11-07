import 'package:sornaz/components/settings_switch_tile.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../helpers/development_access.dart';
import '../IntervalRecognition/settings.dart';
import '../IntervalRecognition/settings_screen.dart';
import '../Social/social_widgets.dart';

class MusicPracticeSettingsPage extends StatefulWidget {
  const MusicPracticeSettingsPage({super.key});
  static const listModeKey = 'music.practice.admin.listMode';
  static const hierarchyModeKey = 'music.practice.admin.hierarchyMode';
  static Future<bool> hierarchyMode(int? actor) async =>
      actor != 1 ||
      ((await SharedPreferences.getInstance()).getBool(hierarchyModeKey) ??
          true);
  static Future<bool> listMode(int? actor) async =>
      actor == 1 &&
      (await SharedPreferences.getInstance()).getBool(listModeKey) == true;
  @override
  State<MusicPracticeSettingsPage> createState() =>
      _MusicPracticeSettingsPageState();
}

class _MusicPracticeSettingsPageState extends State<MusicPracticeSettingsPage> {
  final audio = IntervalAudioSettings();
  bool listMode = false, hierarchyMode = true, ready = false;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final value = await MusicPracticeSettingsPage.listMode(1);
    final hierarchy = await MusicPracticeSettingsPage.hierarchyMode(1);
    if (mounted) {
      setState(() {
        listMode = value;
        hierarchyMode = hierarchy;
        ready = true;
      });
    }
  }

  Future<void> _changeHierarchy(bool value) async {
    if (!DevelopmentAccess.read(context)) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!await prefs.setBool(
        MusicPracticeSettingsPage.hierarchyModeKey,
        value,
      )) {
        throw StateError('Settings not saved');
      }
      if (mounted) setState(() => hierarchyMode = value);
    } catch (e) {
      if (mounted) socialError(context, e);
    }
  }

  Future<void> _change(bool value) async {
    if (!DevelopmentAccess.read(context)) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!await prefs.setBool(MusicPracticeSettingsPage.listModeKey, value)) {
        throw StateError('Settings not saved');
      }
      if (mounted) setState(() => listMode = value);
    } catch (e) {
      if (mounted) socialError(context, e);
    }
  }

  @override
  void dispose() {
    audio.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IntervalSettingsScreen(
    settings: audio,
    additionalSettings: [
      if (DevelopmentAccess.watch(context))
        SettingsSwitchTile.widgets(
          contentPadding: EdgeInsets.zero,
          title: Text(
            socialText(
              context,
              'نمایش آبشاری آزمون‌ها در یک صفحه',
              'Show tests as a tree on one page',
            ),
          ),
          subtitle: Text(
            socialText(
              context,
              'خاموش: نمایش صفحه‌به‌صفحهٔ سطح‌ها',
              'Off: browse sections on separate pages',
            ),
          ),
          value: hierarchyMode,
          onChanged: ready ? _changeHierarchy : null,
        ),
      if (DevelopmentAccess.watch(context))
        SettingsSwitchTile.widgets(
          contentPadding: EdgeInsets.zero,
          title: Text(
            socialText(
              context,
              'نمایش فهرست سطح‌های آزمون',
              'Show test level list',
            ),
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontSize: 12),
          ),
          subtitle: Text(
            socialText(
              context,
              'خاموش: ورود مستقیم و ادامهٔ خودکار سطح‌ها',
              'Off: start directly and continue levels automatically',
            ),
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontSize: 12),
          ),
          value: listMode,
          onChanged: ready ? _change : null,
        ),
    ],
  );
}
