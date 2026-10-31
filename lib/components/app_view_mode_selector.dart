import 'package:flutter/material.dart';
import '../helpers/app_appearance.dart';

class AppViewMode<T> {
  const AppViewMode({
    required this.value,
    required this.label,
    required this.icon,
    this.key,
  });
  final T value;
  final String label;
  final IconData icon;
  final Key? key;
}

/// Shared compact selection buttons, also usable for table/week and card/list.
class AppViewModeSelector<T> extends StatelessWidget {
  const AppViewModeSelector({
    super.key,
    required this.value,
    required this.options,
    required this.onChanged,
  });
  final T value;
  final List<AppViewMode<T>> options;
  final ValueChanged<T>? onChanged;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final option in options)
          Semantics(
            selected: value == option.value,
            child: OutlinedButton.icon(
              key: option.key,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 40),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(borderRadius: appRadius(context)),
                backgroundColor: value == option.value
                    ? colors.primaryContainer
                    : colors.surface,
                foregroundColor: value == option.value
                    ? colors.onPrimaryContainer
                    : colors.onSurface,
                textStyle: Theme.of(context).textTheme.labelLarge,
              ),
              onPressed: onChanged == null
                  ? null
                  : () => onChanged!(option.value),
              icon: Icon(option.icon, size: 18),
              label: Text(option.label),
            ),
          ),
      ],
    );
  }
}
