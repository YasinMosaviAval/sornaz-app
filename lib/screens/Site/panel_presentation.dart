import 'package:flutter/services.dart';
import 'package:archive/archive.dart';
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

/// A real XLSX workbook with inline text cells: user content is never a formula.
List<int> panelExcelBytes(List<Json> rows) {
  String xml(dynamic value) => '$value'
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&apos;');
  final columns = rows.expand((row) => row.keys).toSet().toList();
  final table = [
    columns,
    for (final row in rows) [for (final key in columns) row[key] ?? ''],
  ];
  final sheet =
      '<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main"><sheetViews><sheetView workbookViewId="0" rightToLeft="1"/></sheetViews><sheetData>${[
        for (final row in table) '<row>${[for (final cell in row) '<c t="inlineStr"><is><t xml:space="preserve">${xml(cell)}</t></is></c>'].join()}</row>',
      ].join()}</sheetData></worksheet>';
  final files = {
    '[Content_Types].xml':
        '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types"><Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/><Default Extension="xml" ContentType="application/xml"/><Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/><Override PartName="/xl/worksheets/sheet1.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/></Types>',
    '_rels/.rels':
        '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/></Relationships>',
    'xl/workbook.xml':
        '<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"><sheets><sheet name="Finance" sheetId="1" r:id="rId1"/></sheets></workbook>',
    'xl/_rels/workbook.xml.rels':
        '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet1.xml"/></Relationships>',
    'xl/worksheets/sheet1.xml': sheet,
  };
  final archive = Archive();
  for (final file in files.entries) {
    final bytes = utf8.encode(file.value);
    archive.addFile(ArchiveFile(file.key, bytes.length, bytes));
  }
  return ZipEncoder().encode(archive);
}

Future<void> exportPanelExcel(String name, List<Json> rows) async {
  final bytes = Uint8List.fromList(panelExcelBytes(rows));
  final path = await FilePicker.platform.saveFile(
    fileName: '$name.xlsx',
    bytes: bytes,
  );
  if (path != null &&
      (Platform.isWindows || Platform.isLinux || Platform.isMacOS))
    await File(path).writeAsBytes(bytes);
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
            height: 40,
            child: Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        socialText(
                          context,
                          labels[entry.key]?.$1 ?? entry.key,
                          labels[entry.key]?.$2 ?? entry.key,
                        ),
                        maxLines: 2,
                        style: const TextStyle(fontSize: 11),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          '${entry.value}',
                          style: TextStyle(
                            fontSize: 13,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
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
