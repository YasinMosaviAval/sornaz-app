import 'package:flutter/material.dart';
import 'package:sornaz/helpers/app_navigation.dart';
import 'package:sornaz/helpers/app_typography.dart';

class SectionTitle extends StatelessWidget {
  final String title;
  final String? viewAll;
  final Widget? viewAllLink;

  const SectionTitle({
    super.key,
    required this.title,
    this.viewAll,
    this.viewAllLink,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: AppTypography.sectionTitleTitle()),
        if (viewAll != null)
          TextButton(
            onPressed: () => navigateWithFade(context, viewAllLink!),
            child: Text(
              viewAll!,
              style: AppTypography.sectionTitleViewAllLink(),
            ),
          ),
      ],
    );
  }
}
