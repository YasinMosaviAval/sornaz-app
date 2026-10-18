import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../screens/Authentication/providers/auth_session.dart';

/// Development UI is available only to the active authenticated site founder.
class DevelopmentAccess {
  static bool allows(AuthSession? session) =>
      session?.isAuthenticated == true &&
      session!.token!.trim().isNotEmpty &&
      session.user!.id == 1;
  static bool watch(BuildContext context) =>
      allows(context.watch<AuthSession?>());
  static bool read(BuildContext context) =>
      allows(context.read<AuthSession?>());
}

/// Lazily creates experimental screens and disposes them on account changes.
class DevelopmentGate extends StatelessWidget {
  const DevelopmentGate({super.key, required this.builder});
  final WidgetBuilder builder;
  @override
  Widget build(BuildContext context) => DevelopmentAccess.watch(context)
      ? Builder(builder: builder)
      : Scaffold(appBar: AppBar(), body: const SizedBox.expand());
}
