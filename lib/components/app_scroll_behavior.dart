import 'package:flutter/material.dart';
import 'package:sornaz/helpers/app_appearance.dart';

/// Decorates each vertical viewport, so the handle never covers sibling chrome.
class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior();

  @override
  Widget buildScrollbar(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    if (axisDirectionToAxis(details.direction) != Axis.vertical ||
        details.physics is NeverScrollableScrollPhysics) {
      return child;
    }
    return Scrollbar(
      controller: details.controller,
      thumbVisibility: true,
      interactive: true,
      thickness: 8,
      radius: appRadius(context).topLeft,
      scrollbarOrientation: Directionality.of(context) == TextDirection.rtl
          ? ScrollbarOrientation.right
          : ScrollbarOrientation.left,
      child: child,
    );
  }
}
