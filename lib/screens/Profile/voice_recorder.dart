import 'package:flutter/material.dart';
import 'package:sornaz/components/bottom_nav.dart';
import 'package:sornaz/helpers/app_strings.dart';

class VoiceRecorderPage extends StatelessWidget {
  const VoiceRecorderPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.voiceRecorderTitle)),
      body: Text(AppStrings.voiceRecorderTitle),
      bottomNavigationBar: const BottomNavBarWidget(),
    );
  }
}
