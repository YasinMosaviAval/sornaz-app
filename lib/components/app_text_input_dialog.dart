import 'package:flutter/material.dart';
import 'app_dialog.dart';

/// The dialog owns the controller; callers own any subsequent mutation.
class AppTextInputDialog extends StatefulWidget {
  const AppTextInputDialog({
    super.key,
    required this.title,
    this.initialValue = '',
    this.hint,
    this.maxLength = 180,
    this.confirmLabel,
    this.validator,
  });
  final String title, initialValue;
  final String? hint, confirmLabel;
  final int? maxLength;
  final FormFieldValidator<String>? validator;
  @override
  State<AppTextInputDialog> createState() => _AppTextInputDialogState();
}

class _AppTextInputDialogState extends State<AppTextInputDialog> {
  late final controller = TextEditingController(text: widget.initialValue);
  final form = GlobalKey<FormState>();
  void submit() {
    final value = controller.text.trim();
    if (value.isNotEmpty && form.currentState!.validate()) {
      Navigator.pop(context, value);
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fa = Localizations.localeOf(context).languageCode == 'fa';
    return AppDialog(
      title: Text(widget.title),
      content: Form(
        key: form,
        child: TextFormField(
          controller: controller,
          autofocus: true,
          maxLength: widget.maxLength,
          style: Theme.of(context).textTheme.bodyMedium,
          decoration: InputDecoration(hintText: widget.hint),
          validator: (value) => widget.validator?.call(value?.trim()),
          onChanged: (_) => setState(() {}),
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => submit(),
        ),
      ),
      actions: [
        AppDialogAction(
          role: AppDialogActionRole.cancel,
          onPressed: () => Navigator.pop(context),
          child: Text(fa ? 'انصراف' : 'Cancel'),
        ),
        AppDialogAction(
          onPressed: controller.text.trim().isEmpty ? null : submit,
          child: Text(widget.confirmLabel ?? (fa ? 'ذخیره' : 'Save')),
        ),
      ],
    );
  }
}

Future<String?> showTextInputDialog(
  BuildContext context, {
  required String title,
  String initialValue = '',
  String? hint,
  int? maxLength = 180,
  String? confirmLabel,
  FormFieldValidator<String>? validator,
}) => showDialog<String>(
  context: context,
  builder: (_) => AppTextInputDialog(
    title: title,
    initialValue: initialValue,
    hint: hint,
    maxLength: maxLength,
    confirmLabel: confirmLabel,
    validator: validator,
  ),
);
