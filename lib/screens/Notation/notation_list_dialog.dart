import 'package:sornaz/components/app_text_input_dialog.dart';
import 'package:flutter/material.dart';
import 'package:sornaz/screens/Social/social_widgets.dart';

Future<String?> createNotationList(BuildContext context) => showTextInputDialog(
  context,
  title: socialText(context, 'لیست جدید', 'New list'),
  hint: socialText(context, 'نام لیست', 'List name'),
  maxLength: 80,
  confirmLabel: socialText(context, 'ایجاد', 'Create'),
);
