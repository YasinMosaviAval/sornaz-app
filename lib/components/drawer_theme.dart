import 'package:flutter/material.dart';

/// The drawer inherits the same appearance settings as the rest of the app.
class DrawerThemeScope extends StatelessWidget {
  const DrawerThemeScope({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => child;
}
