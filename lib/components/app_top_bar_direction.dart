import 'sleep_timer_chrome.dart';
import 'package:flutter/material.dart';
import 'app_text.dart';
import 'package:provider/provider.dart';
import 'package:sornaz/helpers/app_data.dart';

/// Page navigation follows the locale and the original Contact page typography.
class AppTopBarDirection extends StatelessWidget
    implements PreferredSizeWidget {
  const AppTopBarDirection({super.key, required this.child});
  final PreferredSizeWidget child;
  static double titleSize(BuildContext context) =>
      14.0 + (context.watch<AppData?>()?.fontSize ?? 0);
  @override
  Size get preferredSize => child.preferredSize;
  Widget? title(BuildContext context, Widget? value) {
    if (value is Text && value.data != null)
      return Text(
        value.data!,
        key: value.key,
        textAlign: TextAlign.start,
        textDirection: value.textDirection,
        semanticsLabel: value.semanticsLabel,
        style: (value.style ?? const TextStyle()).copyWith(
          fontSize: titleSize(context),
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    if (value is AppText)
      return AppText(
        value.data,
        key: value.key,
        style: (value.style ?? const TextStyle()).copyWith(
          fontSize: titleSize(context),
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    return value;
  }

  @override
  Widget build(BuildContext context) {
    final bar = child;
    return SleepTimerChrome(
      child: Directionality(
        textDirection: Localizations.localeOf(context).languageCode == 'fa'
            ? TextDirection.rtl
            : TextDirection.ltr,
        child: bar is AppBar
            ? AppBar(
                key: bar.key,
                leading: bar.leading,
                automaticallyImplyLeading: bar.automaticallyImplyLeading,
                title: title(context, bar.title),
                actions: bar.actions,
                flexibleSpace: bar.flexibleSpace,
                bottom: bar.bottom,
                elevation: bar.elevation,
                scrolledUnderElevation: bar.scrolledUnderElevation,
                shadowColor: bar.shadowColor,
                surfaceTintColor: bar.surfaceTintColor,
                shape: bar.shape,
                backgroundColor: bar.backgroundColor,
                foregroundColor: bar.foregroundColor,
                iconTheme: bar.iconTheme,
                actionsIconTheme: bar.actionsIconTheme,
                excludeHeaderSemantics: bar.excludeHeaderSemantics,
                clipBehavior: bar.clipBehavior,
                actionsPadding: bar.actionsPadding,
                primary: bar.primary,
                centerTitle: false,
                titleSpacing: 0,
                toolbarHeight: bar.toolbarHeight,
                leadingWidth: bar.leadingWidth,
                toolbarOpacity: bar.toolbarOpacity,
                bottomOpacity: bar.bottomOpacity,
                toolbarTextStyle: bar.toolbarTextStyle,
                titleTextStyle: bar.titleTextStyle?.copyWith(
                  fontSize: titleSize(context),
                ),
                systemOverlayStyle: bar.systemOverlayStyle,
                notificationPredicate: bar.notificationPredicate,
                forceMaterialTransparency: bar.forceMaterialTransparency,
              )
            : bar,
      ),
    );
  }
}
