import 'package:flutter/material.dart';
import 'package:sornaz/classes/accordion.dart';
import 'package:sornaz/helpers/app_spacing.dart';
import 'package:sornaz/helpers/app_typography.dart';

class Accordion extends StatefulWidget {
  final List<AccordionItem> items;

  const Accordion({super.key, required this.items});

  @override
  State<Accordion> createState() => _AccordionState();
}

class _AccordionState extends State<Accordion>
    with SingleTickerProviderStateMixin {
  int? _expandedIndex;

  @override
  void initState() {
    super.initState();
    _expandedIndex = 0; // ← آیتم اول به صورت پیش‌فرض باز شود
  }

  void _onItemTapped(int index) {
    setState(() {
      // if (_expandedIndex == index) {
      //   _expandedIndex = null; // اگر دوباره کلیک شد، بسته شود
      // } else {
      //   _expandedIndex = index; // فقط آیتم جدید باز شود
      // }
      _expandedIndex = (_expandedIndex == index) ? null : index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(widget.items.length, (index) {
        final item = widget.items[index];
        final isExpanded = _expandedIndex == index;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () => _onItemTapped(index),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      item.title,
                      style: AppTypography.aboutUsTitle(context),
                    ),
                  ),
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    curve: Curves.easeOutCubic,
                    duration: const Duration(milliseconds: 500),
                    child: const Icon(Icons.keyboard_arrow_down),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.space_8),

            AnimatedSize(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: isExpanded
                  ? Padding(
                      padding: const EdgeInsets.only(
                        bottom: AppSpacing.space_12,
                      ),
                      child: Text(
                        item.description,
                        style: AppTypography.aboutUsBody(context),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),

            const SizedBox(height: AppSpacing.space_32),
          ],
        );
      }),
    );
  }
}
