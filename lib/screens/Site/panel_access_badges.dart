import 'package:flutter/material.dart';
import '../../helpers/app_appearance.dart';
import '../Social/social_api.dart';
import '../Social/social_widgets.dart';

class PanelAccessStatus extends StatelessWidget {
  const PanelAccessStatus({super.key, required this.status});
  final dynamic status;
  @override
  Widget build(BuildContext context) {
    const labels = {
      'pending': ('در انتظار', 'Pending'),
      'approved': ('تأییدشده', 'Approved'),
      'rejected': ('ردشده', 'Rejected'),
      'inactive': ('غیرفعال', 'Inactive'),
      'banned': ('مسدود', 'Banned'),
    };
    final label = labels[status];
    return Text(
      label == null
          ? '${status ?? '—'}'
          : socialText(context, label.$1, label.$2),
    );
  }
}

class PanelAccessBadges extends StatelessWidget {
  const PanelAccessBadges({super.key, required this.items, this.roles = false});
  final List<Json> items;
  final bool roles;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    if (items.isEmpty) return const Text('—');
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 240),
      child: Wrap(
        spacing: 4,
        runSpacing: 4,
        children: [
          for (final item in items.take(3))
            Builder(
              builder: (context) {
                final hex = '${item['color'] ?? ''}'.replaceFirst('#', '');
                final background =
                    roles && RegExp(r'^[0-9a-fA-F]{6}$').hasMatch(hex)
                    ? Color(0xff000000 | int.parse(hex, radix: 16))
                    : colors.primaryContainer;
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: background,
                    borderRadius: appRadius(context),
                  ),
                  child: Text(
                    '${item['title'] ?? item['name'] ?? ''}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: roles
                          ? (ThemeData.estimateBrightnessForColor(background) ==
                                    Brightness.dark
                                ? Colors.white
                                : Colors.black)
                          : colors.onPrimaryContainer,
                    ),
                  ),
                );
              },
            ),
          if (items.length > 3)
            Text(
              '+${items.length - 3}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
        ],
      ),
    );
  }
}
