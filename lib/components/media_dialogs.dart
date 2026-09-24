import 'package:flutter/material.dart';
import '../screens/Social/social_widgets.dart';

Future<bool> confirmMediaDelete(BuildContext context, String title) async =>
    await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(title, style: const TextStyle(fontSize: 14)),
        actions: [
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.grey),
            onPressed: () => Navigator.pop(c, false),
            child: Text(socialText(c, 'انصراف', 'Cancel')),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.pop(c, true),
            child: Text(socialText(c, 'حذف', 'Delete')),
          ),
        ],
      ),
    ) ??
    false;

Future<String?> renameMediaDialog(
  BuildContext context,
  String name, {
  String? title,
}) async {
  var draft = name;
  return showDialog<String>(
    context: context,
    builder: (c) => StatefulBuilder(
      builder: (c, change) => AlertDialog(
        title: Text(
          title ?? socialText(c, 'تغییر نام', 'Rename'),
          style: const TextStyle(fontSize: 14),
        ),
        content: TextFormField(
          initialValue: name,
          autofocus: true,
          maxLength: 180,
          onChanged: (value) => change(() => draft = value),
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.grey),
            onPressed: () => Navigator.pop(c),
            child: Text(socialText(c, 'انصراف', 'Cancel')),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            onPressed: draft.trim().isEmpty
                ? null
                : () => Navigator.pop(c, draft.trim()),
            child: Text(socialText(c, 'ذخیره', 'Save')),
          ),
        ],
      ),
    ),
  );
}
