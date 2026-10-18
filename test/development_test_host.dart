import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sornaz/screens/Authentication/providers/auth_session.dart';
import 'package:sornaz/screens/Authentication/models/auth_user.dart';

/// Existing experimental UI tests explicitly exercise the founder's interface.
Widget developmentAdmin(Widget child) => ChangeNotifierProvider<AuthSession>(
  create: (_) => AuthSession()
    ..token = 'development-test'
    ..user = AuthUser(id: 1, username: 'founder', fullName: 'Founder'),
  child: child,
);
