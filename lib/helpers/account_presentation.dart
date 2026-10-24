import 'package:flutter/material.dart';
import 'development_access.dart';

/// Keep the production account interface for everyone except the site founder.
class AccountPresentation {
  static bool restricted(BuildContext context) =>
      !DevelopmentAccess.watch(context);
  static bool readRestricted(BuildContext context) =>
      !DevelopmentAccess.read(context);
}
