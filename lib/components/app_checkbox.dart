import 'package:flutter/material.dart';

const appCheckboxTheme = CheckboxThemeData(
  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
  visualDensity: VisualDensity(vertical: (AppCheckbox.height - 40) / 4),
);

/// The application checkbox. All pages share this 24dp control height.
class AppCheckbox extends StatelessWidget {
  const AppCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    this.tristate = false,
    this.activeColor,
    this.checkColor,
    this.focusNode,
    this.autofocus = false,
    this.semanticLabel,
  });

  static const double height = 24;
  final bool? value;
  final ValueChanged<bool?>? onChanged;
  final bool tristate, autofocus;
  final Color? activeColor, checkColor;
  final FocusNode? focusNode;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: height,
    child: Checkbox(
      value: value,
      onChanged: onChanged,
      tristate: tristate,
      activeColor: activeColor,
      checkColor: checkColor,
      focusNode: focusNode,
      autofocus: autofocus,
      semanticLabel: semanticLabel,
      visualDensity: appCheckboxTheme.visualDensity,
      materialTapTargetSize: appCheckboxTheme.materialTapTargetSize,
    ),
  );
}

/// A compact checkbox row; longer titles/subtitles can grow without clipping.
class AppCheckboxTile extends StatelessWidget {
  const AppCheckboxTile({
    super.key,
    required this.value,
    required this.onChanged,
    this.title,
    this.subtitle,
    this.contentPadding,
    this.controlAffinity = ListTileControlAffinity.platform,
    this.visualDensity,
    this.tristate = false,
    this.selected = false,
    this.enabled,
    this.dense,
  });

  static const double minHeight = AppCheckbox.height + 4;
  final bool? value;
  final ValueChanged<bool?>? onChanged;
  final Widget? title, subtitle;
  final EdgeInsetsGeometry? contentPadding;
  final ListTileControlAffinity controlAffinity;
  final VisualDensity? visualDensity;
  final bool tristate, selected;
  final bool? enabled;
  final bool? dense;

  @override
  Widget build(BuildContext context) => CheckboxTheme(
    data: CheckboxTheme.of(context).copyWith(
      visualDensity: appCheckboxTheme.visualDensity,
      materialTapTargetSize: appCheckboxTheme.materialTapTargetSize,
    ),
    child: CheckboxListTile(
      value: value,
      onChanged: onChanged,
      title: title,
      subtitle: subtitle,
      contentPadding: contentPadding,
      controlAffinity: controlAffinity,
      visualDensity: VisualDensity(horizontal: visualDensity?.horizontal ?? 0),
      minTileHeight: minHeight,
      minVerticalPadding: 2,
      tristate: tristate,
      selected: selected,
      enabled: enabled,
      dense: dense,
    ),
  );
}
