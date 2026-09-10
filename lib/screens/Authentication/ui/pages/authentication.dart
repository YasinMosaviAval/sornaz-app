import 'package:flutter/material.dart';
import 'registration_feedback.dart';
import '../../services/saved_credentials.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:sornaz/helpers/app_colors.dart';
import 'package:sornaz/helpers/app_data.dart';
import 'package:sornaz/components/app_logo.dart';
import 'package:sornaz/helpers/app_locale_provider.dart';
import 'package:sornaz/helpers/app_strings.dart';
import 'package:sornaz/helpers/app_translations.dart';
import 'package:sornaz/screens/Home/ui/pages/home.dart';
import 'package:sornaz/screens/Authentication/providers/auth_session.dart';
import 'package:sornaz/screens/Authentication/services/auth_api_service.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});
  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  bool remember = false;
  bool hidden = true;
  bool loading = false;
  String? error;
  final identifier = TextEditingController();
  final password = TextEditingController();
  final api = AuthApiService();
  final credentials = SavedCredentials();
  bool choosingCredential = false;

  Future<void> chooseCredential() async {
    if (choosingCredential || loading) return;
    choosingCredential = true;
    try {
      final entries = await credentials.available(
        context.read<AuthSession>().accounts.map((e) => e.id).toSet(),
      );
      if (!mounted || entries.isEmpty) return;
      final en = context.read<LocaleProvider>().locale.languageCode == 'en';
      final selected = await showModalBottomSheet<SavedCredential>(
        context: context,
        isScrollControlled: true,
        builder: (context) => SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.key, size: 40),
                const SizedBox(height: 16),
                Text(
                  en
                      ? 'Use saved password?'
                      : 'از رمز عبور ذخیره‌شده استفاده شود؟',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                Text(SavedCredentials.site),
                const SizedBox(height: 20),
                for (final entry in entries)
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.account_circle_outlined),
                      title: Text(
                        entry.identifier,
                        textDirection: TextDirection.ltr,
                      ),
                      subtitle: const Text(
                        '••••••••',
                        semanticsLabel: 'رمز عبور ذخیره‌شده',
                      ),
                      onTap: () => Navigator.pop(context, entry),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
      if (!mounted || selected == null) return;
      setState(() {
        identifier.text = selected.identifier;
        password.text = selected.password;
        remember = true;
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('خواندن اطلاعات ورود ذخیره‌شده ممکن نشد.'),
          ),
        );
      }
    } finally {
      choosingCredential = false;
    }
  }

  @override
  void dispose() {
    identifier.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> login() async {
    if (identifier.text.trim().isEmpty || password.text.isEmpty) {
      setState(
        () => error =
            'نام کاربری، ایمیل یا شماره موبایل و رمز عبور را وارد کنید.',
      );
      return;
    }
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final result = await api.login(
        identifier: identifier.text.trim(),
        password: password.text,
        remember: remember,
      );
      if (!mounted) return;
      try {
        await credentials.update(
          SavedCredential(
            result.user.id,
            identifier.text.trim(),
            password.text,
          ),
          remember: remember,
        );
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ذخیره اطلاعات ورود ممکن نشد.')),
          );
        }
      }
      if (!mounted) return;
      await context.read<AuthSession>().save(result);
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomePage()),
        (_) => false,
      );
    } catch (e) {
      if (mounted) {
        setState(
          () => error = e is AuthApiException
              ? e.message
              : 'ارتباط با سرور برقرار نشد.',
        );
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final en = context.watch<LocaleProvider>().locale.languageCode == 'en';
    return _AuthPage(
      spacedSections: true,
      children: [
        Column(
          children: [
            _Header(title: AppStrings.sign_in_title.translate(context)),
            const SizedBox(height: 18),
            Text(
              AppStrings.sign_in_description.translate(context),
              textAlign: TextAlign.center,
              style: _muted(context).copyWith(fontSize: 16, height: 1.35),
            ),
          ],
        ),
        Column(
          children: [
            _Field(
              label: en
                  ? 'Username, email or mobile'
                  : 'نام کاربری، ایمیل یا موبایل',
              controller: identifier,
              onTap: chooseCredential,
            ),
            const SizedBox(height: 16),
            _Field(
              label: AppStrings.password.translate(context),
              controller: password,
              obscure: hidden,
              suffix: IconButton(
                onPressed: () => setState(() => hidden = !hidden),
                icon: Icon(
                  hidden
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: InkWell(
                    onTap: () => setState(() => remember = !remember),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: Checkbox(
                            value: remember,
                            onChanged: (v) =>
                                setState(() => remember = v ?? false),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            AppStrings.remember_me.translate(context),
                            style: _muted(context).copyWith(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Flexible(
                  child: Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: TextButton(
                      style: TextButton.styleFrom(padding: EdgeInsets.zero),
                      onPressed: () {},
                      child: Text(
                        AppStrings.forgot_password.translate(context),
                        style: const TextStyle(fontSize: 12),
                        textAlign: TextAlign.end,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (error != null) ...[
              Text(
                error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.error, fontSize: 13),
              ),
              const SizedBox(height: 10),
            ],
            _MainButton(
              label: AppStrings.sign_in_title.translate(context),
              onPressed: loading ? null : login,
              loading: loading,
            ),
            const SizedBox(height: 12),
            _Prompt(
              prefix: en ? "Don’t have an account?" : 'حساب کاربری ندارید؟',
              action: AppStrings.sign_up_title.translate(context),
              onTap: () => Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const SignUpScreen())),
            ),
          ],
        ),
        TextButton(
          onPressed: () => _continueAsGuest(context),
          child: Text(
            context.watch<AuthSession>().isAuthenticated
                ? (en ? 'Continue with current account' : 'ادامه با حساب فعلی')
                : (en ? 'Continue as guest' : 'ادامه بدون ورود'),
          ),
        ),
      ],
    );
  }
}

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key, this.api});
  final AuthApiService? api;
  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  bool hidden = true;
  bool confirmHidden = true;
  bool phoneMethod = false;
  bool terms = false;
  bool loading = false;
  String? error;
  final fullName = TextEditingController();
  final username = TextEditingController();
  final contact = TextEditingController();
  final password = TextEditingController();
  final confirmation = TextEditingController();
  late final api = widget.api ?? AuthApiService();

  @override
  void dispose() {
    fullName.dispose();
    username.dispose();
    contact.dispose();
    password.dispose();
    confirmation.dispose();
    super.dispose();
  }

  Map<String, String> get form {
    final value = contact.text.trim();
    final phone = phoneMethod;
    return {
      'register_method': phone ? 'phone' : 'email',
      'email': phone ? '' : value,
      'phone': phone ? normalizeRegistrationPhone(value) : '',
      'username': username.text.trim(),
      'full_name': fullName.text.trim(),
      'password': password.text,
      'password2': confirmation.text,
      'terms': terms ? '1' : '',
      'locale': context.read<LocaleProvider>().locale.languageCode,
    };
  }

  Future<void> register() async {
    if (username.text.trim().isEmpty ||
        contact.text.trim().isEmpty ||
        password.text.isEmpty) {
      setState(() => error = 'auth.required'.translate(context));
      return;
    }
    final input = contact.text.trim();
    final validContact = phoneMethod
        ? RegExp(r'^09[0-9]{9}$').hasMatch(normalizeRegistrationPhone(input))
        : RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(input);
    if (!validContact) {
      setState(
        () =>
            error = (phoneMethod ? 'auth.invalid_phone' : 'auth.invalid_email')
                .translate(context),
      );
      return;
    }
    if (!validRegistrationUsername(username.text)) {
      setState(() => error = 'auth.username_invalid'.translate(context));
      return;
    }
    if (password.text.length < 8 ||
        registrationPasswordCriteria(password.text).where((v) => v).length <
            3) {
      setState(() => error = 'auth.weak_password'.translate(context));
      return;
    }
    if (password.text != confirmation.text) {
      setState(() => error = 'auth.password_mismatch'.translate(context));
      return;
    }
    if (!terms) {
      setState(() => error = 'auth.terms_required'.translate(context));
      return;
    }
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final submittedForm = form;
      await api.sendRegistrationOtp(submittedForm);
      if (!mounted) return;
      final otp = await _askForOtp(
        submittedForm[submittedForm['register_method']]!,
      );
      if (otp == null || !mounted) return;
      final result = await api.register(submittedForm, otp);
      if (!mounted) return;
      await context.read<AuthSession>().save(result);
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomePage()),
        (_) => false,
      );
    } catch (e) {
      if (mounted) {
        setState(
          () => error = e is AuthApiException
              ? e.message
              : 'ارتباط با سرور برقرار نشد.',
        );
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<String?> _askForOtp(String destination) async {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _OtpDialog(destination: destination),
    );
  }

  Future<void> _showTerms() async {
    final accepted = await showDialog<bool>(
      context: context,
      builder: (_) => const _TermsDialog(),
    );
    if (accepted == true && mounted) setState(() => terms = true);
  }

  @override
  Widget build(BuildContext context) {
    final en = context.watch<LocaleProvider>().locale.languageCode == 'en';
    return _AuthPage(
      children: [
        _Header(title: 'auth.register_title'.translate(context)),
        const SizedBox(height: 18),
        Text(
          'auth.register_intro'.translate(context),
          textAlign: TextAlign.center,
          style: _muted(context).copyWith(fontSize: 16),
        ),
        const SizedBox(height: 34),
        _Field(
          label: en ? 'Full name' : 'نام و نام خانوادگی',
          controller: fullName,
        ),
        const SizedBox(height: 12),
        _Field(label: en ? 'Username' : 'نام کاربری', controller: username),
        UsernameFeedback(controller: username),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            for (final phone in [false, true])
              ChoiceChip(
                showCheckmark: false,
                label: Text(
                  (phone ? 'auth.phone_method' : 'auth.email_method').translate(
                    context,
                  ),
                ),
                avatar: Icon(
                  phone ? Icons.phone_android : Icons.email_outlined,
                  size: 18,
                ),
                selected: phoneMethod == phone,
                onSelected: loading
                    ? null
                    : (_) => setState(() {
                        phoneMethod = phone;
                        contact.clear();
                        error = null;
                      }),
              ),
          ],
        ),
        const SizedBox(height: 12),
        _Field(
          label: phoneMethod
              ? 'auth.phone_label'.translate(context)
              : AppStrings.email.translate(context),
          controller: contact,
          keyboardType: phoneMethod
              ? TextInputType.phone
              : TextInputType.emailAddress,
        ),
        const SizedBox(height: 12),
        _Field(
          label: AppStrings.password.translate(context),
          controller: password,
          obscure: hidden,
          suffix: IconButton(
            onPressed: () => setState(() => hidden = !hidden),
            icon: Icon(
              hidden
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
            ),
          ),
        ),
        PasswordStrengthFeedback(controller: password),
        const SizedBox(height: 12),
        _Field(
          label: en ? 'Confirm Password' : 'تکرار رمز عبور',
          controller: confirmation,
          obscure: confirmHidden,
          suffix: IconButton(
            onPressed: () => setState(() => confirmHidden = !confirmHidden),
            icon: Icon(
              confirmHidden
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                value: terms,
                onChanged: (v) => setState(() => terms = v ?? false),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 4,
                children: [
                  if (en)
                    Text(
                      'auth.terms_accept'.translate(context),
                      style: _muted(context),
                    ),
                  InkWell(
                    onTap: _showTerms,
                    child: Text(
                      'auth.terms_link'.translate(context),
                      style: _muted(
                        context,
                      ).copyWith(color: Theme.of(context).colorScheme.primary),
                    ),
                  ),
                  if (!en)
                    Text(
                      'auth.terms_accept'.translate(context),
                      style: _muted(context),
                    ),
                ],
              ),
            ),
          ],
        ),
        if (error != null) ...[
          const SizedBox(height: 10),
          Text(
            error!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.error, fontSize: 13),
          ),
        ],
        const SizedBox(height: 12),
        _MainButton(
          label: en ? 'Send verification code' : 'ارسال کد تأیید',
          onPressed: loading ? null : register,
          loading: loading,
        ),
        const SizedBox(height: 12),
        _Prompt(
          prefix: en ? 'Already have an account?' : 'از قبل حساب کاربری دارید؟',
          action: AppStrings.sign_in_title.translate(context),
          onTap: () => Navigator.of(context).pop(),
        ),
        TextButton(
          onPressed: () => _continueAsGuest(context),
          child: Text(en ? 'Continue as guest' : 'ادامه بدون ثبت‌نام'),
        ),
      ],
    );
  }
}

class _AuthPage extends StatelessWidget {
  const _AuthPage({required this.children, this.spacedSections = false});
  final List<Widget> children;
  final bool spacedSections;
  @override
  Widget build(BuildContext context) {
    final dark = context.watch<AppData>().isDark;
    final en = context.watch<LocaleProvider>().locale.languageCode == 'en';
    return Directionality(
      textDirection: en ? TextDirection.ltr : TextDirection.rtl,
      child: Scaffold(
        backgroundColor: dark
            ? AppColors.background_dark
            : AppColors.background_light,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: spacedSections
                      ? (constraints.maxHeight - 46).clamp(0.0, double.infinity)
                      : 0,
                ),
                child: Column(
                  mainAxisAlignment: spacedSections
                      ? MainAxisAlignment.spaceBetween
                      : MainAxisAlignment.start,
                  children: children,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.title});
  final String title;
  @override
  Widget build(BuildContext context) {
    final color = context.watch<AppData>().isDark ? Colors.white : Colors.black;
    return Column(
      children: [
        ClipOval(child: const AppLogo(size: 120, withBackground: true)),
        const SizedBox(height: 18),
        Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: color,
            fontSize: 28,
            height: 1,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    this.controller,
    this.obscure = false,
    this.suffix,
    this.keyboardType,
    this.onTap,
  });
  final String label;
  final TextEditingController? controller;
  final bool obscure;
  final Widget? suffix;
  final TextInputType? keyboardType;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    final dark = context.watch<AppData>().isDark;
    OutlineInputBorder border(Color color) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(4),
      borderSide: BorderSide(color: color),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: _muted(context).copyWith(fontSize: 12)),
        const SizedBox(height: 8),
        SizedBox(
          height: 48,
          child: TextField(
            onTap: onTap,
            controller: controller,
            keyboardType: keyboardType,
            obscureText: obscure,
            style: TextStyle(
              color: dark ? Colors.white : Colors.black,
              fontSize: 13,
            ),
            decoration: InputDecoration(
              filled: true,
              suffixIcon: suffix,
              fillColor: dark
                  ? AppColors.surface_dark
                  : AppColors.surface_light,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14),
              enabledBorder: border(
                dark ? AppColors.border_dark : AppColors.border_light,
              ),
              focusedBorder: border(
                dark ? AppColors.primary_dark : AppColors.primary_light,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MainButton extends StatelessWidget {
  const _MainButton({
    required this.label,
    required this.onPressed,
    this.loading = false,
  });
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  @override
  Widget build(BuildContext context) {
    final dark = context.watch<AppData>().isDark;
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: dark
              ? AppColors.primary_dark
              : AppColors.primary_light,
          foregroundColor: dark ? Colors.black : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
        onPressed: onPressed,
        child: loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(label, style: const TextStyle(fontSize: 16)),
      ),
    );
  }
}

void _continueAsGuest(BuildContext context) {
  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => const HomePage()),
    (_) => false,
  );
}

class _OtpDialog extends StatefulWidget {
  const _OtpDialog({required this.destination});
  final String destination;
  @override
  State<_OtpDialog> createState() => _OtpDialogState();
}

class _OtpDialogState extends State<_OtpDialog> {
  final controllers = List.generate(6, (_) => TextEditingController());
  final nodes = List.generate(6, (_) => FocusNode());
  @override
  void dispose() {
    for (final item in controllers) {
      item.dispose();
    }
    for (final item in nodes) {
      item.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text('auth.otp_title'.translate(context)),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('${"auth.otp_prompt".translate(context)} ${widget.destination}'),
        const SizedBox(height: 18),
        Directionality(
          textDirection: TextDirection.ltr,
          child: Row(
            children: List.generate(
              6,
              (index) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: TextField(
                    controller: controllers[index],
                    focusNode: nodes[index],
                    autofocus: index == 0,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 20, height: 1.2),
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(1),
                    ],
                    onChanged: (value) {
                      if (value.isNotEmpty && index < 5) {
                        nodes[index + 1].requestFocus();
                      }
                      if (value.isEmpty && index > 0) {
                        nodes[index - 1].requestFocus();
                      }
                    },
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 0,
                      ),
                      counterText: '',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text('auth.cancel'.translate(context)),
      ),
      FilledButton(
        onPressed: () {
          final code = controllers.map((item) => item.text).join();
          if (RegExp(r'^\d{6}$').hasMatch(code)) Navigator.pop(context, code);
        },
        child: Text('auth.verify'.translate(context)),
      ),
    ],
  );
}

class _TermsDialog extends StatelessWidget {
  const _TermsDialog();
  static const sections = <(String, String)>[
    (
      '۱. پذیرش قوانین',
      'با ایجاد حساب یا استفاده از خدمات سرناز، این قوانین و تغییرات بعدی آن را می‌پذیرید.',
    ),
    (
      '۲. حساب کاربری',
      'اطلاعات ثبت‌نام باید صحیح باشد و مسئولیت حفظ امنیت رمز عبور و فعالیت‌های حساب بر عهده کاربر است.',
    ),
    (
      '۳. محتوای آموزشی',
      'محتوای دوره‌ها، مقالات و فایل‌های آموزشی صرفاً برای استفاده شخصی هنرجو است و انتشار، فروش یا کپی‌برداری بدون مجوز کتبی ممنوع است.',
    ),
    (
      '۴. پرداخت و انصراف',
      'شهریه دوره‌ها طبق تعرفه‌های اعلام‌شده دریافت می‌شود. شرایط استرداد وجه مطابق آیین‌نامه مالی آموزشگاه خواهد بود.',
    ),
    (
      '۵. حریم خصوصی',
      'اطلاعات شخصی کاربران محرمانه نگهداری می‌شود و جز در موارد قانونی یا با رضایت کاربر در اختیار شخص ثالث قرار نمی‌گیرد.',
    ),
    (
      '۶. رفتار کاربران',
      'هرگونه محتوای توهین‌آمیز، اسپم یا نقض حقوق دیگران در پیام‌ها، نظرات و پروفایل ممنوع است و می‌تواند به تعلیق حساب منجر شود.',
    ),
    (
      '۷. تغییرات قوانین',
      'آموزشگاه می‌تواند این قوانین را به‌روزرسانی کند. ادامه استفاده از خدمات پس از اعلام تغییرات به منزله پذیرش نسخه جدید است.',
    ),
  ];
  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('قوانین و شرایط استفاده'),
    content: SizedBox(
      width: 520,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final section in sections) ...[
              Text(
                section.$1,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(section.$2, style: const TextStyle(height: 1.55)),
              const SizedBox(height: 16),
            ],
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context, false),
        child: const Text('بستن'),
      ),
      FilledButton(
        onPressed: () => Navigator.pop(context, true),
        child: const Text('می‌پذیرم'),
      ),
    ],
  );
}

class _Prompt extends StatelessWidget {
  const _Prompt({
    required this.prefix,
    required this.action,
    required this.onTap,
  });
  final String prefix;
  final String action;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final dark = context.watch<AppData>().isDark;
    final accent = dark ? AppColors.primary_dark : AppColors.primary_light;
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          '$prefix ',
          style: TextStyle(
            color: dark ? Colors.white : Colors.black,
            fontSize: 16,
          ),
        ),
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Text(action, style: TextStyle(color: accent, fontSize: 16)),
          ),
        ),
      ],
    );
  }
}

TextStyle _muted(BuildContext context) {
  final dark = context.watch<AppData>().isDark;
  return TextStyle(
    color: dark
        ? AppColors.text_secondary_dark
        : AppColors.text_secondary_light,
    fontSize: 14,
  );
}
