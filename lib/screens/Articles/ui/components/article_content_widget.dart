import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:provider/provider.dart';
import 'package:sornaz/helpers/app_data.dart';

class ArticlesContentWidget extends StatelessWidget {
  const ArticlesContentWidget({
    super.key,
    required this.content,
    this.onLinkTap,
  });
  final String content;
  final ValueChanged<String>? onLinkTap;
  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppData>();
    return Html(
      data: content,
      onLinkTap: (url, attributes, element) {
        if (url != null) onLinkTap?.call(url);
      },
      style: {
        'body': Style(
          margin: Margins.zero,
          padding: HtmlPaddings.zero,
          fontFamily: app.fontFamily,
          fontSize: FontSize(14 + app.fontSize),
          color: app.isDark ? Colors.white : const Color(0xff374151),
          lineHeight: const LineHeight(1.8),
        ),
        'p': Style(
          textAlign: TextAlign.justify,
          margin: Margins.only(bottom: 16, left: 0, right: 0),
        ),
        'div': Style(textAlign: TextAlign.justify),
        'img': Style(width: Width(100, Unit.percent), height: Height.auto()),
        'a': Style(
          color: app.isDark ? const Color(0xffd3ae32) : const Color(0xff4f46e5),
          textDecoration: TextDecoration.underline,
        ),
        'blockquote': Style(
          padding: HtmlPaddings.all(16),
          backgroundColor: app.isDark
              ? const Color(0xff222222)
              : const Color(0xfff3f4f6),
        ),
      },
    );
  }
}
