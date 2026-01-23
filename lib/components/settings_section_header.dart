import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sornaz/helpers/app_colors.dart';
import 'package:sornaz/helpers/app_data.dart';
import 'package:sornaz/helpers/app_spacing.dart';
import 'package:sornaz/helpers/app_typography.dart';


class SettingsSectionHeader extends StatefulWidget {
  final String title;

  final List<Widget>? children;
  final IconData? leadingIcon;
  final double size;
  final bool showDivider;
  final bool animated;
  final EdgeInsetsGeometry padding;

  final bool collapsible;
  final bool initiallyExpanded;
  final ValueChanged<bool>? onExpandChanged;

  const SettingsSectionHeader({
    super.key,
    required this.title,
    this.children,
    this.leadingIcon,
    this.size = 24,
    this.showDivider = true,
    this.animated = true,
    this.padding = const EdgeInsets.symmetric(
      horizontal: AppSpacing.space_12,
      vertical: AppSpacing.space_12
    ),

    this.collapsible = true,
    this.initiallyExpanded = true,
    this.onExpandChanged,
  });

  @override
  State<SettingsSectionHeader> createState() => _SettingsSectionHeaderState();
}

class _SettingsSectionHeaderState extends State<SettingsSectionHeader> {
  late bool _expanded;

  bool get _isCollapsible => widget.collapsible && widget.children != null;
  bool _contentVisible = true;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
  }

  void _toggle() {
    if (!_isCollapsible) return;

    if (_expanded) {
      _collapse();
      widget.onExpandChanged?.call(false);
    } else {
      _expand();
      widget.onExpandChanged?.call(true);
    }
  }

  void _expand() {
    setState(() {
      _expanded = true;
    });

    Future.delayed(const Duration(milliseconds: 50), () {
      if (mounted) {
        setState(() {
          _contentVisible = true;
        });
      }
    });
  }

  void _collapse() {
    setState(() {
      _contentVisible = false;
    });

    Future.delayed(const Duration(milliseconds: 50), () {
      if (mounted) {
        setState(() {
          _expanded = false;
        });
      }
    });
  }


  @override
  Widget build(BuildContext context) {
    final appData = Provider.of<AppData>(context);
    final isDark = appData.isDark;
    final textColor = AppColors.settings_section_header_text_color(isDark: isDark);

    Widget header = InkWell(
      onTap: _isCollapsible ? _toggle : null,
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(AppSpacing.space_8),
        topRight: Radius.circular(AppSpacing.space_8),
        bottomLeft: Radius.circular(AppSpacing.space_2),
        bottomRight: Radius.circular(AppSpacing.space_2)
      ),
      child: Padding(
        padding: widget.padding,
        child: Row(
          children: [
            if (widget.leadingIcon != null) ...[
              Icon(
                widget.leadingIcon,
                size: widget.size,
                color: textColor,
              ),
              const SizedBox(width: AppSpacing.space_12),
            ],

            Expanded(
              child: Text(
                widget.title,
                style: AppTypography.settingsSectionHeaderTitle(context, textColor),
              ),
            ),

            if (_isCollapsible)
              AnimatedRotation(
                turns: _expanded ? 0.5 : 0,
                duration: const Duration(milliseconds: 250),
                child: Icon(
                  Icons.keyboard_arrow_down,
                  color: textColor,
                ),
              ),
          ],
        ),
      ),
    );

    if (widget.animated) {
      header = AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: 1,
        child: header,
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.space_16),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.settings_section_header_box_decoration_color(isDark: isDark),
          borderRadius: BorderRadius.all(Radius.circular(AppSpacing.space_8))
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            header,

            if (widget.showDivider)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space_8),
                child: Divider(
                  height: AppSpacing.space_16,
                  thickness: 1,
                  color: AppColors.settings_section_header_divider_color(isDark: isDark),
                ),
              ),

            if (widget.children != null)
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                alignment: Alignment.topCenter,
                child: ClipRect(
                  child: Align(
                    alignment: Alignment.topCenter,
                    heightFactor: _expanded ? 1.0 : 0.0,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      opacity: _contentVisible ? 1.0 : 0.0,
                      child: AnimatedSlide(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        offset: _contentVisible ? Offset.zero : const Offset(0, -0.05),
                        child: Column(
                          children: widget.children!,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

          ],
        ),
      ),
    );
  }
}
