import 'package:flutter/material.dart';
import 'package:sornaz/components/app_bar.dart';
import 'package:sornaz/screens/Social/social_widgets.dart';

class RhythmPracticePage extends StatelessWidget {
  const RhythmPracticePage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: SornazAppBar(
      title: socialText(context, 'تمرین ریتم', 'Rhythm practice'),
    ),
    body: const SizedBox.expand(),
  );
}
