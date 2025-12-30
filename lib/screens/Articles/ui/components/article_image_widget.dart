import 'package:flutter/material.dart';
import 'package:sornaz/helpers/app_spacing.dart';

class ArticlesImageWidget extends StatelessWidget {
  const ArticlesImageWidget({super.key, required this.imageUrl});
  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return Image.network(
      imageUrl,
      fit: BoxFit.contain,
      height: AppSpacing.space_200,
      width: double.infinity,
    );
  }
}
