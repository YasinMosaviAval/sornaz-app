import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../Social/social_api.dart';
import '../Social/social_widgets.dart';
import 'panel_api.dart';
import 'site_api.dart';

String panelCsv(List<Json> rows) {
  final columns = rows
      .expand((row) => row.keys)
      .where(
        (key) => ![
          'password',
          'csrf_token',
          'permissions',
          'catalog',
          'staff_catalog',
        ].contains(key),
      )
      .toSet()
      .toList();
  String cell(dynamic value) {
    var text = value is Map || value is List
        ? jsonEncode(value)
        : '${value ?? ''}';
    if (RegExp(r'^[=+@\-\t\r]').hasMatch(text)) text = "'$text";
    return '"${text.replaceAll('"', '""')}"';
  }

  return '\ufeff${[columns.map(cell).join(','), for (final row in rows) columns.map((key) => cell(row[key])).join(',')].join('\r\n')}';
}

Future<void> exportPanelRows(String name, List<Json> rows) async {
  final bytes = utf8.encode(panelCsv(rows));
  final path = await FilePicker.platform.saveFile(
    fileName: '$name.csv',
    bytes: bytes,
  );
  if (path != null &&
      (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    await File(path).writeAsBytes(bytes);
  }
}

class PanelProfileHeader extends StatelessWidget {
  const PanelProfileHeader({super.key, required this.profile});
  final Json profile;
  @override
  Widget build(BuildContext context) {
    final url = '${profile['avatarUrl'] ?? ''}';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            ClipOval(
              child: url.isEmpty
                  ? const SizedBox(
                      width: 64,
                      height: 64,
                      child: Icon(Icons.person_outline, size: 40),
                    )
                  : Image.network(
                      SiteApi.origin.resolve(url).toString(),
                      width: 64,
                      height: 64,
                      fit: BoxFit.cover,
                      errorBuilder: (_, error, stack) => const SizedBox(
                        width: 64,
                        height: 64,
                        child: Icon(Icons.person_outline, size: 40),
                      ),
                    ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    panelTitle(profile),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text('${profile['email'] ?? profile['phone'] ?? ''}'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PanelStatistics extends StatelessWidget {
  const PanelStatistics({super.key, required this.stats});
  final Json stats;
  static const labels = {
    'activeStudents': ('هنرجویان فعال', 'Active students'),
    'todayClasses': ('کلاس‌های امروز', 'Today’s classes'),
    'monthlyIncome': ('درآمد ماه', 'Monthly income'),
    'attendanceRate': ('حضور در کلاس', 'Attendance'),
    'pendingPayments': ('اقساط معوق', 'Overdue payments'),
    'absencesToday': ('غیبت‌های امروز', 'Absences today'),
    'newMessages': ('پیام‌های جدید', 'New messages'),
    'urgentAlerts': ('موارد نیازمند رسیدگی', 'Action required'),
    'newStudentsWeek': ('ثبت‌نام‌های هفته', 'Weekly enrollments'),
    'pointsAwarded': ('امتیازهای اعطاشده', 'Points awarded'),
  };
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, size) => Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final entry in stats.entries)
          SizedBox(
            width: (size.maxWidth - 8) / 2,
            child: Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      socialText(
                        context,
                        labels[entry.key]?.$1 ?? entry.key,
                        labels[entry.key]?.$2 ?? entry.key,
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${entry.value}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

Future<Uint8List> panelPdf(
  String title,
  List<Json> rows, {
  required bool rtl,
  Map<String, String> labels = const {},
}) async {
  final font = pw.Font.ttf(
    await rootBundle.load('assets/fonts/vazir_fa/regular.ttf'),
  );
  final document = pw.Document();
  final content = <pw.Widget>[];
  for (final row in rows) {
    content.add(
      pw.Padding(
        padding: const pw.EdgeInsets.only(top: 12, bottom: 6),
        child: pw.Text(
          panelTitle(row),
          style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
        ),
      ),
    );
    for (final entry in row.entries) {
      if ([
        'password',
        'csrf_token',
        'permissions',
        'catalog',
        'staff_catalog',
      ].contains(entry.key)) {
        continue;
      }
      final value = entry.value;
      final text = value is Map || value is List
          ? jsonEncode(value)
          : '${value ?? ''}';
      if (text.isEmpty) continue;
      // Separate long fields into layout blocks so they can continue on another page.
      final characters = text.runes.toList();
      for (var offset = 0; offset < characters.length; offset += 350) {
        final end = (offset + 350).clamp(0, characters.length);
        content.add(
          pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 4),
            child: pw.Text(
              '${offset == 0 ? '${labels[entry.key] ?? entry.key}: ' : ''}${String.fromCharCodes(characters.sublist(offset, end))}',
              style: const pw.TextStyle(fontSize: 10),
            ),
          ),
        );
      }
    }
    content.add(pw.Divider());
  }
  document.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      maxPages: 1000,
      theme: pw.ThemeData.withFont(base: font, bold: font),
      textDirection: rtl ? pw.TextDirection.rtl : pw.TextDirection.ltr,
      header: (_) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 12),
        child: pw.Text(title, style: const pw.TextStyle(fontSize: 16)),
      ),
      footer: (context) => pw.Align(
        alignment: pw.Alignment.center,
        child: pw.Text('${context.pageNumber} / ${context.pagesCount}'),
      ),
      build: (_) => content,
    ),
  );
  return document.save();
}

Future<void> exportPanelPdf(
  String name,
  List<Json> rows, {
  required bool rtl,
  Map<String, String> labels = const {},
}) async {
  final bytes = await panelPdf(name, rows, rtl: rtl, labels: labels);
  final path = await FilePicker.platform.saveFile(
    fileName: '$name.pdf',
    bytes: bytes,
  );
  if (path != null &&
      (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    await File(path).writeAsBytes(bytes);
  }
}
