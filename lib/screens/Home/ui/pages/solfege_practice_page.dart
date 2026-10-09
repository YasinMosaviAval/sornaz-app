import 'package:flutter/material.dart';
import 'package:sornaz/components/app_bar.dart';
import 'package:sornaz/screens/Social/social_widgets.dart';

class SolfegePracticePage extends StatelessWidget {
  const SolfegePracticePage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: SornazAppBar(
      title: socialText(context, 'تمرین سولفژ', 'Solfege practice'),
    ),
    body: ListView(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      children: [
        for (final section in [
          ('گام شناسی', 'Scale recognition'),
          ('آکورد شناسی', 'Chord recognition'),
          ('تشخیص فرکانس', 'Frequency recognition'),
          ('تشخیص فاصله', 'Interval recognition'),
          ('تشخیص آکورد', 'Chord identification'),
          ('تشخیص هارمونی', 'Harmony recognition'),
        ])
          ListTile(
            title: Text(
              socialText(context, section.$1, section.$2),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
      ],
    ),
  );
}
