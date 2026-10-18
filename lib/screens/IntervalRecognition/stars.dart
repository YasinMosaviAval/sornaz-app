import 'package:flutter/material.dart';
import 'progress.dart';
import 'text.dart';

class IntervalStars extends StatelessWidget {
  const IntervalStars({super.key, required this.count});
  final int count;
  @override
  Widget build(BuildContext context) {
    final t = IntervalText(context);
    final selected = count.clamp(0, IntervalProgress.maxStars);
    return Semantics(
      label: t('interval.stars', {
        'count': t.number(selected),
        'total': t.number(IntervalProgress.maxStars),
      }),
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < IntervalProgress.maxStars; i++)
              Icon(
                Icons.star,
                key: ValueKey('interval.star.$i.${i < selected}'),
                color: i < selected
                    ? Colors.amber
                    : Theme.of(context).disabledColor,
                size:
                    (Theme.of(context).textTheme.bodyLarge?.fontSize ?? 16) *
                    1.25,
              ),
          ],
        ),
      ),
    );
  }
}
