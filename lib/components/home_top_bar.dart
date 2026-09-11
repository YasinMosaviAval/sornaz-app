import 'package:flutter/material.dart';
import 'app_logo.dart';

class HomeTopBar extends StatefulWidget implements PreferredSizeWidget {
  const HomeTopBar({
    super.key,
    this.onSearch,
    this.onFilter,
    this.hint = '',
    this.initialQuery = '',
  });
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
  void dispose() {
    input.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AppBar(
    automaticallyImplyLeading: false,
    titleSpacing: 0,
    leading: const Padding(
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
                width: open ? constraints.maxWidth : 48,
                child: open
                    ? ClipRect(
                        child: OverflowBox(
                          minWidth: constraints.maxWidth,
                          maxWidth: constraints.maxWidth,
                          alignment: AlignmentDirectional.centerEnd,
                          child: TextField(
                            key: const ValueKey('home-search'),
                            controller: input,
                            autofocus: true,
                            onChanged: widget.onSearch,
                            style: const TextStyle(fontSize: 13),
                            decoration: InputDecoration(
                              filled: false,
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
                      )
                    : IconButton(
                        key: const ValueKey('open-home-search'),
                        icon: const Icon(Icons.search),
                        onPressed: () => setState(() => open = true),
                      ),
              ),
            ),
          ),
    actions: [
      Builder(
        builder: (c) => IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => Scaffold.of(c).openDrawer(),
        ),
      ),
      const SizedBox(width: 12),
    ],
  );
}
