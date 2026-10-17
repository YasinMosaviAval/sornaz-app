import 'package:shamsi_date/shamsi_date.dart';
import '../Social/social_api.dart';

bool panelSessionAction(String action, Json session, Json permissions) {
  final cancellation = session['cancellationStatus'] ?? 'none';
  final booking = session['bookingStatus'] ?? '';
  final approve = permissions['canApproveSessionCancellations'] == true;
  return switch (action) {
    'cancel' =>
      ['none', 'rejected'].contains(cancellation) &&
          !['canceled', 'rejected', 'completed', 'held'].contains(booking) &&
          permissions['canCancelSessions'] == true,
    'cancel-approve' || 'cancel-reject' => cancellation == 'pending' && approve,
    'restore' =>
      cancellation == 'pending' ||
          (cancellation == 'approved' || booking == 'canceled') && approve,
    _ => false,
  };
}

bool panelPayableInstallment(Json invoice, Json installment) {
  final next = objects(
    invoice['installments'] ?? [],
  ).where((item) => item['statusCode'] != 'paid').firstOrNull;
  return installment['statusCode'] != 'paid' &&
      next != null &&
      '${next['id']}' == '${installment['id']}';
}

List<Json> panelSortedRows(
  List<Json> rows,
  String key,
  bool ascending,
  dynamic Function(Json row, String key) value,
) {
  if (key.isEmpty) return rows;
  final entries = rows.indexed.toList();
  entries.sort((a, b) {
    final left = value(a.$2, key), right = value(b.$2, key);
    final l = left is num ? left : num.tryParse('$left');
    final r = right is num ? right : num.tryParse('$right');
    final compared = l != null && r != null
        ? l.compareTo(r)
        : '$left'.toLowerCase().compareTo('$right'.toLowerCase());
    return compared == 0
        ? a.$1.compareTo(b.$1)
        : ascending
        ? compared
        : -compared;
  });
  return entries.map((entry) => entry.$2).toList();
}

String panelNumber(dynamic value, {required bool fa}) {
  final number = value is num ? value : num.tryParse('$value');
  if (number == null) return '${value ?? '—'}';
  final parts = '$number'.split('.');
  final grouped = parts.first.replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
    (match) => '${match[1]},',
  );
  final text =
      '$grouped${parts.length > 1 && parts[1] != '0' ? '.${parts[1]}' : ''}';
  return fa ? panelDigits(text) : text;
}

String panelDigits(String text) => text.replaceAllMapped(
  RegExp(r'\d'),
  (match) => '۰۱۲۳۴۵۶۷۸۹'[int.parse(match[0]!)],
);

String panelDate(dynamic value, {required bool fa}) {
  if (value == null || '$value'.isEmpty) return '—';
  final parsed = DateTime.tryParse('$value');
  if (parsed == null || !fa) return '$value';
  final date = Jalali.fromDateTime(parsed);
  return panelDigits(
    '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}${'$value'.length > 10 ? ' ${parsed.hour.toString().padLeft(2, '0')}:${parsed.minute.toString().padLeft(2, '0')}' : ''}',
  );
}

List<Json> panelExportRows(
  List<Json> rows,
  List<Json> columns,
  Json Function(Json row) display,
  String Function(Json row, Json column) text,
) => [
  for (final row in rows)
    {
      for (final column in columns)
        '${column['en'] ?? column['label']}': text(display(row), column),
    },
];
