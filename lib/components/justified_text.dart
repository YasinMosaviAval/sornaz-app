import 'package:flutter/material.dart';
import 'package:sornaz/helpers/app_spacing.dart';
import 'package:sornaz/helpers/app_typography.dart';

class JustifiedText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final EdgeInsetsGeometry? padding;

  const JustifiedText({
    super.key,
    required this.text,
    this.style,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.symmetric(
        horizontal: AppSpacing.space_24,
        vertical: AppSpacing.space_12,
      ),
      child: Text(
        text,
        style: style ?? AppTypography.aboutUsBody(context),
        textAlign: TextAlign.justify,
      ),
    );
  }
}
