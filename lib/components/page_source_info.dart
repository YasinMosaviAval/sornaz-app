import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sornaz/screens/Authentication/providers/auth_session.dart';
import 'page_source_catalog.dart';
import '../helpers/development_access.dart';

bool canInspectPage(AuthSession? session) => DevelopmentAccess.allows(session);

/// Reserve a toolbar slot instead of placing a floating button over page actions.
class PageSourceToolbar extends StatelessWidget {
  const PageSourceToolbar({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final allowed = canInspectPage(context.watch<AuthSession?>());
    if (!allowed ||
        context.getInheritedWidgetOfExactType<_SourceToolbarScope>() != null) {
      return child;
    }
    return _SourceToolbarScope(
      child: Row(
        children: [
          Expanded(child: child),
          SafeArea(
            bottom: false,
            left: false,
            right: false,
            child: Padding(
              padding: const EdgeInsetsDirectional.only(end: 12),
              child: const PageSourceInfoButton(),
            ),
          ),
        ],
      ),
    );
  }
}

class _SourceToolbarScope extends InheritedWidget {
  const _SourceToolbarScope({required super.child});
  @override
  bool updateShouldNotify(_SourceToolbarScope oldWidget) => false;
}

/// Custom media controls can scroll when the administrator's extra action
/// would otherwise push an existing action off a narrow screen.
class PageSourceControlRow extends StatelessWidget {
  const PageSourceControlRow({
    super.key,
    required this.children,
    this.mainAxisAlignment = MainAxisAlignment.spaceBetween,
  });
  final List<Widget> children;
  final MainAxisAlignment mainAxisAlignment;

  @override
  Widget build(BuildContext context) {
    final row = Row(mainAxisAlignment: mainAxisAlignment, children: children);
    if (!canInspectPage(context.watch<AuthSession?>())) {
      return row;
    }
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: constraints.maxWidth),
          child: row,
        ),
      ),
    );
  }
}

/// Shared by ordinary toolbars and the video player's custom controls.
class PageSourceInfoButton extends StatelessWidget {
  const PageSourceInfoButton({super.key, this.color});
  final Color? color;

  @override
  Widget build(BuildContext context) {
    if (!canInspectPage(context.watch<AuthSession?>())) {
      return const SizedBox.shrink();
    }
    final fa = Localizations.localeOf(context).languageCode == 'fa';
    return IconButton(
      key: const ValueKey('page-source-info'),
      tooltip: fa ? 'فایل‌های سازندهٔ این صفحه' : 'Page source files',
      icon: Icon(Icons.info_outline, size: 24, color: color),
      onPressed: () {
        if (!canInspectPage(context.read<AuthSession?>())) return;
        final sources = collectPageSources(context);
        showDialog<void>(
          context: context,
          builder: (context) => _PageSourceDialog(sources: sources, fa: fa),
        );
      },
    );
  }
}

/// Only mounted, visible widgets of this route are evidence of rendered content.
Map<String, Set<String>> collectPageSources(BuildContext context) {
  Element root = context as Element;
  context.visitAncestorElements((element) {
    if (element.widget is Navigator) return false;
    root = element;
    return true;
  });
  final viewport = Offset.zero & MediaQuery.sizeOf(context);
  final result = <String, Set<String>>{};
  void record(Widget widget) {
    final name = widget.runtimeType.toString().split('<').first;
    for (final file in pageSourceClasses[name] ?? const <String>[]) {
      if (file.contains('/page_source_')) continue;
      result.putIfAbsent(file, () => <String>{}).add(name);
    }
  }

  // Application-level appearance and wrappers live above the route's Navigator.
  context.visitAncestorElements((element) {
    record(element.widget);
    return true;
  });
  void visit(Element element) {
    final widget = element.widget;
    if (widget is Offstage && widget.offstage) return;
    final render = element.findRenderObject();
    if (render is RenderBox && render.attached && render.hasSize) {
      final rect = MatrixUtils.transformRect(
        render.getTransformTo(null),
        Offset.zero & render.size,
      );
      if (!rect.overlaps(viewport)) return;
    }
    record(widget);
    element.visitChildren(visit);
  }

  visit(root);
  return result;
}

class _PageSourceDialog extends StatelessWidget {
  const _PageSourceDialog({required this.sources, required this.fa});
  final Map<String, Set<String>> sources;
  final bool fa;

  @override
  Widget build(BuildContext context) {
    // Dismiss the diagnostic content when the active account changes.
    if (!canInspectPage(context.watch<AuthSession?>())) {
      final route = ModalRoute.of(context);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted && route != null && route.isActive) {
          Navigator.of(context).removeRoute(route);
        }
      });
      return const SizedBox.shrink();
    }
    final files = sources.keys.toList()..sort();
    final dependencies = <String>{};
    for (final file in files) {
      dependencies.addAll(pageSourceImports[file] ?? const <String>[]);
    }
    dependencies.removeAll(files);
    dependencies.removeWhere((file) => file.contains('/page_source_'));
    final imports = dependencies.toList()..sort();
    final resources = <String>{};
    for (final file in [...files, ...imports]) {
      resources.addAll(pageSourceResources[file] ?? const <String>[]);
    }
    final assets = resources.toList()..sort();
    return AlertDialog(
      title: Text(fa ? 'ساختار این صفحه' : 'Page implementation'),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                fa
                    ? 'ویجت‌های قابل مشاهده در لحظهٔ باز کردن این پنجره؛ اجزای پنهان یا هنوز بارگذاری‌نشده در این فهرست نیستند.'
                    : 'Widgets visible when this dialog opened; hidden or not yet loaded components are excluded.',
              ),
              for (final file in files)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: SelectableText(
                    file,
                    textDirection: TextDirection.ltr,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  subtitle: Text(
                    '${sourceFileRole(file, fa)}\n${fa ? 'اجزای صفحه' : 'Page components'}: ${sources[file]!.join(', ')}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: Text(
                  fa ? 'وابستگی‌های مستقیم کد' : 'Direct code dependencies',
                ),
                subtitle: Text(
                  fa
                      ? 'وارد شدن فایل به کد، استفادهٔ اجرایی از آن را تأیید نمی‌کند.'
                      : 'An import does not prove runtime usage.',
                ),
                children: [
                  for (final file in imports)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: SelectableText(
                        file,
                        textDirection: TextDirection.ltr,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      subtitle: Text(
                        sourceFileRole(file, fa),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                ],
              ),
              if (assets.isNotEmpty)
                ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  title: Text(
                    fa ? 'منابع ارجاع‌شده در کد' : 'Referenced resources',
                  ),
                  subtitle: Text(
                    fa
                        ? 'تصویر، صدا یا فایل‌های ویرایشگر؛ ارجاع ثابت به معنی بارگذاری فعلی نیست.'
                        : 'Images, audio or editor resources; a static reference does not prove current loading.',
                  ),
                  children: [
                    for (final file in assets)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: SelectableText(
                          file,
                          textDirection: TextDirection.ltr,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        subtitle: Text(
                          sourceFileRole(file, fa),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(fa ? 'بستن' : 'Close'),
        ),
      ],
    );
  }
}

String sourceFileRole(String file, bool fa) {
  final value = file.toLowerCase();
  const roles = <String, List<String>>{
    'my_app.dart': [
      'قالب اصلی برنامه، زبان، رنگ‌ها، تایپوگرافی و مسیرهای اصلی',
      'Application shell, locale, theme, typography and named routes',
    ],
    'app_data.dart': [
      'تنظیمات مشترک ظاهر و رفتار برنامه',
      'Shared application appearance and behavior settings',
    ],
    'app_top_bar_direction.dart': [
      'جهت راست‌به‌چپ یا چپ‌به‌راست و ابعاد استاندارد نوار بالا',
      'Toolbar direction, title style and standard dimensions',
    ],
    'expanding_search_bar.dart': [
      'دکمه جست‌وجو، باز و بسته شدن کادر جست‌وجو و اکشن‌های نوار بالا',
      'Animated search field and toolbar actions',
    ],
    'home_top_bar.dart': [
      'دکمه دراور، لوگو و اکشن‌های نوار بالای صفحات اصلی',
      'Main page drawer button, logo and toolbar actions',
    ],
    'main_tabs.dart': [
      'مقصدهای تب‌های اصلی و نگهداری وضعیت و نوار بالای هر تب',
      'Main tab destinations, state and shared toolbar',
    ],
    'scroll_aware_scaffold.dart': [
      'پوسته صفحه و رفتار نوار بالا هنگام اسکرول',
      'Page scaffold and toolbar scrolling behavior',
    ],
    'sleep_timer_chrome.dart': [
      'نمایش شمارش معکوس تایمر خواب روی نوار بالا',
      'Sleep timer countdown in the toolbar',
    ],
    'app_text.dart': [
      'نمایش متن با سبک و تنظیمات مشترک برنامه',
      'Text presentation using shared application styles',
    ],
    'app_logo.dart': ['رسم لوگوی برنامه', 'Application logo'],
    'learning_home.dart': [
      'چیدمان صفحه خانه، بخش‌های محتوا و لینک‌های آن‌ها',
      'Home page layout, content sections and links',
    ],
    'panel_resource_page.dart': [
      'فهرست، جزئیات و عملیات منابع پنل کاربری',
      'Panel resource lists, details and actions',
    ],
    'panel_form.dart': [
      'فرم‌های ایجاد و ویرایش اطلاعات پنل',
      'Panel create and edit forms',
    ],
    'notation_top_bar.dart': [
      'دکمه‌ها و فرمان‌های نوار بالای نت‌نویسی',
      'Notation toolbar actions and commands',
    ],
    'music_sheets_page.dart': [
      'میزبانی ویرایشگر WebView، ارتباط فرمان‌ها و مدیریت قطعات نت',
      'Notation WebView host, command bridge and sheet management',
    ],
    'auth_session.dart': [
      'حساب فعال، وضعیت ورود و تغییر حساب کاربری',
      'Active account, authentication and account switching',
    ],
  };
  final role = roles[value.split('/').last];
  if (role != null) return role[fa ? 0 : 1];
  if (value.endsWith('.js')) {
    return fa
        ? 'منطق اجرایی و رندر بخش WebView؛ مسئولیت دقیق مطابق نام فایل'
        : 'WebView behavior and rendering, as named';
  }
  if (value.endsWith('.html')) {
    return fa
        ? 'ساختار صفحهٔ داخلی WebView و بارگذاری منابع آن'
        : 'Embedded WebView document and resource loading';
  }
  if (value.endsWith('.css')) {
    return fa
        ? 'چیدمان و سبک عناصر صفحهٔ داخلی WebView'
        : 'Embedded WebView layout and styles';
  }
  if (value.startsWith('assets/')) {
    return fa
        ? 'منبع تصویری، صوتی یا دادهٔ مورد ارجاع این بخش'
        : 'Referenced visual, audio or data resource';
  }
  if (value.contains('api') ||
      value.contains('service') ||
      value.contains('/library/')) {
    return fa
        ? 'ارتباط با داده‌ها و سرویس‌های مورد استفادهٔ صفحه'
        : 'Data access and supporting services';
  }
  if (value.contains('model')) {
    return fa ? 'تعریف ساختار داده‌ها' : 'Data structures';
  }
  if (value.contains('provider') ||
      value.contains('controller') ||
      value.contains('settings')) {
    return fa
        ? 'وضعیت، تنظیمات و کنترل رفتار صفحه'
        : 'State, settings and behavior';
  }
  if (value.contains('/helpers/')) {
    return fa
        ? 'ظاهر، ترجمه یا ابزارهای مشترک؛ نقش دقیق مطابق نام فایل'
        : 'Shared appearance, localization or utilities, as named';
  }
  if (value.contains('/pages/') ||
      value.contains('_page.dart') ||
      value.contains('_screen.dart')) {
    return fa
        ? 'ساخت چیدمان و تعامل‌های صفحهٔ مشخص‌شده در نام فایل'
        : 'Layout and interactions of the page identified by the file name';
  }
  return fa
      ? 'تعریف اجزای رابط کاربری یا مقصدهای مرتبط؛ نام فایل مسیر مسئولیت را نشان می‌دهد'
      : 'UI components or related destinations, identified by file name';
}
