import 'package:flutter/material.dart';
import 'package:sornaz/helpers/app_translations.dart';

bool validRegistrationUsername(String value) =>
    RegExp(r'^[A-Za-z0-9_]{3,100}$').hasMatch(value);

String normalizeRegistrationPhone(String value) {
  const digits = '0123456789';
  const persian =
      '\u06f0\u06f1\u06f2\u06f3\u06f4\u06f5\u06f6\u06f7\u06f8\u06f9';
  const arabic = '\u0660\u0661\u0662\u0663\u0664\u0665\u0666\u0667\u0668\u0669';
  return value
      .split('')
      .map((c) {
        final index = persian.indexOf(c);
        if (index >= 0) return digits[index];
        final other = arabic.indexOf(c);
        return other >= 0 ? digits[other] : c;
      })
      .join()
      .replaceAll(RegExp(r'\s'), '');
}

List<bool> registrationPasswordCriteria(String value) => [
  RegExp(r'[A-Z]').hasMatch(value),
  RegExp(r'[a-z]').hasMatch(value),
  RegExp(r'[0-9]').hasMatch(value),
  RegExp(r'[!@#$%^&*()\-_+=\[\]{}|;:,.<>?\/~]').hasMatch(value),
  value.length > 8,
];

class UsernameFeedback extends StatelessWidget {
  const UsernameFeedback({super.key, required this.controller});
  final TextEditingController controller;
  @override
  Widget build(BuildContext context) =>
      ValueListenableBuilder<TextEditingValue>(
        valueListenable: controller,
        builder: (context, value, _) {
          final empty = value.text.isEmpty;
          final valid = validRegistrationUsername(value.text);
          return Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                (empty
                        ? 'auth.username_hint'
                        : valid
                        ? 'auth.username_valid'
                        : 'auth.username_invalid')
                    .translate(context),
                style: TextStyle(
                  fontSize: 12,
                  color: empty
                      ? Colors.grey
                      : valid
                      ? Colors.green
                      : Colors.red,
                ),
              ),
            ),
          );
        },
      );
}

class PasswordStrengthFeedback extends StatelessWidget {
  const PasswordStrengthFeedback({super.key, required this.controller});
  final TextEditingController controller;
  @override
  Widget build(BuildContext context) =>
      ValueListenableBuilder<TextEditingValue>(
        valueListenable: controller,
        builder: (context, value, _) {
          final criteria = registrationPasswordCriteria(value.text);
          final score = criteria.where((met) => met).length;
          final hue = score <= 1 ? 0.0 : (score - 1) * 30.0;
          final color = HSLColor.fromAHSL(1, hue, .75, .42).toColor();
          const labels = [
            'auth.upper',
            'auth.lower',
            'auth.number',
            'auth.special',
            'auth.length',
          ];
          final strength = score < 3
              ? 'auth.very_weak'
              : score == 3
              ? 'auth.medium'
              : score == 4
              ? 'auth.strong'
              : 'auth.very_strong';
          return Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'auth.strength'.translate(context),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    Text(
                      strength.translate(context),
                      style: TextStyle(fontSize: 12, color: color),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: LinearProgressIndicator(
                    value: score / 5,
                    minHeight: 8,
                    color: color,
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(6),
                    semanticsLabel: 'auth.strength'.translate(context),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 16,
                  runSpacing: 6,
                  children: [
                    for (var i = 0; i < criteria.length; i++)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            criteria[i] ? Icons.check : Icons.circle_outlined,
                            size: 14,
                            color: criteria[i] ? Colors.green : Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            labels[i].translate(context),
                            style: TextStyle(
                              fontSize: 12,
                              color: criteria[i] ? Colors.green : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          );
        },
      );
}
