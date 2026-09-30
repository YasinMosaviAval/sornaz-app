import 'package:flutter/material.dart';

/// Shared corner radius from the application's appearance settings.
BorderRadius appRadius(BuildContext context) {
  final shape = Theme.of(context).cardTheme.shape;
  if (shape is RoundedRectangleBorder && shape.borderRadius is BorderRadius) {
    return shape.borderRadius as BorderRadius;
  }
  return BorderRadius.circular(4);
}
