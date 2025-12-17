import 'package:flutter/material.dart';

class EqualizerTab extends StatelessWidget {
  const EqualizerTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        EqualizerSlider(label: 'Bass'),
        EqualizerSlider(label: 'Mid'),
        EqualizerSlider(label: 'Treble'),
      ],
    );
  }
}

class EqualizerSlider extends StatelessWidget {
  final String label;
  const EqualizerSlider({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        Slider(
          min: -10,
          max: 10,
          value: 0,
          onChanged: (_) {},
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}


