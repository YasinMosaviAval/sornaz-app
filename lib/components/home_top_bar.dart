import 'package:flutter/material.dart';

import 'app_logo.dart';
import 'app_top_bar_direction.dart';
import 'expanding_search_bar.dart';

class HomeTopBar extends StatelessWidget implements PreferredSizeWidget {
  const HomeTopBar({
    super.key,
    this.onSearch,
    this.searchOnly = false,
    this.searchTextInset,
    this.pageTitle,
    this.flexibleSpace,
    this.leadingWidget,
    this.trailingWidget,
    this.extraActions = const [],
    this.onFilter,
    this.hint = '',
    this.initialQuery = '',
  });

  final Widget? leadingWidget, trailingWidget, flexibleSpace;
  final bool searchOnly;
  final double? searchTextInset;
  final String? pageTitle;
  final List<Widget> extraActions;
  final ValueChanged<String>? onSearch;
  final VoidCallback? onFilter;
  final String hint, initialQuery;

  @override
  Size get preferredSize => const Size.fromHeight(48);

  Widget _leading() => SizedBox(
    width: AppTopBarDirection.leadingWidth,
    child: searchOnly
        ? const BackButton()
        : leadingWidget ??
              Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              ),
  );

  List<Widget> _actions() => [
    ...extraActions,
    if (!searchOnly)
      if (leadingWidget != null)
        Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        )
      else
        Padding(
          padding: EdgeInsetsDirectional.only(
            end: trailingWidget == null ? 20 : 12,
          ),
          child: SizedBox(
            width: AppTopBarDirection.leadingWidth,
            child:
                trailingWidget ??
                const Center(child: AppLogo(size: 40, withBackground: false)),
          ),
        ),
  ];

  @override
  Widget build(BuildContext context) {
    final title = Row(
      children: [
        _leading(),
        if (pageTitle != null)
          Expanded(
            child: Text(
              pageTitle!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: AppTopBarDirection.titleSize(context)),
            ),
          ),
      ],
    );
    if (onSearch != null) {
      return ExpandingSearchBar(
        title: title,
        onChanged: onSearch!,
        onFilter: onFilter,
        background: flexibleSpace,
        initialQuery: initialQuery,
        openKey: const ValueKey('open-home-search'),
        fieldKey: const ValueKey('home-search'),
        hint: hint,
        actions: _actions(),
        actionsExtraWidth: searchOnly || leadingWidget != null
            ? 0
            : trailingWidget == null
            ? 20
            : 12,
      );
    }
    return AppTopBarDirection(
      child: AppBar(
        automaticallyImplyLeading: false,
        flexibleSpace: flexibleSpace,
        title: Padding(
          padding: const EdgeInsetsDirectional.only(
            start: AppTopBarDirection.contentInset,
          ),
          child: title,
        ),
        actions: _actions(),
      ),
    );
  }
}
