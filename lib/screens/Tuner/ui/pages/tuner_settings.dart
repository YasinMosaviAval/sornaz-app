import 'package:sornaz/helpers/app_appearance.dart';
import 'package:sornaz/components/scroll_aware_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sornaz/components/app_bar.dart';
import 'package:sornaz/components/settings_section_header.dart';
import 'package:sornaz/components/settings_switch_tile.dart';
import 'package:sornaz/helpers/app_colors.dart';
import 'package:sornaz/helpers/app_constants.dart';
import 'package:sornaz/helpers/app_data.dart';
import 'package:sornaz/helpers/app_locale_provider.dart';
import 'package:sornaz/helpers/app_spacing.dart';
import 'package:sornaz/helpers/app_strings.dart';
import 'package:sornaz/helpers/app_translations.dart';
import 'package:sornaz/screens/Metronome/ui/components/labeled_slider.dart';
import 'package:sornaz/screens/Tuner/controller/tuner_provider.dart';

class TunerSettingsPage extends StatelessWidget {
  const TunerSettingsPage({super.key});

  Future<void> _sampleRate(BuildContext context, TunerProvider tuner) async {
    final current = tuner.sampleRate;
    const baseRate = TunerProvider.defaultSampleRate;
    final values = <int>[
      baseRate ~/ 2,
      baseRate,
      (baseRate * 1.5).round(),
      baseRate * 2,
    ];
    final selected = await showDialog<int>(
      context: context,
      builder: (c) => SimpleDialog(
        shape: RoundedRectangleBorder(borderRadius: appRadius(context)),
        title: Text(
          Localizations.localeOf(c).languageCode == 'fa'
              ? 'نرخ نمونه‌برداری تیونر'
              : 'Tuner sample rate',
          style: const TextStyle(fontSize: 14),
        ),
        children: [
          for (final value in values)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(c, value),
              child: Row(
                children: [
                  Expanded(child: Text('$value Hz')),
                  if (value == current)
                    Icon(
                      Icons.check,
                      size: 18,
                      color: Theme.of(c).colorScheme.primary,
                    ),
                ],
              ),
            ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(c, -1),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    Localizations.localeOf(c).languageCode == 'fa'
                        ? 'مقدار دلخواه'
                        : 'Custom value',
                  ),
                ),
                if (!values.contains(current))
                  Icon(
                    Icons.check,
                    size: 18,
                    color: Theme.of(c).colorScheme.primary,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
    if (selected == null || !context.mounted) return;
    var value = selected;
    if (selected == -1) {
      final controller = TextEditingController(text: '$current');
      value =
          await showDialog<int>(
            context: context,
            builder: (c) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: appRadius(context)),
              title: Text(
                Localizations.localeOf(c).languageCode == 'fa'
                    ? 'نرخ نمونه‌برداری دلخواه'
                    : 'Custom sample rate',
                style: const TextStyle(fontSize: 14),
              ),
              content: TextField(
                controller: controller,
                autofocus: true,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  suffixText: 'Hz',
                  helperText: '8000 – 192000',
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(c),
                  child: Text(
                    Localizations.localeOf(c).languageCode == 'fa'
                        ? 'انصراف'
                        : 'Cancel',
                  ),
                ),
                FilledButton(
                  onPressed: () {
                    final parsed = int.tryParse(controller.text.trim());
                    if (parsed != null && parsed >= 8000 && parsed <= 192000) {
                      Navigator.pop(c, parsed);
                    }
                  },
                  child: Text(
                    Localizations.localeOf(c).languageCode == 'fa'
                        ? 'ذخیره'
                        : 'Save',
                  ),
                ),
              ],
            ),
          ) ??
          current;
      controller.dispose();
    }
    await tuner.setSampleRate(value);
  }

  Future<void> _graphFillDuration(
    BuildContext context,
    TunerProvider tuner,
  ) async {
    final isPersian = Localizations.localeOf(context).languageCode == 'fa';
    final current = tuner.graphFillDuration;
    const values = <double>[1, 2, 3, 4, 5];
    final selected = await showDialog<double>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        shape: RoundedRectangleBorder(borderRadius: appRadius(context)),
        title: Text(
          isPersian ? 'زمان پر شدن نمودار فرکانس' : 'Frequency graph fill time',
          style: const TextStyle(fontSize: 14),
        ),
        children: [
          for (final value in values)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(dialogContext, value),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${value.toStringAsFixed(0)} ${isPersian ? 'ثانیه' : 'seconds'}',
                    ),
                  ),
                  if ((value - current).abs() < 0.001)
                    Icon(
                      Icons.check,
                      size: 18,
                      color: Theme.of(dialogContext).colorScheme.primary,
                    ),
                ],
              ),
            ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(dialogContext, -1.0),
            child: Row(
              children: [
                Expanded(
                  child: Text(isPersian ? 'مقدار دلخواه' : 'Custom value'),
                ),
                if (!values.any((value) => (value - current).abs() < 0.001))
                  Icon(
                    Icons.check,
                    size: 18,
                    color: Theme.of(dialogContext).colorScheme.primary,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
    if (selected == null || !context.mounted) return;
    var value = selected;
    if (selected == -1) {
      final controller = TextEditingController(
        text: current.toStringAsFixed(2),
      );
      value =
          await showDialog<double>(
            context: context,
            builder: (dialogContext) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: appRadius(context)),
              title: Text(
                isPersian ? 'زمان دلخواه' : 'Custom fill time',
                style: const TextStyle(fontSize: 14),
              ),
              content: TextField(
                controller: controller,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  suffixText: isPersian ? 'ثانیه' : 'seconds',
                  helperText: '0.10 – 30.00',
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text(isPersian ? 'انصراف' : 'Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    final parsed = double.tryParse(
                      controller.text.trim().replaceAll(',', '.'),
                    );
                    if (parsed != null && parsed >= 0.1 && parsed <= 30) {
                      Navigator.pop(dialogContext, parsed);
                    }
                  },
                  child: Text(isPersian ? 'ذخیره' : 'Save'),
                ),
              ],
            ),
          ) ??
          current;
      controller.dispose();
    }
    await tuner.setGraphFillDuration(value);
  }

  @override
  Widget build(BuildContext context) {
    final tuner = context.watch<TunerProvider>();
    final appData = context.watch<AppData>();
    final isDark = appData.isDark;

    final localeProvider = Provider.of<LocaleProvider>(context, listen: false);
    final isEnglish =
        localeProvider.locale.languageCode == AppConstants.LOCALIZATION_EN;

    return Directionality(
      textDirection: isEnglish ? TextDirection.ltr : TextDirection.rtl,
      child: ScrollAwareScaffold(
        appBar: SornazAppBar(
          title: AppStrings.tuner_settings_title.translate(context),
        ),
        backgroundColor: AppColors.tuner_settings_background_color(
          isDark: isDark,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.space_16,
            ),
            child: Column(
              children: [
                SettingsSectionHeader(
                  title: AppStrings.volumes.translate(context),
                  leadingIcon: Icons.volume_up,
                  children: [
                    LabeledSlider(
                      leadingIcon: Icon(
                        Icons.access_alarm,
                        color: AppColors.tuner_settings_icon_color(
                          isDark: isDark,
                        ),
                        size: AppSpacing.space_20,
                      ),
                      // label: "Note duration (seconds)",
                      // unit: AppStrings.second.translate(context),
                      label:
                          "${AppStrings.note_stretch.translate(context)} : ${tuner.noteDurationSeconds} ${AppStrings.second.translate(context)}",
                      value: tuner.noteDurationSeconds.toDouble(),
                      min: 1,
                      max: 60,
                      divisions: 59,
                      isDark: isDark,
                      onChanged: (value) {
                        tuner.setNoteDuration(value.toInt());
                      },
                    ),
                    LabeledSlider(
                      leadingIcon: Icon(
                        Icons.tune,
                        color: AppColors.tuner_settings_icon_color(
                          isDark: isDark,
                        ),
                        size: AppSpacing.space_20,
                      ),
                      label:
                          "${AppStrings.set_base_frequency.translate(context)}${tuner.a4.toStringAsFixed(0)} ${AppStrings.hz.translate(context)}",
                      value: tuner.a4,
                      min: 420,
                      max: 460,
                      divisions: 40,
                      isDark: isDark,
                      onChanged: tuner.setA4,
                    ),
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                      ),
                      leading: Icon(
                        Icons.graphic_eq,
                        color: AppColors.tuner_settings_icon_color(
                          isDark: isDark,
                        ),
                        size: AppSpacing.space_20,
                      ),
                      title: Text(
                        isEnglish
                            ? 'Tuner sample rate'
                            : 'نرخ نمونه‌برداری تیونر',
                      ),
                      trailing: Text('${tuner.sampleRate} Hz'),
                      onTap: () => _sampleRate(context, tuner),
                    ),
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                      ),
                      leading: Icon(
                        Icons.timeline,
                        color: AppColors.tuner_settings_icon_color(
                          isDark: isDark,
                        ),
                        size: AppSpacing.space_20,
                      ),
                      title: Text(
                        isEnglish
                            ? 'Frequency graph fill time'
                            : 'زمان پر شدن نمودار فرکانس',
                      ),
                      trailing: Text(
                        '${tuner.graphFillDuration.toStringAsFixed(2)} ${isEnglish ? 's' : 'ثانیه'}',
                      ),
                      onTap: () => _graphFillDuration(context, tuner),
                    ),
                    LabeledSlider(
                      leadingIcon: Icon(
                        Icons.line_weight,
                        color: AppColors.tuner_settings_icon_color(
                          isDark: isDark,
                        ),
                        size: AppSpacing.space_20,
                      ),
                      label: isEnglish
                          ? 'Tuner line thickness: ${tuner.lineThickness.toStringAsFixed(1)}'
                          : 'ضخامت خط تیونر: ${tuner.lineThickness.toStringAsFixed(1)}',
                      value: tuner.lineThickness,
                      min: 1,
                      max: 3,
                      divisions: 20,
                      isDark: isDark,
                      onChanged: tuner.setLineThickness,
                    ),
                  ],
                ),
                SettingsSectionHeader(
                  title: AppStrings.tools.translate(context),
                  leadingIcon: Icons.construction_outlined,
                  children: [
                    LabeledSlider(
                      leadingIcon: Icon(
                        Icons.flag_outlined,
                        color: AppColors.tuner_settings_icon_color(
                          isDark: isDark,
                        ),
                        size: AppSpacing.space_20,
                      ),
                      label:
                          "${AppStrings.starting_octave.translate(context)}: ${tuner.keyboardSettings.startOctave}",
                      value: tuner.keyboardSettings.startOctave.toDouble(),
                      min: 1,
                      max: 6,
                      divisions: 5,
                      isDark: isDark,
                      onChanged: (value) => tuner.setStartOctave(value.toInt()),
                    ),
                    LabeledSlider(
                      leadingIcon: Icon(
                        Icons.arrow_forward_outlined,
                        color: AppColors.tuner_settings_icon_color(
                          isDark: isDark,
                        ),
                        size: AppSpacing.space_20,
                      ),
                      label:
                          "${AppStrings.number_of_octaves.translate(context)}: ${tuner.keyboardSettings.octaveCount}",
                      value: tuner.keyboardSettings.octaveCount.toDouble(),
                      min: 1,
                      max: 6,
                      divisions: 5,
                      isDark: isDark,
                      onChanged: (value) => tuner.setOctaveCount(value.toInt()),
                    ),
                    SettingsSwitchTile(
                      title: AppStrings.highlight_a4_key.translate(context),
                      subtitle: AppStrings.enable_a4_key_highlight.translate(
                        context,
                      ),
                      value: tuner.keyboardSettings.highlightA4,
                      isDark: isDark,
                      onChanged: tuner.setHighlightA4,
                    ),
                    SettingsSwitchTile(
                      title: AppStrings.frequencies_on_white_keys.translate(
                        context,
                      ),
                      subtitle: AppStrings
                          .enable_frequency_display_on_white_keys
                          .translate(context),
                      value: tuner.keyboardSettings.showWhiteKeyFrequencies,
                      isDark: isDark,
                      onChanged: (value) =>
                          tuner.setShowWhiteKeyFrequencies(value),
                    ),
                    SettingsSwitchTile(
                      title: AppStrings.frequencies_on_black_keys.translate(
                        context,
                      ),
                      subtitle: AppStrings
                          .enable_frequency_display_on_black_keys
                          .translate(context),
                      value: tuner.keyboardSettings.showBlackKeyFrequencies,
                      isDark: isDark,
                      onChanged: (value) =>
                          tuner.setShowBlackKeyFrequencies(value),
                    ),
                    SettingsSwitchTile(
                      title: AppStrings.quarter_tones.translate(context),
                      subtitle: AppStrings.enable_iranian_quarter_tones
                          .translate(context),
                      value: tuner.keyboardSettings.showQuarterTones,
                      isDark: isDark,
                      onChanged: (_) => tuner.toggleQuarterTones(),
                    ),
                  ],
                ),

                AppSpacing.sizedBoxH16(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
