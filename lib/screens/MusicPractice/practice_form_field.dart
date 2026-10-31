import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../Social/social_widgets.dart';

class PracticeFieldValidation {
  static const ranges = <String, (num, num)>{
    'position': (0, 100000),
    'stageCount': (1, 100),
    'requiredWins': (1, 100),
    'amount': (1000, 1000000000),
    'days': (1, 366),
    'bpm': (30, 240),
    'teacherPercent': (0, 100),
  };
  static String normalize(String name, String value) {
    if (name == 'slug') return value.toLowerCase();
    if (!ranges.containsKey(name) &&
        !['quarterSteps', 'beats', 'correct'].contains(name)) {
      return value;
    }
    return value
        .replaceAllMapped(
          RegExp('[۰-۹]'),
          (m) => (m[0]!.codeUnitAt(0) - 1776).toString(),
        )
        .replaceAllMapped(
          RegExp('[٠-٩]'),
          (m) => (m[0]!.codeUnitAt(0) - 1632).toString(),
        )
        .replaceAll('،', ',')
        .replaceAll('٫', '.');
  }

  static String suggestSlug(String title) {
    var value = title
        .toLowerCase()
        .replaceAll(RegExp('[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    if (value.isNotEmpty && !RegExp('^[a-z]').hasMatch(value)) {
      value = 'section-$value';
    }
    return value.substring(0, math.min(100, value.length));
  }

  static String hint(String name, bool en) {
    if (name == 'slug') {
      return en
          ? '1–100 characters: start with an English letter; then letters, digits or hyphens. Example: ear-training. Suggested from the English title.'
          : '۱ تا ۱۰۰ نویسه؛ شروع با حرف انگلیسی، سپس حرف، عدد یا خط تیره. نمونه: ear-training. از عنوان انگلیسی پیشنهاد می‌شود.';
    }
    final range = ranges[name];
    if (range != null) {
      return name == 'teacherPercent'
          ? (en
                ? 'Percentage from 0 to 100, with at most two decimal places.'
                : 'درصدی از ۰ تا ۱۰۰ با حداکثر دو رقم اعشار.')
          : (en
                ? 'A whole number from ${range.$1} to ${range.$2}, without thousands separators.'
                : 'عدد صحیح از ${range.$1} تا ${range.$2}، بدون جداکنندهٔ هزارگان.');
    }
    if (name == 'quarterSteps') {
      return en
          ? 'Comma-separated whole numbers from 1 to 24; example: 14,24. Each unit is a quarter-tone.'
          : 'اعداد صحیح ۱ تا ۲۴ با ویرگول؛ نمونه: 14,24. هر واحد یک ربع‌پرده است.';
    }
    if (name == 'beats') {
      return en
          ? '1–64 beat lengths from 0.125 to 8, separated by commas; example: 1,0.5,0.5.'
          : '۱ تا ۶۴ کشش از 0.125 تا 8، با ویرگول؛ نمونه: 1,0.5,0.5.';
    }
    if (name == 'choices') {
      return en
          ? '2–12 choices, one per line, up to 200 characters each.'
          : '۲ تا ۱۲ گزینه، هر گزینه در یک سطر و حداکثر ۲۰۰ نویسه.';
    }
    if (name == 'correct') {
      return en
          ? 'The correct choice index starts at zero; enter 0 for the first choice.'
          : 'شمارهٔ گزینهٔ درست از صفر شروع می‌شود؛ برای گزینهٔ اول 0 وارد کنید.';
    }
    final max = name.startsWith('prompt') ? 2000 : 200;
    return en
        ? 'Required text, up to $max characters.'
        : 'متن الزامی، حداکثر $max نویسه.';
  }

  static String? error(
    String name,
    String raw,
    bool en, {
    int choiceCount = 0,
    bool required = true,
  }) {
    final value = normalize(name, raw).trim();
    if (value.isEmpty) {
      return required
          ? (en ? 'Complete this field.' : 'این فیلد را تکمیل کنید.')
          : null;
    }
    if (name == 'slug') {
      return RegExp(r'^[a-z][a-z0-9-]{0,99}$').hasMatch(value)
          ? null
          : hint(name, en);
    }
    final range = ranges[name];
    if (range != null) {
      final number = num.tryParse(value),
          valid = name == 'teacherPercent'
              ? RegExp(r'^(?:\d+(?:\.\d{0,2})?|\.\d{1,2})$').hasMatch(value)
              : RegExp(r'^\d+$').hasMatch(value);
      return valid && number != null && number >= range.$1 && number <= range.$2
          ? null
          : hint(name, en);
    }
    if (name == 'quarterSteps' || name == 'beats') {
      final parts = value.split(',').map((p) => p.trim()).toList();
      final valid =
          parts.length <= (name == 'beats' ? 64 : 24) &&
          parts.every((p) {
            final n = num.tryParse(p);
            return n != null &&
                n.isFinite &&
                (name != 'beats' ||
                    RegExp(
                      r'^[+-]?(?:\d+(?:\.\d*)?|\.\d+)(?:[eE][+-]?\d+)?$',
                    ).hasMatch(p)) &&
                (name == 'beats'
                    ? n >= .125 && n <= 8
                    : RegExp(r'^\d+$').hasMatch(p) && n >= 1 && n <= 24);
          });
      return valid ? null : hint(name, en);
    }
    if (name == 'choices') {
      final choices = value
          .split('\n')
          .where((p) => p.trim().isNotEmpty)
          .toList();
      return choices.length >= 2 &&
              choices.length <= 12 &&
              choices.every((p) => p.runes.length <= 200)
          ? null
          : hint(name, en);
    }
    if (name == 'correct') {
      final index = int.tryParse(value);
      return RegExp(r'^\d+$').hasMatch(value) &&
              index != null &&
              index < choiceCount
          ? null
          : (en
                ? 'Enter an index from 0 to ${math.max(0, choiceCount - 1)}; complete the choices first.'
                : 'شماره‌ای از ۰ تا ${math.max(0, choiceCount - 1)} وارد کنید؛ ابتدا گزینه‌ها را تکمیل کنید.');
    }
    return value.runes.length <= (name.startsWith('prompt') ? 2000 : 200)
        ? null
        : hint(name, en);
  }
}

class PracticeFormField extends StatefulWidget {
  const PracticeFormField({
    super.key,
    required this.name,
    required this.label,
    required this.controller,
    this.lines = 1,
    this.required = true,
    this.readOnly = false,
    this.choiceCount = 0,
    this.onChanged,
    this.extraValidator,
  });
  final String name, label;
  final TextEditingController controller;
  final int lines, choiceCount;
  final bool required, readOnly;
  final ValueChanged<String>? onChanged;
  final String? Function(String)? extraValidator;
  @override
  State<PracticeFormField> createState() => _PracticeFormFieldState();
}

class _PracticeFormFieldState extends State<PracticeFormField> {
  final focus = FocusNode();
  @override
  void initState() {
    super.initState();
    focus.addListener(changed);
    widget.controller.addListener(changed);
  }

  void changed() {
    if (mounted) setState(() {});
  }

  @override
  void didUpdateWidget(PracticeFormField old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller.removeListener(changed);
      widget.controller.addListener(changed);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(changed);
    focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final en = Localizations.localeOf(context).languageCode == 'en';
    String? validate(String raw) =>
        PracticeFieldValidation.error(
          widget.name,
          raw,
          en,
          choiceCount: widget.choiceCount,
          required: widget.required,
        ) ??
        widget.extraValidator?.call(raw);
    final error = validate(widget.controller.text), theme = Theme.of(context);
    final color = !focus.hasFocus
        ? theme.colorScheme.onSurfaceVariant
        : error != null
        ? theme.colorScheme.error
        : theme.brightness == Brightness.dark
        ? Colors.green.shade300
        : Colors.green.shade700;
    return TextFormField(
      controller: widget.controller,
      focusNode: focus,
      readOnly: widget.readOnly,
      keyboardType: PracticeFieldValidation.ranges.containsKey(widget.name)
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.multiline,
      maxLines: widget.lines,
      style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12),
      decoration: InputDecoration(
        labelText: widget.label,
        labelStyle: theme.textTheme.bodyMedium?.copyWith(fontSize: 12),
        helperMaxLines: 5,
        errorMaxLines: 5,
        helperText: focus.hasFocus
            ? (error ??
                  socialText(
                    context,
                    'مقدار واردشده قابل قبول است.',
                    'This value is acceptable.',
                  ))
            : PracticeFieldValidation.hint(widget.name, en),
        helperStyle: theme.textTheme.bodySmall?.copyWith(
          color: color,
          fontSize: 12,
        ),
      ),
      validator: (value) => validate(value ?? ''),
      autovalidateMode: AutovalidateMode.onUserInteraction,
      onChanged: (value) {
        final normalized = PracticeFieldValidation.normalize(
          widget.name,
          value,
        );
        if (normalized != value) {
          widget.controller.value = TextEditingValue(
            text: normalized,
            selection: TextSelection.collapsed(
              offset: math.min(
                widget.controller.selection.extentOffset.clamp(
                  0,
                  normalized.length,
                ),
                normalized.length,
              ),
            ),
          );
        }
        widget.onChanged?.call(normalized);
      },
    );
  }
}
