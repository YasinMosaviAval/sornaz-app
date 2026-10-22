import 'package:flutter/material.dart';
import '../../helpers/app_appearance.dart';

import '../Social/social_widgets.dart';
import 'panel_api.dart';

/// Plain membership request form for the release account page.
class AccountMembershipRequest extends StatefulWidget {
  const AccountMembershipRequest({
    super.key,
    required this.api,
    required this.eligible,
    required this.onChanged,
  });
  final PanelApi api;
  final bool eligible;
  final Future<void> Function() onChanged;
  @override
  State<AccountMembershipRequest> createState() =>
      _AccountMembershipRequestState();
}

class _AccountMembershipRequestState extends State<AccountMembershipRequest> {
  final form = GlobalKey<FormState>();
  final userId = TextEditingController(),
      memberId = TextEditingController(),
      reason = TextEditingController();
  bool saving = false;
  String t(String fa, String en) => socialText(context, fa, en);
  @override
  void dispose() {
    userId.dispose();
    memberId.dispose();
    reason.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (saving || !widget.eligible || !form.currentState!.validate()) return;
    setState(() => saving = true);
    try {
      await widget.api.act(
        'account',
        'merge',
        values: {
          'userId': userId.text.trim(),
          'memberId': memberId.text.trim(),
          'reason': reason.text.trim(),
        },
      );
      await widget.onChanged();
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              t('درخواست برای بررسی ثبت شد.', 'Request submitted for review.'),
            ),
          ),
        );
    } catch (error) {
      if (mounted) socialError(context, error);
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    child: Form(
      key: form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            t(
              'شناسه کاربری و شماره عضویتی را که از آموزشگاه یا شعبه دریافت کرده‌اید وارد کنید. انتقال سوابق فقط پس از بررسی مدیر سایت انجام می‌شود.',
              'Enter the user ID and membership number provided by your academy or branch. Records are transferred only after site administrator review.',
            ),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          for (final field in [
            (userId, t('شناسه کاربری دریافتی', 'Provided user ID')),
            (memberId, t('شماره عضویت', 'Membership number')),
          ]) ...[
            TextFormField(
              controller: field.$1,
              enabled: !saving && widget.eligible,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: field.$2,
                border: OutlineInputBorder(borderRadius: appRadius(context)),
              ),
              validator: (value) => (int.tryParse(value?.trim() ?? '') ?? 0) > 0
                  ? null
                  : t('شناسه معتبر وارد کنید.', 'Enter a valid identifier.'),
            ),
            const SizedBox(height: 12),
          ],
          TextFormField(
            controller: reason,
            enabled: !saving && widget.eligible,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: t('توضیح اختیاری', 'Optional explanation'),
              border: OutlineInputBorder(borderRadius: appRadius(context)),
            ),
          ),
          const SizedBox(height: 12),
          if (!widget.eligible)
            Text(
              t(
                'این بخش فقط برای حساب حقیقی کامل که سابقه ورود ثبت‌شده دارد فعال است.',
                'A complete personal account with recorded login history is required.',
              ),
            ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              shape: RoundedRectangleBorder(borderRadius: appRadius(context)),
            ),
            onPressed: saving || !widget.eligible ? null : submit,
            child: Text(t('ارسال درخواست بررسی', 'Submit for review')),
          ),
        ],
      ),
    ),
  );
}
