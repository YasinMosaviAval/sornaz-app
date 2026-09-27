import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../Social/social_api.dart';
import '../Social/social_widgets.dart';
import 'panel_api.dart';
import 'branch_style.dart';

class BranchForm extends StatefulWidget {
  const BranchForm({
    super.key,
    required this.api,
    required this.data,
    this.row,
    this.typesOnly = false,
    this.academyId = '',
  });
  final PanelApi api;
  final Json data;
  final Json? row;
  final bool typesOnly;
  final String academyId;
  @override
  State<BranchForm> createState() => _BranchFormState();
}

class _BranchFormState extends State<BranchForm> {
  final form = GlobalKey<FormState>();
  late final Json values = {
    'status': 'active',
    'physical_type': 'physical',
    'academy_id': widget.academyId.isNotEmpty
        ? widget.academyId
        : objects(widget.data['academies'] ?? []).firstOrNull?['id'] ??
              objects(
                widget.data['branches'] ?? [],
              ).firstOrNull?['academy_id'] ??
              '',
    ...?widget.row,
    if (widget.row != null) 'status': branchStatusCode(widget.row!),
    if (widget.typesOnly)
      'title': widget.row?['title'] ?? widget.row?['name'] ?? '',
  };
  late final List<Json> phones = copyRows('phones'),
      links = copyRows('links'),
      addresses = copyRows('addresses');
  late final List<Json> types = objects(widget.data['types'] ?? []);
  bool saving = false;
  String? error;
  bool get fa => Localizations.localeOf(context).languageCode == 'fa';
  String t(String a, String b) => fa ? a : b;
  List<Json> copyRows(String key) => [
    for (final r in objects(widget.row?[key] ?? [])) {...r},
  ];
  Widget text(
    String key,
    String label, {
    Json? target,
    bool required = false,
    int lines = 1,
    int? limit,
    bool secret = false,
    TextInputType? keyboard,
  }) {
    final value = target ?? values;
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '$label${required ? ' *' : ''}',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          TextFormField(
            key: ValueKey('${identityHashCode(value)}:$key'),
            initialValue: '${value[key] ?? ''}',
            maxLines: lines,
            obscureText: secret,
            maxLength: limit,
            keyboardType: keyboard,
            style: const TextStyle(fontSize: 14),
            decoration: const InputDecoration(counterText: ''),
            onChanged: (v) => value[key] = v,
            validator: (v) {
              if (required && (v ?? '').trim().isEmpty)
                return t('این فیلد الزامی است.', 'This field is required.');
              if (key == 'password2' && v != values['password'])
                return t('رمزها یکسان نیستند.', 'Passwords do not match.');
              if (key == 'password' &&
                  widget.row == null &&
                  (v ?? '').length < 8)
                return t(
                  'رمز عبور حداقل ۸ کاراکتر باشد.',
                  'Use at least 8 characters.',
                );
              if (key == 'lat' || key == 'lng') {
                if ((v ?? '').trim().isEmpty) return null;
                final number = double.tryParse(v!);
                final bound = key == 'lat' ? 90 : 180;
                if (number == null || !number.isFinite || number.abs() > bound)
                  return t(
                    'مختصات معتبر وارد کنید.',
                    'Enter valid coordinates.',
                  );
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget select(
    String key,
    String label,
    List<Json> options, {
    Json? target,
    bool required = false,
    bool enabled = true,
    ValueChanged<String>? changed,
  }) {
    final value = target ?? values;
    final selected = '${value[key] ?? ''}';
    // Keep a saved selection even when its catalog entry is no longer available.
    final choices = [
      for (final r in options) {...r},
      if (selected.isNotEmpty && !options.any((r) => '${r['id']}' == selected))
        {'id': selected, 'name': selected},
    ];
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '$label${required ? ' *' : ''}',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            key: ValueKey('${identityHashCode(value)}:$key:$selected'),
            initialValue: selected.isEmpty ? null : selected,
            isExpanded: true,
            style: const TextStyle(fontSize: 14, color: Color(0xff111827)),
            decoration: InputDecoration(hintText: t('انتخاب کنید', 'Select')),
            items: [
              if (!required)
                DropdownMenuItem(
                  value: '',
                  child: Text(t('انتخاب نشده', 'Not selected')),
                ),
              for (final r in choices)
                DropdownMenuItem(
                  value: '${r['id']}',
                  child: Text(
                    '${r['name'] ?? r['title']}',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            validator: (v) => required && (v == null || v.isEmpty)
                ? t('انتخاب این مورد الزامی است.', 'Select an option.')
                : null,
            onChanged: enabled
                ? (v) => setState(() {
                    value[key] = v ?? '';
                    changed?.call(v ?? '');
                  })
                : null,
          ),
        ],
      ),
    );
  }

  List<Json> get priorities => [
    for (final e in {
      'primary': t('اصلی', 'Primary'),
      'secondary': t('فرعی', 'Secondary'),
      'emergency': t('اضطراری', 'Emergency'),
      'ledger': t('دفتر', 'Office'),
      'support': t('پشتیبانی', 'Support'),
      'other': t('سایر', 'Other'),
    }.entries)
      {'id': e.key, 'name': e.value},
  ];
  Widget primary(List<Json> rows, Json row, {bool address = false}) =>
      CheckboxListTile(
        contentPadding: EdgeInsets.zero,
        controlAffinity: ListTileControlAffinity.leading,
        title: Text(
          address ? t('آدرس اصلی', 'Primary address') : t('اصلی', 'Primary'),
          style: const TextStyle(fontSize: 14),
        ),
        value: branchFlag(row['is_main']),
        onChanged: (v) => setState(() {
          if (v == true)
            for (final r in rows) {
              r['is_main'] = false;
            }
          row['is_main'] = v == true;
        }),
      );
  Widget collection(
    String label,
    List<Json> rows,
    Widget Function(Json) fields,
    String add,
    Json defaults,
  ) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        label,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      ),
      const SizedBox(height: 8),
      for (final row in rows)
        Padding(
          key: ObjectKey(row),
          padding: const EdgeInsets.only(bottom: 12),
          child: BranchSurface(
            padding: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                fields(row),
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: IconButton(
                    tooltip: t('حذف', 'Remove'),
                    onPressed: () => setState(() => rows.remove(row)),
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                  ),
                ),
              ],
            ),
          ),
        ),
      Align(
        alignment: AlignmentDirectional.centerStart,
        child: TextButton(
          onPressed: () => setState(() => rows.add({...defaults})),
          child: Text('+ $add'),
        ),
      ),
      const SizedBox(height: 24),
    ],
  );
  Future<void> addType() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => Theme(
        data: branchTheme(context),
        child: BranchForm(api: widget.api, data: widget.data, typesOnly: true),
      ),
    );
    if (result == true) {
      try {
        final updated = await widget.api.get('/branches/list');
        if (mounted)
          setState(() {
            types.clear();
            types.addAll(objects(updated['types'] ?? []));
          });
      } catch (e) {
        if (mounted) socialError(context, e);
      }
    }
  }

  Future<void> save() async {
    if (saving || !form.currentState!.validate()) return;
    if (!widget.typesOnly &&
        widget.row == null &&
        '${values['email'] ?? ''}'.trim().isEmpty &&
        '${values['phone'] ?? ''}'.trim().isEmpty) {
      setState(
        () => error = t(
          'ایمیل یا شماره همراه را وارد کنید.',
          'Enter an email address or mobile number.',
        ),
      );
      return;
    }
    setState(() {
      saving = true;
      error = null;
    });
    try {
      final payload = {
        ...values,
        if (!widget.typesOnly) ...{
          'phones': phones
              .where((r) => '${r['number'] ?? ''}'.trim().isNotEmpty)
              .toList(),
          'links': links
              .where((r) => '${r['url'] ?? ''}'.trim().isNotEmpty)
              .toList(),
          'addresses': addresses,
        },
      };
      await widget.api.act(
        widget.typesOnly ? 'branch-types' : 'branches',
        widget.row == null ? 'create' : 'update',
        params: {if (widget.row != null) 'id': '${widget.row!['id']}'},
        values: payload,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) setState(() => error = '$e');
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provinces = objects(widget.data['provinces'] ?? []);
    final counties = objects(widget.data['counties'] ?? []);
    return BranchDialog(
      title: widget.typesOnly
          ? (widget.row == null
                ? t('افزودن نوع آموزشی', 'Add education type')
                : t('ویرایش نوع آموزشی', 'Edit education type'))
          : (widget.row == null
                ? t('افزودن شعبه جدید', 'Add new branch')
                : t('ویرایش شعبه', 'Edit branch')),
      busy: saving,
      child: AbsorbPointer(
        absorbing: saving,
        child: Form(
          key: form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.typesOnly) ...[
                text('title', t('عنوان', 'Title'), required: true, limit: 100),
                text(
                  'summary',
                  t('خلاصه', 'Summary'),
                  required: true,
                  lines: 2,
                  limit: 500,
                ),
                text(
                  'description',
                  t('شرح', 'Description'),
                  required: true,
                  lines: 5,
                  limit: 5000,
                ),
              ] else ...[
                if (branchFlag(widget.data['site_admin']))
                  select(
                    'academy_id',
                    t('آموزشگاه', 'Academy'),
                    objects(widget.data['academies'] ?? []),
                    required: true,
                    enabled: widget.row == null,
                    changed: (_) => values['manager_user_id'] = '',
                  ),
                text('name', t('نام شعبه', 'Branch name'), required: true),
                select(
                  'type_id',
                  t('نوع آموزشی', 'Education type'),
                  types,
                  required: true,
                ),
                if (branchFlag(widget.data['site_admin']))
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: TextButton(
                      onPressed: addType,
                      child: Text(t('+ نوع جدید', '+ New type')),
                    ),
                  ),
                select('physical_type', t('نوع ارائه', 'Delivery type'), [
                  for (final k in ['physical', 'online', 'hybrid'])
                    {'id': k, 'name': branchMode(k, fa)},
                ], required: true),
                select('status', t('وضعیت', 'Status'), [
                  for (final k in ['active', 'inactive', 'removed'])
                    {
                      'id': k,
                      'name': branchStatus({'status': k}, fa),
                    },
                ]),
                select('manager_user_id', t('مدیر شعبه', 'Branch manager'), [
                  for (final r in objects(
                    widget.data['manager_candidates'] ?? [],
                  ))
                    if ('${r['academy_id']}' == '${values['academy_id']}')
                      {'id': r['user_id'], 'name': r['name']},
                ]),
                if (widget.row == null) ...[
                  text('username', t('نام کاربری', 'Username'), required: true),
                  text(
                    'email',
                    t('ایمیل', 'Email'),
                    keyboard: TextInputType.emailAddress,
                  ),
                  text(
                    'phone',
                    t('شماره همراه', 'Mobile number'),
                    keyboard: TextInputType.phone,
                  ),
                  text(
                    'password',
                    t('رمز عبور', 'Password'),
                    secret: true,
                    required: true,
                  ),
                  text(
                    'password2',
                    t('تکرار رمز عبور', 'Confirm password'),
                    secret: true,
                    required: true,
                  ),
                ],
                text('slogan', t('شعار', 'Slogan')),
                text(
                  'short_description',
                  t('معرفی کوتاه', 'Introduction'),
                  lines: 2,
                  limit: 500,
                ),
                text('bio', t('بیوگرافی', 'Biography'), lines: 3),
                collection(
                  t('شماره‌های تماس', 'Phone numbers'),
                  phones,
                  (r) => Column(
                    children: [
                      text(
                        'number',
                        t('شماره تماس', 'Phone number'),
                        target: r,
                        keyboard: TextInputType.phone,
                      ),
                      select(
                        'priority',
                        t('اولویت', 'Priority'),
                        priorities,
                        target: r,
                      ),
                      primary(phones, r),
                    ],
                  ),
                  t('افزودن شماره', 'Add phone'),
                  {'priority': 'primary', 'is_main': false},
                ),
                collection(
                  t('لینک‌ها', 'Links'),
                  links,
                  (r) => Column(
                    children: [
                      text('title', t('عنوان لینک', 'Link title'), target: r),
                      text(
                        'url',
                        t('آدرس URL', 'URL'),
                        target: r,
                        keyboard: TextInputType.url,
                      ),
                      select('mode', t('نوع', 'Type'), [
                        {
                          'id': 'social',
                          'name': t(
                            'شبکه اجتماعی / کلاس',
                            'Social network / class',
                          ),
                        },
                        {'id': 'email', 'name': t('ایمیل', 'Email')},
                      ], target: r),
                      select('platform', t('شبکه اجتماعی', 'Platform'), [
                        for (final e in {
                          'instagram': 'اینستاگرام',
                          'whats-app': 'واتساپ',
                          'youtube': 'یوتیوب',
                          'telegram': 'تلگرام',
                          'website': 'وب‌سایت',
                          'zoom': 'زوم',
                          'google-meet': 'گوگل میت',
                          'custom': 'سفارشی',
                          'other': 'سایر',
                        }.entries)
                          {'id': e.key, 'name': fa ? e.value : e.key},
                      ], target: r),
                      select(
                        'priority',
                        t('اولویت', 'Priority'),
                        priorities,
                        target: r,
                      ),
                      primary(links, r),
                    ],
                  ),
                  t('افزودن لینک', 'Add link'),
                  {
                    'mode': 'social',
                    'platform': 'website',
                    'priority': 'secondary',
                    'is_main': false,
                  },
                ),
                collection(
                  t('آدرس‌ها', 'Addresses'),
                  addresses,
                  (r) {
                    final province = provinces
                        .where((p) => p['province_name'] == r['province'])
                        .firstOrNull;
                    return Column(
                      children: [
                        select(
                          'province',
                          t('استان', 'Province'),
                          [
                            for (final p in provinces)
                              {
                                'id': p['province_name'],
                                'name': p['province_name'],
                              },
                          ],
                          target: r,
                          changed: (_) => r['city'] = '',
                        ),
                        select(
                          'city',
                          t('شهر', 'City'),
                          [
                            for (final c in counties)
                              if (province != null &&
                                  '${c['province_id']}' ==
                                      '${province['province_id']}')
                                {
                                  'id': c['county_name'],
                                  'name': c['county_name'],
                                },
                          ],
                          target: r,
                          enabled: province != null,
                        ),
                        text(
                          'address',
                          t('ادامه آدرس', 'Street address'),
                          target: r,
                        ),
                        text(
                          'postal_code',
                          t('کد پستی', 'Postal code'),
                          target: r,
                          keyboard: TextInputType.number,
                        ),
                        text(
                          'lat',
                          t('عرض جغرافیایی', 'Latitude'),
                          target: r,
                          keyboard: const TextInputType.numberWithOptions(
                            decimal: true,
                            signed: true,
                          ),
                        ),
                        text(
                          'lng',
                          t('طول جغرافیایی', 'Longitude'),
                          target: r,
                          keyboard: const TextInputType.numberWithOptions(
                            decimal: true,
                            signed: true,
                          ),
                        ),
                        primary(addresses, r, address: true),
                        TextButton.icon(
                          onPressed: () async {
                            final q = '${r['lat'] ?? ''},${r['lng'] ?? ''}';
                            await launchUrl(
                              Uri.https('www.google.com', '/maps/search/', {
                                'api': '1',
                                'query': q == ','
                                    ? '${r['province'] ?? ''} ${r['city'] ?? ''} ${r['address'] ?? ''}'
                                    : q,
                              }),
                              mode: LaunchMode.externalApplication,
                            );
                          },
                          icon: const Icon(Icons.location_on_outlined),
                          label: Text(t('انتخاب روی نقشه', 'Choose on map')),
                        ),
                      ],
                    );
                  },
                  t('افزودن آدرس', 'Add address'),
                  {'is_main': false},
                ),
              ],
              if (error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey,
                      ),
                      onPressed: saving ? null : () => Navigator.pop(context),
                      child: Text(t('انصراف', 'Cancel')),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: saving ? null : save,
                      child: Text(
                        widget.row == null && !widget.typesOnly
                            ? t('افزودن شعبه', 'Add branch')
                            : t('ذخیره تغییرات', 'Save changes'),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
