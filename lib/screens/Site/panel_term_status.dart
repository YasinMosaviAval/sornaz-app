import 'package:flutter/material.dart';
import '../../helpers/app_appearance.dart';
import '../Social/social_api.dart';
import '../Social/social_widgets.dart';

Future<String?> selectPanelTermStatus(
  BuildContext context,
  String current,
  Json options,
) {
  const english = {
    'pending': 'Pending approval',
    'open': 'Open',
    'ongoing': 'Ongoing',
    'finished': 'Finished',
    'canceled': 'Canceled',
    'suspended': 'Suspended',
  };
  final terminal = ['finished', 'canceled'].contains(current);
  return showDialog<String>(
    context: context,
    builder: (dialog) => SimpleDialog(
      shape: RoundedRectangleBorder(borderRadius: appRadius(dialog)),
      title: Text(socialText(dialog, 'تعیین وضعیت ترم', 'Select term status')),
      children: [
        if (terminal)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              socialText(
                dialog,
                'وضعیت این ترم نهایی است.',
                'This term has a final status.',
              ),
            ),
          ),
        for (final entry in options.entries)
          if (!terminal || entry.key == current)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(dialog, entry.key),
              child: Row(
                children: [
                  Icon(
                    entry.key == current
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    color: Theme.of(dialog).colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      socialText(
                        dialog,
                        '${entry.value}',
                        english[entry.key] ?? '${entry.value}',
                      ),
                    ),
                  ),
                ],
              ),
            ),
      ],
    ),
  );
}
