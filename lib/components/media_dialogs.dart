import 'package:sornaz/components/app_text_input_dialog.dart';
import 'package:sornaz/components/app_dialog.dart';
import 'package:flutter/material.dart';
import '../screens/Social/social_widgets.dart';

Future<bool> confirmMediaDelete(BuildContext context, String title) async =>
    await showDeleteConfirmation(context, title: title);

Future<String?> renameMediaDialog(
  BuildContext context,
  String name, {
  String? title,
}) async {
  return showTextInputDialog(
    context,
    title: title ?? socialText(context, 'تغییر نام', 'Rename'),
    initialValue: name,
    maxLength: 180,
  );
}
