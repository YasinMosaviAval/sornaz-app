import 'app_top_bar_direction.dart';
import 'package:flutter/material.dart';
import 'app_logo.dart';

class HomeTopBar extends StatefulWidget implements PreferredSizeWidget {
  const HomeTopBar({
    super.key,
    this.onSearch,
    this.searchOnly = false,
    this.searchTextInset,
    this.pageTitle,
    this.flexibleSpace,
    this.leadingWidget,
    this.extraActions = const [],
    this.onFilter,
    this.hint = '',
    this.initialQuery = '',
  });
  final Widget? leadingWidget, flexibleSpace;
  final bool searchOnly;
  final double? searchTextInset;
  final String? pageTitle;
  final List<Widget> extraActions;
  final ValueChanged<String>? onSearch;
  final VoidCallback? onFilter;
  final String hint, initialQuery;
  @override
  Size get preferredSize => const Size.fromHeight(56);
  @override
  State<HomeTopBar> createState() => _HomeTopBarState();
}

class _HomeTopBarState extends State<HomeTopBar> {
  late bool open = widget.initialQuery.isNotEmpty;
  late final input = TextEditingController(text: widget.initialQuery);
  @override
  void didUpdateWidget(HomeTopBar old) {
    super.didUpdateWidget(old);
    if (old.hint != widget.hint) {
      open = widget.initialQuery.isNotEmpty;
      input.text = widget.initialQuery;
    }
  }

  @override
  void dispose() {
    input.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: widget.pageTitle != null
        ? (Localizations.localeOf(context).languageCode == 'fa'
              ? TextDirection.rtl
              : TextDirection.ltr)
        : (Localizations.localeOf(context).languageCode == 'fa'
              ? TextDirection.ltr
              : TextDirection.rtl),
    child: AppBar(
      automaticallyImplyLeading: false,
      titleSpacing: widget.pageTitle != null
          ? 0
          : widget.searchOnly
          ? 12
          : 0,
      flexibleSpace: widget.flexibleSpace,
      leading: widget.searchOnly
          ? (widget.pageTitle != null ? const BackButton() : null)
          : widget.leadingWidget ??
                const Padding(
                  padding: EdgeInsets.all(8),
                  child: AppLogo(size: 40, withBackground: false),
                ),
      title: widget.onSearch == null
          ? null
          : LayoutBuilder(
              builder: (context, constraints) => Align(
                alignment: AlignmentDirectional.centerEnd,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeInOutCubic,
                  height: 48,
                  width: open || widget.pageTitle != null
                      ? constraints.maxWidth
                      : 48,
                  child: open
                      ? ClipRect(
                          child: OverflowBox(
                            minWidth: constraints.maxWidth,
                            maxWidth: constraints.maxWidth,
                            alignment: AlignmentDirectional.centerEnd,
                            child: Directionality(
                              textDirection: widget.searchTextInset != null
                                  ? (Localizations.localeOf(
                                              context,
                                            ).languageCode ==
                                            'fa'
                                        ? TextDirection.rtl
                                        : TextDirection.ltr)
                                  : (widget.pageTitle != null
                                        ? (Localizations.localeOf(
                                                    context,
                                                  ).languageCode ==
                                                  'fa'
                                              ? TextDirection.rtl
                                              : TextDirection.ltr)
                                        : (Localizations.localeOf(
                                                    context,
                                                  ).languageCode ==
                                                  'fa'
                                              ? TextDirection.ltr
                                              : TextDirection.rtl)),
                              child: TextField(
                                key: const ValueKey('home-search'),
                                controller: input,
                                textDirection:
                                    Localizations.localeOf(
                                          context,
                                        ).languageCode ==
                                        'fa'
                                    ? TextDirection.rtl
                                    : TextDirection.ltr,
                                autofocus: true,
                                onChanged: widget.onSearch,
                                style: const TextStyle(fontSize: 13),
                                decoration: InputDecoration(
                                  filled: false,
                                  contentPadding: widget.searchTextInset == null
                                      ? null
                                      : EdgeInsetsDirectional.only(
                                          start: widget.searchTextInset! - 12,
                                          top: 12,
                                          bottom: 12,
                                        ),
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  hintText: widget.hint,
                                  suffixIcon: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (widget.onFilter != null)
                                        IconButton(
                                          icon: const Icon(Icons.tune),
                                          onPressed: widget.onFilter,
                                        ),
                                      IconButton(
                                        icon: const Icon(Icons.close),
                                        onPressed: () {
                                          input.clear();
                                          widget.onSearch?.call('');
                                          setState(() => open = false);
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        )
                      : Row(
                          children: [
                            if (widget.pageTitle != null)
                              Expanded(
                                child: Text(
                                  widget.pageTitle!,
                                  style: TextStyle(
                                    fontSize: AppTopBarDirection.titleSize(
                                      context,
                                    ),
                                  ),
                                ),
                              ),
                            if (widget.pageTitle == null) const Spacer(),
                            IconButton(
                              key: const ValueKey('open-home-search'),
                              icon: const Icon(Icons.search),
                              onPressed: () => setState(() => open = true),
                            ),
                          ],
                        ),
                ),
              ),
            ),
      actions: [
        if (widget.searchOnly && widget.pageTitle != null)
          const SizedBox(width: 12),
        if (!open) ...widget.extraActions,
        if (!widget.searchOnly)
          Builder(
            builder: (c) => IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => Scaffold.of(c).openDrawer(),
            ),
          ),
        if (!widget.searchOnly) const SizedBox(width: 12),
      ],
    ),
  );
}
