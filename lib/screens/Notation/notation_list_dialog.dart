import 'package:flutter/material.dart';
import 'package:sornaz/screens/Players/ui/components/player_dialog.dart';
import 'package:sornaz/screens/Social/social_widgets.dart';

Future<String?> createNotationList(BuildContext context) async {
  var draft = '';
  return showDialog<String>(
    context: context,
    builder: (dialogContext) => PlayerDialog(
        title: Text(socialText(dialogContext, 'لیست جدید', 'New list')),
        content: TextField(
          autofocus: true,
          maxLength: 80,
          style: Theme.of(dialogContext).textTheme.bodyMedium,
          onChanged: (value) => draft = value,
          decoration: InputDecoration(
            hintText: socialText(dialogContext, 'نام لیست', 'List name'),
          ),
        ),
        actions: [
          PlayerDialogButton(
            primary: false,
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(socialText(dialogContext, 'انصراف', 'Cancel')),
          ),
          PlayerDialogButton(
            onPressed: () => Navigator.pop(dialogContext, draft.trim()),
            child: Text(socialText(dialogContext, 'ایجاد', 'Create')),
          ),
        ],
      ),
  );
}
