import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sornaz/helpers/app_data.dart';
import 'package:sornaz/helpers/app_locale_provider.dart';
import 'package:sornaz/helpers/color_palette.dart';

class ColorPalettePicker extends StatelessWidget {
  const ColorPalettePicker({super.key});
  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppData>();
    final en = context.watch<LocaleProvider>().locale.languageCode == 'en';
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            en ? 'Color theme' : 'تم رنگی',
            style: const TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              for (final palette in ColorPalette.values)
                ChoiceChip(
                  showCheckmark: false,
                  avatar: CircleAvatar(
                    backgroundColor: app.isDark ? palette.dark : palette.light,
                    radius: 8,
                  ),
                  label: Text(
                    en ? palette.en : palette.fa,
                    style: const TextStyle(fontSize: 11),
                  ),
                  selected: app.palette == palette,
                  onSelected: (_) => app.setPalette(palette),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
