import 'sleep_timer_chrome.dart';
import 'package:flutter/material.dart';

class ExpandingSearchBar extends StatefulWidget implements PreferredSizeWidget {
  const ExpandingSearchBar({
    super.key,
    required this.title,
    required this.onChanged,
    this.onSettings,
    this.onFilter,
    this.background,
    this.initialQuery = '',
    this.openKey,
    this.fieldKey,
    this.searchIconSize = 24,
    this.searchIconColor,
    this.hint = 'جستجو',
    this.actions = const [],
  });
  final double searchIconSize;
  final Color? searchIconColor;
  final Widget title;
  final ValueChanged<String> onChanged;
  final VoidCallback? onSettings;
  final VoidCallback? onFilter;
  final Widget? background;
  final String initialQuery;
  final Key? openKey, fieldKey;
  final String hint;
  final List<Widget> actions;
  @override
  Size get preferredSize => const Size.fromHeight(48);
  @override
  State<ExpandingSearchBar> createState() => _ExpandingSearchBarState();
}

class _ExpandingSearchBarState extends State<ExpandingSearchBar> {
  late bool open = widget.initialQuery.isNotEmpty;
  late final field = TextEditingController(text: widget.initialQuery);
  @override
  void didUpdateWidget(covariant ExpandingSearchBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.hint != widget.hint ||
        oldWidget.initialQuery != widget.initialQuery) {
      field.text = widget.initialQuery;
      open = widget.initialQuery.isNotEmpty;
    }
  }

  @override
  void dispose() {
    field.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SleepTimerChrome(
    child: Directionality(
      textDirection: Localizations.localeOf(context).languageCode == 'fa'
          ? TextDirection.rtl
          : TextDirection.ltr,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 48,
          child: Stack(
            children: [
              if (widget.background != null)
                Positioned.fill(child: widget.background!),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: LayoutBuilder(
                  builder: (_, constraints) => Row(
                    children: [
                      AnimatedContainer(
                        key: ValueKey(widget.actions.length),
                        duration: const Duration(milliseconds: 280),
                        curve: Curves.easeInOutCubic,
                        width: open
                            ? 0
                            : (constraints.maxWidth -
                                      48 -
                                      widget.actions.length * 48 -
                                      (widget.onSettings == null ? 0 : 48))
                                  .clamp(0, double.infinity),
                        child: ClipRect(
                          child: OverflowBox(
                            alignment: AlignmentDirectional.centerStart,
                            minWidth:
                                (constraints.maxWidth -
                                        48 -
                                        widget.actions.length * 48 -
                                        (widget.onSettings == null ? 0 : 48))
                                    .clamp(0, double.infinity),
                            maxWidth:
                                (constraints.maxWidth -
                                        48 -
                                        widget.actions.length * 48 -
                                        (widget.onSettings == null ? 0 : 48))
                                    .clamp(0, double.infinity),
                            child: AnimatedOpacity(
                              opacity: open ? 0 : 1,
                              duration: const Duration(milliseconds: 160),
                              child: widget.title,
                            ),
                          ),
                        ),
                      ),
                      if (open)
                        Expanded(
                          child: TextField(
                            key:
                                widget.fieldKey ??
                                const ValueKey('expanded-search'),
                            controller: field,
                            textDirection: Directionality.of(context),
                            autofocus: true,
                            style: const TextStyle(fontSize: 13),
                            onChanged: widget.onChanged,
                            decoration: InputDecoration(
                              hintText: widget.hint,
                              filled: false,
                              border: InputBorder.none,
                              prefixIcon: Icon(
                                Icons.search,
                                size: widget.searchIconSize,
                                color: widget.searchIconColor,
                              ),
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
                                      field.clear();
                                      widget.onChanged('');
                                      setState(() => open = false);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      if (!open)
                        IconButton(
                          key: widget.openKey ?? const ValueKey('open-search'),
                          tooltip: widget.hint,
                          icon: Icon(
                            Icons.search,
                            size: widget.searchIconSize,
                            color: widget.searchIconColor,
                          ),
                          onPressed: () => setState(() => open = true),
                        ),
                      if (!open) ...widget.actions,
                      if (!open && widget.onSettings != null)
                        IconButton(
                          icon: Icon(
                            Icons.settings,
                            size: widget.searchIconSize,
                            color: widget.searchIconColor,
                          ),
                          onPressed: widget.onSettings,
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
