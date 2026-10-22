import '../Social/social_api.dart';

const panelInvoiceStatuses = {
  'draft': 'پیش‌نویس',
  'issued': 'صادرشده',
  'partial': 'پرداخت جزئی',
  'partially_paid': 'پرداخت جزئی',
  'paid': 'پرداخت‌شده',
  'pending': 'در انتظار پرداخت',
  'canceled': 'لغوشده',
  'cancelled': 'لغوشده',
  'void': 'باطل‌شده',
};

Json panelInvoiceStatusField(Json field) => {
  ...field,
  'label': 'وضعیت',
  'type': 'select',
  'options': panelInvoiceStatuses,
  'readOnly': true,
};

List<Json> panelSubscriptionRows(Json data) => [
  for (final period in objects(data['periods'] ?? []))
    {
      'id': 'subscription-${period['id']}',
      'subscriptionId': period['id'],
      'invoiceKind': 'subscription',
      'title': 'اشتراک سامانه مدیریت آموزشگاه',
      'termName': 'اشتراک سامانه مدیریت آموزشگاه',
      'organizationKind': 'academy',
      'branchId': 0,
      'branchName': period['academyName'] ?? 'آموزشگاه',
      'course': '${period['start']} تا ${period['end']}',
      'type': 'اشتراک سامانه',
      'amount': period['amount'],
      'dateIso': period['dueDate'] ?? period['start'],
      'date': period['dueDate'] ?? period['start'],
      'statusCode': period['statusCode'],
      'status': period['status'],
      'statusLabel': period['status'],
      'canPay': period['canPay'],
      'installments': <Json>[],
      'canEdit': false,
      'canDelete': false,
    },
];

num _amount(dynamic value) =>
    value is num ? value : num.tryParse('$value') ?? 0;

Json panelFinanceTotals(List<Json> rows) {
  num total = 0, paid = 0;
  for (final row in rows) {
    total += _amount(row['amount']);
    if (row['invoiceKind'] == 'subscription' && row['statusCode'] == 'paid') {
      paid += _amount(row['amount']);
    } else {
      for (final installment in objects(row['installments'] ?? [])) {
        if (installment['statusCode'] == 'paid') {
          paid += _amount(installment['amount']);
        }
      }
    }
  }
  return {
    'total': total,
    'paid': paid,
    'remaining': (total - paid).clamp(0, double.infinity),
  };
}
