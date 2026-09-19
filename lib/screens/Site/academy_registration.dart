import 'package:sornaz/components/scroll_aware_scaffold.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:sornaz/components/app_bar.dart';
import 'package:sornaz/helpers/user_facing_error.dart';
import 'package:sornaz/screens/Authentication/providers/auth_session.dart';
import '../Social/social_widgets.dart';
import 'academy_registration_api.dart';

class AcademyRegistrationCard extends StatelessWidget {
  const AcademyRegistrationCard({super.key});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Padding(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.add_business_outlined, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  socialText(
                    context,
                    'آموزشگاهتان را به سُرناز بیاورید',
                    'Bring your academy to Sornaz',
                  ),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            socialText(
              context,
              'آموزشگاه خود را به جامعه سرناز اضافه کنید. می‌توانید بدون شعبه ثبت‌نام کنید یا شعبه اصلی را هم بسازید؛ افزودن شعبه در آینده نیز امکان‌پذیر است.',
              'Join the Sornaz community with your academy. Register without a branch or create its main branch too; you can add branches later.',
            ),
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            key: const ValueKey('register-academy'),
            icon: const Icon(Icons.add),
            label: Text(
              socialText(
                context,
                'درخواست ثبت آموزشگاه',
                'Register your academy',
              ),
            ),
            onPressed: () {
              final auth = context.read<AuthSession?>();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => AcademyRegistrationPage(
                    token: auth?.token ?? '',
                    userId: auth?.user?.id ?? 0,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    ),
  );
}

class AcademyRegistrationPage extends StatefulWidget {
  const AcademyRegistrationPage({
    super.key,
    this.token = '',
    this.userId = 0,
    this.api,
  });
  final String token;
  final int userId;
  final AcademyRegistrationApi? api;
  @override
  State<AcademyRegistrationPage> createState() =>
      _AcademyRegistrationPageState();
}

class _AcademyRegistrationPageState extends State<AcademyRegistrationPage> {
  late final api =
      widget.api ??
      AcademyRegistrationApi(token: widget.token, userId: widget.userId);
  final formKey = GlobalKey<FormState>();
  final fields = {
    for (final key in [
      'academy_name',
      'username',
      'email',
      'phone',
      'slogan',
      'short_description',
      'biography',
      'password',
      'password2',
    ])
      key: TextEditingController(),
  };
  final code = TextEditingController();
  Map<String, String> pending = {};
  Map<String, dynamic> info = {};
  String phase = 'academy', method = 'email';
  String? error;
  bool loading = true,
      busy = false,
      verifying = false,
      accepted = false,
      showPassword = false;
  DateTime? resendAt, expiresAt;
  Timer? timer;
  String t(String fa, String en) => socialText(context, fa, en);
  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void dispose() {
    timer?.cancel();
    code.dispose();
    for (final controller in fields.values) {
      controller.dispose();
    }
    if (widget.api == null) api.dispose();
    super.dispose();
  }

  Future<void> load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final data = await api.state();
      if (mounted) {
        setState(() {
          info = data;
          phase = data['stage']?.toString() ?? 'academy';
        });
      }
    } catch (e) {
      if (mounted) setState(() => error = message(e));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  String message(Object e) {
    if (e is AcademyRegistrationException) {
      final raw = e.errors.isNotEmpty
          ? e.errors.values.first.toString()
          : e.message;
      if (raw.isNotEmpty) return userFacingError(raw);
    }
    return t(
      'ارتباط برقرار نشد. دوباره تلاش کنید.',
      'Connection failed. Please try again.',
    );
  }

  int get remaining => resendAt == null
      ? 0
      : resendAt!.difference(DateTime.now()).inSeconds.clamp(0, 3600);
  void countdown(int retry, int expires) {
    resendAt = DateTime.now().add(Duration(seconds: retry));
    expiresAt = DateTime.now().add(Duration(seconds: expires));
    timer?.cancel();
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  Future<void> send({bool resend = false}) async {
    FocusScope.of(context).unfocus();
    if (!resend) {
      if (!formKey.currentState!.validate()) return;
      if (!accepted) {
        setState(
          () =>
              error = t('پذیرش قوانین الزامی است.', 'Please accept the terms.'),
        );
        return;
      }
      pending = {
        for (final entry in fields.entries)
          if (entry.key != (method == 'email' ? 'phone' : 'email'))
            entry.key: entry.key.startsWith('password')
                ? entry.value.text
                : entry.value.text.trim(),
        'register_method': method,
        'terms': '1',
      };
    }
    if (info['otp_required'] == false) {
      await finish();
      return;
    }
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final data = await api.sendCode(pending, phase);
      if (mounted) {
        setState(() {
          verifying = true;
          countdown(
            (data['retry_after'] as num?)?.toInt() ?? 60,
            (data['expires_in'] as num?)?.toInt() ?? 120,
          );
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          error = message(e);
          if (e is AcademyRegistrationException && e.retryAfter > 0) {
            countdown(e.retryAfter, 120);
          }
        });
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> finish({bool withoutBranch = false}) async {
    if (!withoutBranch &&
        info['otp_required'] != false &&
        !RegExp(r'^\d{6}$').hasMatch(code.text)) {
      setState(
        () =>
            error = t('کد شش‌رقمی را وارد کنید.', 'Enter the six-digit code.'),
      );
      return;
    }
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final data = withoutBranch
          ? await api.withoutBranch()
          : await api.submit(pending, phase, code.text);
      if (mounted) {
        setState(() {
          info = data;
          phase = data['stage'].toString();
          verifying = false;
          pending = {};
          timer?.cancel();
          code.clear();
          for (final c in fields.values) {
            c.clear();
          }
          accepted = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => error = message(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> terms() => showDialog<void>(
    context: context,
    builder: (c) => AlertDialog(
      title: Text(
        t(
          phase == 'branch'
              ? 'قوانین ثبت و فعالیت شعبه'
              : 'قوانین ثبت و فعالیت آموزشگاه',
          'Registration terms',
        ),
      ),
      content: SingleChildScrollView(
        child: Text(
          (info[phase == 'branch' ? 'branch_terms' : 'terms'] ?? '').toString(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(c),
          child: Text(t('بستن', 'Close')),
        ),
      ],
    ),
  );
  Widget field(
    String key,
    String label, {
    bool required = false,
    int lines = 1,
    int maxLength = 255,
  }) {
    final password = key.startsWith('password');
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        key: ValueKey(key),
        controller: fields[key],
        enabled: !busy,
        maxLines: password ? 1 : lines,
        maxLength: maxLength,
        obscureText: password && !showPassword,
        autocorrect: !password,
        enableSuggestions: !password,
        keyboardType: key == 'email'
            ? TextInputType.emailAddress
            : key == 'phone'
            ? TextInputType.phone
            : lines > 1
            ? TextInputType.multiline
            : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          counterText: '',
          suffixIcon: password
              ? IconButton(
                  onPressed: () => setState(() => showPassword = !showPassword),
                  icon: Icon(
                    showPassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                  ),
                )
              : null,
        ),
        validator: (value) {
          final v = value ?? '';
          if (required && v.trim().isEmpty) {
            return t('این فیلد الزامی است.', 'This field is required.');
          }
          if (key == 'username' &&
              !RegExp(r'^[A-Za-z0-9_]{3,100}$').hasMatch(v.trim())) {
            return t(
              'حداقل ۳ حرف انگلیسی، عدد یا _',
              'Use 3–100 letters, digits or underscores.',
            );
          }
          if (key == 'email' &&
              !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim())) {
            return t('ایمیل معتبر وارد کنید.', 'Enter a valid email.');
          }
          if (key == 'phone' && !RegExp(r'^09\d{9}$').hasMatch(v.trim())) {
            return t(
              'شماره موبایل معتبر وارد کنید.',
              'Enter a valid Iranian mobile number.',
            );
          }
          if (key == 'password' && v.length < 8) {
            return t(
              'رمز باید حداقل ۸ کاراکتر باشد.',
              'Use at least 8 characters.',
            );
          }
          if (key == 'password2' && v != fields['password']!.text) {
            return t('تکرار رمز یکسان نیست.', 'Passwords do not match.');
          }
          return null;
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) => ScrollAwareScaffold(
    appBar: SornazAppBar(
      title: t(
        phase == 'branch' ? 'ثبت شعبه اصلی' : 'ثبت آموزشگاه',
        phase == 'branch' ? 'Register main branch' : 'Register academy',
      ),
    ),
    body: loading
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      error!,
                      key: const ValueKey('registration-error'),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                if (info.isEmpty)
                  FilledButton(
                    onPressed: load,
                    child: Text(t('تلاش دوباره', 'Retry')),
                  )
                else if (phase == 'choice') ...[
                  const Icon(Icons.check_circle_outline, size: 56),
                  const SizedBox(height: 16),
                  Text(
                    t('آموزشگاه شما ثبت شد', 'Your academy is registered'),
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    t(
                      'ایجاد شعبه اختیاری است. می‌توانید بدون شعبه ادامه دهید یا شعبه اصلی را همین حالا ثبت کنید. بعداً هم از پنل کاربری می‌توانید شعبه اضافه کنید.',
                      'Creating a branch is optional. Continue without one or register the main branch now. You can add branches from your panel later.',
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: busy
                        ? null
                        : () => setState(() {
                            phase = 'branch';
                            fields['academy_name']!.text =
                                (info['academy_name'] ?? '').toString() +
                                t(' - شعبه اصلی', ' - Main branch');
                          }),
                    child: Text(t('ثبت شعبه اصلی', 'Register main branch')),
                  ),
                  OutlinedButton(
                    key: const ValueKey('without-branch'),
                    onPressed: busy ? null : () => finish(withoutBranch: true),
                    child: Text(
                      t('ادامه بدون شعبه', 'Continue without a branch'),
                    ),
                  ),
                ] else if (phase == 'complete') ...[
                  const Icon(Icons.check_circle, color: Colors.green, size: 56),
                  const SizedBox(height: 16),
                  Text(
                    t(
                      info['without_branch'] == true
                          ? 'آموزشگاه شما بدون شعبه ثبت شد.'
                          : 'آموزشگاه و شعبه اصلی ثبت شدند.',
                      info['without_branch'] == true
                          ? 'Your academy was registered without a branch.'
                          : 'Your academy and main branch are registered.',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    t(
                      'برای مدیریت آموزشگاه می‌توانید از پنل کاربری استفاده کنید. اگر مهمان هستید، با حساب آموزشگاه وارد شوید.',
                      'Use the user panel to manage your academy. If you registered as a guest, sign in with your academy account.',
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: () async {
                      await api.forget();
                      if (context.mounted) Navigator.pop(context);
                    },
                    child: Text(t('بازگشت به خانه', 'Back to home')),
                  ),
                ] else if (verifying) ...[
                  Text(
                    t(
                      'کد تأیید ارسال‌شده را وارد کنید.',
                      'Enter the verification code.',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(pending[method] ?? '', textDirection: TextDirection.ltr),
                  const SizedBox(height: 16),
                  TextField(
                    key: const ValueKey('registration-otp'),
                    controller: code,
                    keyboardType: TextInputType.number,
                    textDirection: TextDirection.ltr,
                    maxLength: 6,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      labelText: t('کد تأیید', 'Verification code'),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  if (expiresAt != null)
                    Text(
                      t('اعتبار کد: ', 'Code expires in: ') +
                          expiresAt!
                              .difference(DateTime.now())
                              .inSeconds
                              .clamp(0, 120)
                              .toString() +
                          t(' ثانیه', ' seconds'),
                    ),
                  FilledButton(
                    onPressed: busy ? null : finish,
                    child: Text(t('تأیید و ثبت', 'Verify and register')),
                  ),
                  TextButton(
                    onPressed: busy || remaining > 0
                        ? null
                        : () => send(resend: true),
                    child: Text(
                      t('ارسال مجدد کد', 'Resend code') +
                          (remaining > 0 ? ' ($remaining)' : ''),
                    ),
                  ),
                  TextButton(
                    onPressed: busy
                        ? null
                        : () => setState(() {
                            verifying = false;
                            code.clear();
                          }),
                    child: Text(t('تغییر اطلاعات', 'Edit details')),
                  ),
                ] else
                  Form(
                    key: formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          t(
                            phase == 'branch'
                                ? 'شعبه اصلی آموزشگاهتان را ثبت کنید'
                                : 'آموزشگاهتان را به سُرناز بیاورید',
                            phase == 'branch'
                                ? 'Register your main branch'
                                : 'Bring your academy to Sornaz',
                          ),
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          t(
                            phase == 'branch'
                                ? 'اطلاعات و حساب کاربری شعبه را وارد کنید.'
                                : 'آموزشگاه خود را به جامعه سرناز اضافه کنید. ایجاد شعبه اختیاری است.',
                            phase == 'branch'
                                ? 'Enter your branch details and account information.'
                                : 'Join the Sornaz community with your academy. Creating a branch is optional.',
                          ),
                        ),
                        const SizedBox(height: 20),
                        SegmentedButton<String>(
                          segments: [
                            ButtonSegment(
                              value: 'email',
                              label: Text(t('ایمیل', 'Email')),
                              icon: const Icon(Icons.email_outlined),
                            ),
                            ButtonSegment(
                              value: 'phone',
                              label: Text(t('موبایل', 'Mobile')),
                              icon: const Icon(Icons.phone_android),
                            ),
                          ],
                          selected: {method},
                          onSelectionChanged: busy
                              ? null
                              : (v) => setState(() => method = v.first),
                        ),
                        const SizedBox(height: 20),
                        field(
                          method,
                          t(
                            method == 'email' ? 'ایمیل' : 'شماره موبایل',
                            method == 'email' ? 'Email' : 'Mobile number',
                          ),
                          required: true,
                        ),
                        field(
                          'username',
                          t('نام کاربری', 'Username'),
                          required: true,
                          maxLength: 100,
                        ),
                        field(
                          'academy_name',
                          t(
                            phase == 'branch' ? 'نام شعبه' : 'نام آموزشگاه',
                            phase == 'branch' ? 'Branch name' : 'Academy name',
                          ),
                          required: true,
                        ),
                        field('slogan', t('شعار', 'Slogan')),
                        field(
                          'short_description',
                          t('معرفی کوتاه', 'Short introduction'),
                          lines: 2,
                          maxLength: 500,
                        ),
                        field(
                          'biography',
                          t('درباره آموزشگاه', 'About'),
                          lines: 4,
                          maxLength: 5000,
                        ),
                        field(
                          'password',
                          t('رمز عبور', 'Password'),
                          required: true,
                        ),
                        field(
                          'password2',
                          t('تکرار رمز عبور', 'Confirm password'),
                          required: true,
                        ),
                        Row(
                          children: [
                            Checkbox(
                              value: accepted,
                              onChanged: busy
                                  ? null
                                  : (v) =>
                                        setState(() => accepted = v ?? false),
                            ),
                            Expanded(
                              child: Text(
                                t(
                                  'قوانین ثبت و فعالیت را می‌پذیرم.',
                                  'I accept the registration terms.',
                                ),
                              ),
                            ),
                          ],
                        ),
                        TextButton(
                          onPressed: terms,
                          child: Text(t('مطالعه قوانین', 'Read terms')),
                        ),
                        FilledButton(
                          key: const ValueKey('send-registration-code'),
                          onPressed: busy ? null : send,
                          child: Text(
                            info['otp_required'] == false
                                ? t('ثبت', 'Register')
                                : t(
                                    'دریافت کد تأیید',
                                    'Send verification code',
                                  ),
                          ),
                        ),
                        if (phase == 'branch')
                          TextButton(
                            onPressed: busy
                                ? null
                                : () => setState(() => phase = 'choice'),
                            child: Text(
                              t(
                                'بازگشت به انتخاب وضعیت شعبه',
                                'Back to branch options',
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                if (busy)
                  const Padding(
                    padding: EdgeInsets.only(top: 16),
                    child: LinearProgressIndicator(),
                  ),
              ],
            ),
          ),
  );
}
