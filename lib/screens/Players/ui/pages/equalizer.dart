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
      final color = eq.enabled
          ? Theme.of(context).colorScheme.primary
          : Colors.grey;
      return AbsorbPointer(
        absorbing: !eq.enabled,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          children: [
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
                    onSelected: eq.enabled ? (_) => eq.select(name) : null,
                  ),
              ],
            ),
            const SizedBox(height: 16),
            DefaultTabController(
              length: 2,
              initialIndex: eq.bands == 5 ? 0 : 1,
              child: TabBar(
                labelColor: color,
                unselectedLabelColor: eq.enabled ? null : Colors.grey,
                indicatorColor: color,
                onTap: (index) => eq.setBands(index == 0 ? 5 : 10),
                tabs: [
                  Tab(text: socialText(context, '5 فیلتر', '5 Bands')),
                  Tab(text: socialText(context, '10 فیلتر', '10 Bands')),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Directionality(
              textDirection: TextDirection.ltr,
              child: LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: eq.bands == 5
                      ? const NeverScrollableScrollPhysics()
                      : null,
                  child: SizedBox(
                    width: constraints.maxWidth * eq.bands / 5,
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
                                    style: TextStyle(
                                      color: color,
                                      fontSize: 14,
                                    ),
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
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: eq.enabled ? null : Colors.grey,
                                    ),
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
        ),
      );
    },
  );
}
