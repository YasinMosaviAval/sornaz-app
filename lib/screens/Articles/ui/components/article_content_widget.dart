import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';

class ArticlesContentWidget extends StatelessWidget {
  const ArticlesContentWidget({super.key, required this.content});
  final String content;

  @override
  Widget build(BuildContext context) {
    return Html(
      data: content,
      style: {'img': Style(height: Height.auto())},
    );
  }
}
