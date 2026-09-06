import 'package:flutter/material.dart';
import 'package:sornaz/helpers/app_functions.dart';

String articleDate(BuildContext context, String value) {
  if (value.isEmpty) return '—';
  if (Localizations.localeOf(context).languageCode == 'en') {
    return DateTime.tryParse(value)?.toIso8601String().split('T').first ??
        value;
  }
  return formatJalaliDate(value);
}

String articlePlain(String value) => value
    .replaceAll(RegExp(r'<[^>]*>'), '')
    .replaceAll('&amp;', '&')
    .replaceAll('&nbsp;', ' ');
String articleImage(Map<String, dynamic> post) {
  final media = post['_embedded']?['wp:featuredmedia'];
  return media is List && media.isNotEmpty
      ? '${media.first['source_url'] ?? ''}'
      : '';
}
