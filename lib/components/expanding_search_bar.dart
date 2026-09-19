import 'package:flutter/material.dart';

class ExpandingSearchBar extends StatefulWidget implements PreferredSizeWidget {
  const ExpandingSearchBar({
    super.key,
    required this.title,
    required this.onChanged,
    this.onSettings,
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
  final String hint;
  final List<Widget> actions;
  @override
  Size get preferredSize => const Size.fromHeight(56);
  @override
  State<ExpandingSearchBar> createState() => _ExpandingSearchBarState();
}

class _ExpandingSearchBarState extends State<ExpandingSearchBar> {
  bool open = false;
  final field = TextEditingController();
  @override
  void dispose() {
    field.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: Directionality.of(context) == TextDirection.rtl
        ? TextDirection.ltr
        : TextDirection.rtl,
    child: SafeArea(
      bottom: false,
      child: SizedBox(
        height: 56,
        child: LayoutBuilder(
          builder: (_, constraints) => Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeInOutCubic,
                width: open
                    ? 0
                    : (constraints.maxWidth - 96 - widget.actions.length * 48)
                          .clamp(0, double.infinity),
                child: ClipRect(
                  child: OverflowBox(
                    alignment: AlignmentDirectional.centerStart,
                    minWidth:
                        (constraints.maxWidth - 96 - widget.actions.length * 48)
                            .clamp(0, double.infinity),
                    maxWidth:
                        (constraints.maxWidth - 96 - widget.actions.length * 48)
                            .clamp(0, double.infinity),
                    child: AnimatedOpacity(
                      opacity: open ? 0 : 1,
                      duration: const Duration(milliseconds: 160),
                      child: widget.title,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: open
                      ? TextField(
                          key: const ValueKey('expanded-search'),
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
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () {
                                field.clear();
                                widget.onChanged('');
                                setState(() => open = false);
                              },
                            ),
                          ),
                        )
                      : IconButton(
                          key: const ValueKey('open-search'),
                          tooltip: widget.hint,
                          icon: const Icon(Icons.search),
                          onPressed: () => setState(() => open = true),
                        ),
                ),
              ),
              if (!open) ...widget.actions,
              if (!open)
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
    ),
  );
}
