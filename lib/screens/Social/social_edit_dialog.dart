import 'package:sornaz/helpers/app_translations.dart';
import 'package:sornaz/components/app_text.dart';
import 'package:flutter/material.dart';

class SocialEditDialog extends StatefulWidget {
  const SocialEditDialog({
    super.key,
    required this.title,
    required this.labels,
    required this.values,
    this.passwordOnly = false,
  });
  final String title;
  final bool passwordOnly;
  final List<String> labels, values;
  @override
  State<SocialEditDialog> createState() => _SocialEditDialogState();
}

class _SocialEditDialogState extends State<SocialEditDialog> {
  late final controllers = widget.values
      .map((value) => TextEditingController(text: value))
      .toList();
  @override
  void dispose() {
    for (final controller in controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: AppText(widget.title),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < controllers.length; i++)
            TextField(
              controller: controllers[i],
              autofocus: i == 0,
              maxLength: i == 0
                  ? 180
                  : i == 2
                  ? 72
                  : 100000,
              maxLines: i == 1 ? 6 : 1,
              obscureText: i == 2 || widget.passwordOnly,
              decoration: InputDecoration(
                labelText: widget.labels[i].translate(context),
              ),
            ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const AppText('انصراف'),
      ),
      FilledButton(
        onPressed: () {
          if (controllers.first.text.trim().isNotEmpty) {
            Navigator.pop(
              context,
              controllers.map((c) => c.text.trim()).toList(),
            );
          }
        },
        child: const AppText('ثبت'),
      ),
    ],
  );
}
