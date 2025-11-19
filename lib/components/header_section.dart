import 'package:flutter/material.dart';

class HeaderSection extends StatelessWidget {
  final String title;
  final ThemeData theme;

  const HeaderSection({super.key, required this.title, required this.theme});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: theme.textTheme.headlineMedium),
            TextButton(onPressed: () {}, child: const Text('View all')),
          ],
        ),
      ),
    );
  }
}
