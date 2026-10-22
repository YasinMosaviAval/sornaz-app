import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../../helpers/app_appearance.dart';
import '../Social/social_api.dart';
import '../Social/social_widgets.dart';
import 'panel_api.dart';
import 'site_api.dart';
import '../../components/settings_section_header.dart';
import '../../helpers/account_presentation.dart';

/// Native rendering of sections/account.php and account-templates.js.
class PanelAccount extends StatefulWidget {
  const PanelAccount({
    super.key,
    required this.api,
    required this.data,
    required this.actions,
    required this.onAction,
    required this.onChanged,
    this.area,
  });
  final PanelApi api;
  final Json data, actions;
  final String? area;
  final Future<void> Function(String, Json) onAction;
  final Future<void> Function() onChanged;
  @override
  State<PanelAccount> createState() => _PanelAccountState();
}

class _PanelAccountState extends State<PanelAccount> {
  Json get profile => optionalObject(widget.data['profile']);
  late Json privacy = {...optionalObject(profile['privacy'])};
  final security = <String, String>{};
  final merge = <String, String>{};
  Json invite = {};
  bool saving = false,
      verifying = false,
      inviteFailed = false,
      inviteLoading = false;
  String t(String fa, String en) => socialText(context, fa, en);
  @override
  void initState() {
    super.initState();
    invite = optionalObject(widget.data['invite']);
    if (widget.area == null) loadInvite();
  }

  Future<void> loadInvite() async {
    if (inviteLoading) return;
    setState(() => inviteLoading = true);
    try {
      final result = await widget.api.get('/account/invite');
      if (mounted)
        setState(() {
          invite = result;
          inviteFailed = false;
        });
    } catch (_) {
      if (mounted) setState(() => inviteFailed = true);
    } finally {
      if (mounted) setState(() => inviteLoading = false);
    }
  }

  Future<void> save(String action, Json values) async {
    if (saving) return;
    setState(() => saving = true);
    try {
      await widget.api.act('account', action, values: values);
      await widget.onChanged();
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t('تغییرات ذخیره شد.', 'Changes saved.'))),
        );
    } catch (error) {
      if (mounted) socialError(context, error);
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Widget action(
    String key,
    String fa,
    String en, {
    Json row = const {},
    IconData? icon,
    bool filled = false,
  }) {
    if (!widget.actions.containsKey(key)) return const SizedBox.shrink();
    if (filled)
      return FilledButton.icon(
        onPressed: saving ? null : () => widget.onAction(key, row),
        icon: Icon(icon ?? Icons.edit_outlined),
        label: Text(t(fa, en)),
      );
    return TextButton.icon(
      onPressed: saving ? null : () => widget.onAction(key, row),
      icon: Icon(icon ?? Icons.edit_outlined),
      label: Text(t(fa, en)),
    );
  }

  Widget card(
    String fa,
    String en,
    List<Widget> children, {
    Widget? trailing,
  }) =>
      ((widget.area != null &&
              [
                'Connected devices',
                'Documents',
                'Login and logout history',
                'Security alerts',
              ].contains(en)) ||
          (AccountPresentation.restricted(context) &&
              en == 'Link membership records to my account'))
      ? Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (trailing != null)
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: trailing,
                ),
              ...children,
            ],
          ),
        )
      : Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: SettingsSectionHeader(
            key: ValueKey('account-section-$en'),
            title: t(fa, en),
            initiallyExpanded: false,
            topSpacing: 0,
            children: [
              Padding(
                padding: const EdgeInsets.all(24),
                child: Material(
                  type: MaterialType.transparency,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (trailing != null)
                        Align(
                          alignment: AlignmentDirectional.centerEnd,
                          child: trailing,
                        ),
                      ...children,
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
  Widget value(String label, dynamic value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                '${value ?? ''}'.isEmpty ? '—' : '$value',
                textAlign: TextAlign.end,
              ),
            ),
          ],
        ),
        const Divider(height: 16),
      ],
    ),
  );
  Widget empty(String fa, String en) => Padding(
    padding: const EdgeInsets.all(16),
    child: Text(t(fa, en), style: Theme.of(context).textTheme.bodySmall),
  );
  Widget biographyValue(String label, dynamic content) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Text('${content ?? ''}'.isEmpty ? '—' : '$content'),
      ],
    ),
  );
  Widget field(
    String key,
    String fa,
    String en,
    Map<String, String> values, {
    String? initial,
    String? hint,
    bool password = false,
    bool multiline = false,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: TextFormField(
      key: ValueKey('account-$key'),
      initialValue: values[key] ?? initial,
      obscureText: password,
      maxLines: multiline ? 3 : 1,
      onChanged: (v) => values[key] = v,
      decoration: InputDecoration(
        labelText: t(fa, en),
        hintText: hint,
        border: OutlineInputBorder(borderRadius: appRadius(context)),
      ),
    ),
  );
  Widget image(String key, {bool avatar = false}) {
    final url = '${profile[key] ?? ''}';
    return url.isEmpty
        ? Icon(
            avatar ? Icons.music_note : Icons.image_outlined,
            size: avatar ? 40 : 48,
          )
        : Image.network(
            SiteApi.origin.resolve(url).toString(),
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            errorBuilder: (_, error, stack) =>
                Icon(avatar ? Icons.music_note : Icons.image_outlined),
          );
  }

  Widget header() => Card(
    margin: const EdgeInsets.only(bottom: 24),
    clipBehavior: Clip.antiAlias,
    shape: RoundedRectangleBorder(borderRadius: appRadius(context)),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AspectRatio(
          aspectRatio: 16 / 9,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ColoredBox(
                color: Theme.of(context).colorScheme.primaryContainer,
                child: profile['coverUrl']?.toString().isNotEmpty == true
                    ? image('coverUrl')
                    : Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.image_outlined, size: 40),
                            Text(
                              t(
                                'کاور پروفایل ${profile['entityLabel'] ?? 'حساب'}',
                                'Account profile cover',
                              ),
                            ),
                            Text(
                              t(
                                'قالب پیشنهادی ۱۹۲۰×۱۰۸۰ (۱۶:۹ افقی)',
                                'Suggested: 1920×1080 (16:9 landscape)',
                              ),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
              ),
              Positioned(
                top: 12,
                left: 12,
                right: 12,
                child: Wrap(
                  children: [
                    action(
                      'cover',
                      'تغییر کاور',
                      'Change cover',
                      icon: Icons.camera_alt_outlined,
                    ),
                    if (profile['coverId'] != null)
                      action(
                        'delete-media',
                        'حذف کاور',
                        'Remove cover',
                        row: {'id': profile['coverId']},
                        icon: Icons.delete_outline,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(24),
          child: LayoutBuilder(
            builder: (context, size) {
              final avatar = SizedBox(
                width: 112,
                height: 120,
                child: Stack(
                  children: [
                    Positioned.fill(
                      bottom: 8,
                      child: ClipOval(
                        child: ColoredBox(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          child: image('avatarUrl', avatar: true),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      child: IconButton.filled(
                        tooltip: t('تغییر عکس پروفایل', 'Change avatar'),
                        onPressed: widget.actions.containsKey('avatar')
                            ? () => widget.onAction('avatar', const {})
                            : null,
                        icon: const Icon(Icons.camera_alt_outlined),
                      ),
                    ),
                  ],
                ),
              );
              final name = Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerLow,
                  borderRadius: appRadius(context),
                ),
                child: Column(
                  children: [
                    Text(
                      '${profile['name'] ?? ''}',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Text('${profile['type'] ?? ''}'),
                    const SizedBox(height: 8),
                    Text('${profile['shortIntro'] ?? '—'}', maxLines: 2),
                  ],
                ),
              );
              final edit = action(
                'profile',
                'ویرایش پروفایل',
                'Edit profile',
                filled: true,
              );
              return size.maxWidth < 600
                  ? Column(
                      children: [
                        avatar,
                        const SizedBox(height: 16),
                        SizedBox(width: double.infinity, child: name),
                        edit,
                      ],
                    )
                  : Row(
                      children: [
                        avatar,
                        const SizedBox(width: 16),
                        Expanded(child: name),
                        edit,
                      ],
                    );
            },
          ),
        ),
      ],
    ),
  );
  Widget information() {
    final human = profile['accountType'] == 'human';
    final rows = <Widget>[
      value(t('نام', 'Name'), profile['name']),
      if (!human) value(t('مدیر مسئول', 'Manager'), profile['manager']),
      value(t('ایمیل', 'Email'), profile['email']),
      value(t('تلفن', 'Phone'), profile['phone']),
      value(t('آدرس', 'Address'), profile['address']),
      value(
        human ? t('تاریخ تولد', 'Date of birth') : t('سال تأسیس', 'Founded'),
        profile['founded'],
      ),
      if (!human) ...[
        value(
          profile['accountType'] == 'branch'
              ? t('نوع حساب', 'Account type')
              : t('تعداد شعبه‌ها', 'Branches'),
          profile['accountType'] == 'branch'
              ? t('شعبه', 'Branch')
              : profile['branches'] ?? 0,
        ),
        value(t('تعداد هنرجویان', 'Students'), profile['students'] ?? 0),
        value(t('تعداد اساتید', 'Teachers'), profile['teachers'] ?? 0),
      ],
    ];
    return card('اطلاعات اصلی', 'Main information', [
      LayoutBuilder(
        builder: (context, size) => Wrap(
          spacing: 20,
          children: [
            for (final row in rows)
              SizedBox(
                width: size.maxWidth < 650
                    ? size.maxWidth
                    : (size.maxWidth - 20) / 2,
                child: row,
              ),
          ],
        ),
      ),
    ]);
  }

  Widget privacyCard() {
    final type = profile['accountType'];
    final options = <(String, String, String)>[
      (
        'showPublicProfile',
        'نمایش پروفایل عمومی در وبسایت',
        'Show public profile on the website',
      ),
      if (type == 'academy')
        (
          'showBranches',
          'نمایش لیست شعبه‌ها در صفحه عمومی',
          'Show branches on the public page',
        ),
      if (type != 'human') ...[
        (
          'showTeachers',
          'نمایش اساتید در صفحه عمومی',
          'Show teachers on the public page',
        ),
        (
          'showStats',
          'نمایش آمار (تعداد هنرجو / کلاس)',
          'Show statistics (students / classes)',
        ),
      ],
      (
        'showContact',
        'نمایش اطلاعات تماس عمومی',
        'Show public contact details',
      ),
      (
        'indexable',
        'اجازه ایندکس شدن در موتورهای جستجو',
        'Allow search engine indexing',
      ),
    ];
    return card('حریم خصوصی و نمایش عمومی', 'Privacy and public visibility', [
      for (final option in options)
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(t(option.$2, option.$3)),
          value: privacy[option.$1] == true,
          onChanged: widget.actions.containsKey('privacy')
              ? (v) => setState(() => privacy[option.$1] = v)
              : null,
        ),
      if (widget.actions.containsKey('privacy'))
        FilledButton(
          onPressed: saving ? null : () => save('privacy', privacy),
          child: Text(t('ذخیره تنظیمات حریم خصوصی', 'Save privacy settings')),
        ),
    ]);
  }

  Future<void> saveSecurity() async {
    if (saving || verifying) return;
    final password = security['password'] ?? '';
    if (password.isNotEmpty &&
        (password.length < 8 || password != security['passwordConfirmation'])) {
      socialError(
        context,
        t(
          'رمز عبور باید حداقل ۸ کاراکتر و با تکرار آن یکسان باشد.',
          'Passwords must match and have at least 8 characters.',
        ),
      );
      return;
    }
    setState(() => verifying = true);
    try {
      for (final channel in ['email', 'phone']) {
        final target = (security[channel] ?? '${profile[channel] ?? ''}')
            .trim();
        if (target == '${profile[channel] ?? ''}') continue;
        await widget.api.act(
          'account',
          'contact-send',
          values: {'field': channel, 'destination': target},
        );
        if (!mounted) return;
        var code = '';
        final result = await showDialog<String>(
          context: context,
          builder: (c) => AlertDialog(
            title: Text(t('کد تأیید', 'Verification code')),
            content: TextField(
              onChanged: (value) => code = value,
              keyboardType: TextInputType.number,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(c),
                child: Text(t('انصراف', 'Cancel')),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(c, code),
                child: Text(t('تأیید', 'Verify')),
              ),
            ],
          ),
        );
        if (result == null) return;
        await widget.api.act(
          'account',
          'contact-verify',
          values: {'field': channel, 'destination': target, 'code': result},
        );
        await widget.api.act(
          'account',
          'contact-commit',
          values: {'field': channel, 'destination': target},
        );
      }
      await save('security', {
        'password': password,
        'passwordConfirmation': security['passwordConfirmation'] ?? '',
      });
      if (mounted)
        setState(() {
          security.clear();
        });
    } catch (error) {
      if (mounted) socialError(context, error);
    } finally {
      if (mounted) setState(() => verifying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final area = widget.area;
    bool show(String key) => area == null || area == key;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (area == null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                t(
                  'مدیریت پروفایل، امنیت، حریم خصوصی و پشتیبان‌گیری',
                  'Manage profile, security, privacy and backups',
                ),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            header(),
            information(),
            card('لینک دعوت من', 'My invitation link', [
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: .1),
                    borderRadius: appRadius(context),
                  ),
                  child: Text(
                    t(
                      '${invite['invitedUsers'] ?? '—'} کاربر دعوت‌شده',
                      '${invite['invitedUsers'] ?? '—'} invited users',
                    ),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                t(
                  'این لینک اختصاصی را برای معرفی سرناز ارسال کنید. امتیازها و تخفیف‌های دعوت در آینده بر اساس همین کد محاسبه می‌شوند.',
                  'Share this personal link to introduce Sornaz. Future referral points and discounts will use this code.',
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                key: ValueKey('invite-${invite['url']}'),
                readOnly: true,
                initialValue: '${invite['url'] ?? ''}',
                textDirection: TextDirection.ltr,
                textAlign: TextAlign.left,
                decoration: InputDecoration(
                  hintText: inviteLoading
                      ? t('در حال دریافت...', 'Loading...')
                      : t(
                          'لینک دعوت دریافت نشد.',
                          'Invitation link could not be loaded.',
                        ),
                  border: OutlineInputBorder(borderRadius: appRadius(context)),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surfaceContainerLow,
                ),
              ),
              Wrap(
                children: [
                  TextButton.icon(
                    onPressed: invite['url'] == null
                        ? null
                        : () => Clipboard.setData(
                            ClipboardData(text: '${invite['url']}'),
                          ),
                    icon: const Icon(Icons.copy),
                    label: Text(t('کپی لینک', 'Copy link')),
                  ),
                  TextButton.icon(
                    onPressed: invite['url'] == null
                        ? null
                        : () => Share.share('${invite['url']}'),
                    icon: const Icon(Icons.share_outlined),
                    label: Text(t('اشتراک‌گذاری', 'Share')),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                t(
                  'کد اختصاصی: ${invite['code'] ?? '—'}',
                  'Personal code: ${invite['code'] ?? '—'}',
                ),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              if (inviteFailed)
                TextButton(
                  onPressed: loadInvite,
                  child: Text(t('تلاش دوباره', 'Retry')),
                ),
            ]),
          ],
          if (AccountPresentation.restricted(context) &&
              show('merges.requests'))
            card(
              'اتصال سوابق عضویت به حساب من',
              'Link membership records to my account',
              [
                Text(
                  t(
                    'شناسه کاربری و شماره عضویتی را که از آموزشگاه یا شعبه دریافت کرده‌اید وارد کنید. انتقال سوابق فقط پس از بررسی مدیر سایت انجام می‌شود.',
                    'Enter the user ID and membership number provided by your academy or branch. Records are transferred only after site administrator review.',
                  ),
                ),
                const SizedBox(height: 16),
                field(
                  'userId',
                  'شناسه کاربری دریافتی',
                  'Provided user ID',
                  merge,
                ),
                field('memberId', 'شماره عضویت', 'Membership number', merge),
                field(
                  'reason',
                  'توضیح اختیاری',
                  'Optional explanation',
                  merge,
                  multiline: true,
                ),
                if (optionalObject(widget.data['merges'])['eligible'] == false)
                  empty(
                    'این بخش فقط برای حساب حقیقی کامل که سابقه ورود ثبت‌شده دارد فعال است.',
                    'A complete personal account with recorded login history is required.',
                  ),
                for (final row in objects(
                  optionalObject(widget.data['merges'])['requests'] ?? [],
                )) ...[
                  value(
                    t('وضعیت درخواست', 'Request status'),
                    {
                          'pending': t('در انتظار بررسی', 'Pending review'),
                          'approved': t('تأیید شده', 'Approved'),
                          'rejected': t('رد شده', 'Rejected'),
                          'cancelled': t('لغو شده', 'Cancelled'),
                        }['${row['status']}'] ??
                        row['status'],
                  ),
                  action(
                    'cancel-merge',
                    'لغو درخواست',
                    'Cancel request',
                    row: row,
                  ),
                  action(
                    'decide-merge',
                    'بررسی درخواست',
                    'Review request',
                    row: row,
                  ),
                ],
                if (widget.actions.containsKey('merge'))
                  FilledButton(
                    onPressed:
                        saving ||
                            optionalObject(widget.data['merges'])['eligible'] !=
                                true
                        ? null
                        : () => save('merge', merge),
                    child: Text(
                      t('ارسال درخواست ادغام', 'Submit merge request'),
                    ),
                  ),
              ],
            ),
          if (area == null)
            card('معرفی و بیوگرافی', 'Introduction and biography', [
              biographyValue(
                t('معرفی کوتاه', 'Short introduction'),
                profile['shortIntro'],
              ),
              biographyValue(
                t('بیوگرافی کامل', 'Full biography'),
                profile['biography'],
              ),
            ], trailing: action('bio', 'ویرایش', 'Edit')),
          if (show('documents'))
            card(
              'اسناد',
              'Documents',
              [
                Text(
                  t(
                    'فرمت‌های مجاز: PDF، JPG/JPEG، PNG، WebP و DOCX؛ حداکثر حجم هر فایل ۲۰ مگابایت.',
                    'Allowed: PDF, JPG/JPEG, PNG, WebP, DOCX. Maximum 20 MB per file.',
                  ),
                ),
                if (objects(widget.data['documents'] ?? []).isEmpty)
                  empty('سندی ثبت نشده', 'No documents'),
                for (final row in objects(widget.data['documents'] ?? []))
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('${row['title'] ?? row['name'] ?? ''}'),
                      Text('${row['documentType'] ?? row['type'] ?? ''}'),
                      Wrap(
                        children: [
                          action(
                            'download-media',
                            'دانلود',
                            'Download',
                            row: row,
                            icon: Icons.download,
                          ),
                          action(
                            'delete-media',
                            'حذف',
                            'Delete',
                            row: row,
                            icon: Icons.delete_outline,
                          ),
                        ],
                      ),
                    ],
                  ),
              ],
              trailing: action(
                'document',
                'آپلود سند',
                'Upload document',
                icon: Icons.upload,
              ),
            ),
          if (show('devices'))
            card('دستگاه‌های متصل', 'Connected devices', [
              if (objects(widget.data['devices'] ?? []).isEmpty)
                empty('دستگاهی ثبت نشده', 'No devices recorded'),
              for (final row in objects(widget.data['devices'] ?? []))
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      '${row['name'] ?? ''} ${row['current'] == true ? t('(دستگاه فعلی)', '(Current device)') : ''}',
                    ),
                    Text(
                      '${row['location'] ?? ''} · ${row['ip'] ?? ''} · ${row['lastActive'] ?? ''}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    if (row['current'] != true)
                      action(
                        'end-session',
                        'خروج دستگاه',
                        'Sign out device',
                        row: row,
                        icon: Icons.logout,
                      ),
                    const Divider(),
                  ],
                ),
              if (objects(
                    widget.data['devices'] ?? [],
                  ).any((r) => r['current'] != true) &&
                  widget.actions.containsKey('end-session'))
                TextButton(
                  onPressed: saving
                      ? null
                      : () async {
                          for (final row in objects(
                            widget.data['devices'] ?? [],
                          ).where((r) => r['current'] != true)) {
                            await widget.onAction('end-session', row);
                          }
                        },
                  child: Text(
                    t(
                      'خروج از همه دستگاه‌های دیگر',
                      'Sign out all other devices',
                    ),
                  ),
                ),
            ]),
          if (show('loginHistory'))
            card('تاریخچه ورود و خروج', 'Login and logout history', [
              if (objects(widget.data['loginHistory'] ?? []).isEmpty)
                empty('موردی نیست', 'No records'),
              for (final row in objects(widget.data['loginHistory'] ?? []))
                value(
                  '${row['action'] ?? ''} · ${row['device'] ?? ''}\n${row['ip'] ?? ''}',
                  row['date'],
                ),
            ]),
          if (show('securityAlerts'))
            card('هشدارهای امنیتی', 'Security alerts', [
              if (objects(widget.data['securityAlerts'] ?? []).isEmpty)
                empty('هشداری نیست', 'No alerts'),
              for (final row in objects(widget.data['securityAlerts'] ?? []))
                ListTile(
                  title: Text('${row['title'] ?? ''}'),
                  subtitle: Text('${row['text'] ?? ''}\n${row['date'] ?? ''}'),
                  leading: Icon(
                    Icons.security,
                    color: row['level'] == 'danger'
                        ? Colors.red
                        : Theme.of(context).colorScheme.primary,
                  ),
                ),
            ]),
          if (show('privacy')) privacyCard(),
          if (show('security') && widget.actions.containsKey('security'))
            card('تنظیمات امنیتی حساب', 'Account security settings', [
              field(
                'email',
                'ایمیل مدیریت',
                'Management email',
                security,
                initial: '${profile['email'] ?? ''}',
              ),
              field(
                'phone',
                'شماره تماس اصلی',
                'Primary phone',
                security,
                initial: '${profile['phone'] ?? ''}',
              ),
              field(
                'password',
                'رمز عبور جدید',
                'New password',
                security,
                password: true,
                hint: t(
                  'در صورت نیاز به تغییر',
                  'Only if you need to change it',
                ),
              ),
              field(
                'passwordConfirmation',
                'تکرار رمز عبور',
                'Confirm password',
                security,
                password: true,
                hint: t('تکرار رمز جدید', 'Repeat the new password'),
              ),
              FilledButton(
                onPressed: saving || verifying ? null : saveSecurity,
                child: Text(t('ذخیره تغییرات', 'Save changes')),
              ),
            ]),
          if (show('documents') && widget.actions.containsKey('backup'))
            card('خروجی اطلاعات', 'Export information', [
              Text(
                t(
                  'اطلاعات حساب خود را به‌صورت JSON، بدون رمزها و توکن‌های ورود دریافت کنید. محتوای فایل‌های بارگذاری‌شده در این خروجی نیست.',
                  'Export account records as JSON without passwords or authentication tokens. Uploaded file contents are not included.',
                ),
              ),
              action(
                'backup',
                'ایجاد خروجی اطلاعات',
                'Create export',
                icon: Icons.backup_outlined,
              ),
              if (widget.data['backup'] is Map)
                action(
                  'download-backup',
                  'دانلود آخرین خروجی',
                  'Download latest export',
                  row: optionalObject(widget.data['backup']),
                  icon: Icons.download,
                ),
            ]),
        ],
      ),
    );
  }
}
