import 'package:flutter/material.dart';
import 'package:sornaz/components/app_dialog.dart';
import 'package:sornaz/screens/Social/social_widgets.dart';

Future<bool> confirmNotationStructureDelete(BuildContext context, String kind) {
  if (kind != 'part' && kind != 'section' && kind != 'subsection') {
    throw const FormatException('Invalid notation structure.');
  }
  return showDeleteConfirmation(
    context,
    title: kind == 'part'
        ? socialText(context, 'حذف پارت ساز', 'Delete instrument part')
        : kind == 'subsection'
        ? socialText(context, 'حذف بخش', 'Delete subsection')
        : socialText(context, 'حذف قسمت', 'Delete section'),
    message: socialText(
      context,
      'تمام نت‌های این بخش حذف می‌شوند. ادامه می‌دهید؟',
      'All notes in this part or section will be deleted. Continue?',
    ),
    deleteLabel: socialText(context, 'حذف', 'Delete'),
    cancelLabel: socialText(context, 'انصراف', 'Cancel'),
  );
}
