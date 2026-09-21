import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sornaz/helpers/app_colors.dart';
import 'package:sornaz/helpers/app_data.dart';
import 'package:sornaz/screens/Players/providers/audio_player_provider.dart';
import 'package:sornaz/screens/Social/social_widgets.dart';
import '../../services/equalizer_settings.dart';
import '../../services/equalizer_presets.dart';

class EqualizerTab extends StatefulWidget {
  const EqualizerTab({super.key, this.settings});
  final EqualizerSettings? settings;
  @override
  State<EqualizerTab> createState() => _EqualizerTabState();
}

class _EqualizerTabState extends State<EqualizerTab> {
  late EqualizerSettings eq;
  @override
  void initState() {
    super.initState();
    eq = widget.settings ?? context.read<AudioPlayerProvider>().equalizer;
    eq.load();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: eq,
    builder: (context, _) {
      if (!eq.ready) return const Center(child: CircularProgressIndicator());
      final isDark = context.watch<AppData>().isDark;
      final color = Theme.of(context).colorScheme.primary;
      return ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(socialText(context, 'اکولایزر', 'Equalizer')),
              ),
              Switch(
                value: eq.enabled,
                onChanged: eq.setEnabled,
                inactiveThumbColor:
                    AppColors.settings_switch_tile_inactive_thumb_color(
                      isDark: isDark,
                    ),
                inactiveTrackColor:
                    AppColors.settings_switch_tile_inactive_track_color(
                      isDark: isDark,
                    ),
                activeTrackColor:
                    AppColors.settings_switch_tile_active_track_color(
                      isDark: isDark,
                    ),
                activeThumbColor:
                    AppColors.settings_switch_tile_active_thumb_color(
                      isDark: isDark,
                    ),
              ),
              IconButton(
                tooltip: socialText(context, 'بازنشانی', 'Reset'),
                onPressed: eq.reset,
                icon: const Icon(Icons.restart_alt),
              ),
            ],
          ),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final name in ['Custom', ...equalizerPresets.keys])
                ChoiceChip(
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  label: Text(name, style: const TextStyle(fontSize: 12)),
                  selected: eq.selected == name,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  side: BorderSide.none,
                  backgroundColor:
                      AppColors.article_list_unselected_box_decoration_color(
                        isDark: isDark,
                      ),
                  showCheckmark: false,
                  selectedColor: color,
                  labelStyle: TextStyle(
                    color: eq.selected == name
                        ? Theme.of(context).colorScheme.onPrimary
                        : null,
                  ),
                  onSelected: (_) => eq.select(name),
                ),
            ],
          ),
          const SizedBox(height: 16),
          DefaultTabController(
            length: 2,
            initialIndex: eq.bands == 5 ? 0 : 1,
            child: TabBar(
              onTap: (index) => eq.setBands(index == 0 ? 5 : 10),
              tabs: const [
                Tab(text: '5 Bands'),
                Tab(text: '10 Bands'),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Directionality(
            textDirection: TextDirection.ltr,
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: constraints.maxWidth < eq.bands * 80
                      ? eq.bands * 80.0
                      : constraints.maxWidth,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (var i = 0; i < eq.bands; i++)
                        Expanded(
                          child: Column(
                            children: [
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  '${eq.gains[i] >= 0 ? '+' : ''}${eq.gains[i].toStringAsFixed(1)}',
                                  style: TextStyle(color: color, fontSize: 14),
                                ),
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                height: 230,
                                child: RotatedBox(
                                  quarterTurns: 3,
                                  child: SliderTheme(
                                    data: SliderTheme.of(context).copyWith(
                                      showValueIndicator:
                                          ShowValueIndicator.never,
                                      trackHeight: 4,
                                      thumbShape: const RoundSliderThumbShape(
                                        enabledThumbRadius: 8,
                                      ),
                                      overlayShape:
                                          const RoundSliderOverlayShape(
                                            overlayRadius: 12,
                                          ),
                                    ),
                                    child: Slider(
                                      key: ValueKey('eq-band-$i'),
                                      min: -15,
                                      max: 15,
                                      divisions: 60,
                                      value: eq.gains[i],
                                      semanticFormatterCallback: (value) =>
                                          '${eq.frequencies[i]} Hz, $value dB',
                                      onChanged: eq.enabled
                                          ? (value) => eq.setGain(i, value)
                                          : null,
                                    ),
                                  ),
                                ),
                              ),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  eq.frequencies[i] >= 1000
                                      ? '${eq.frequencies[i] / 1000}kHz'
                                      : '${eq.frequencies[i].round()}Hz',
                                  style: const TextStyle(fontSize: 11),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (eq.error != null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(
                socialText(
                  context,
                  'اعمال اکولایزر انجام نشد. این قابلیت به اندروید ۹ یا بالاتر و پشتیبانی دستگاه نیاز دارد.',
                  'Could not apply equalizer. Android 9 or later and device support are required.',
                ),
              ),
            ),
          const SizedBox(height: 16),
        ],
      );
    },
  );
}
