import 'package:flutter/material.dart';
import 'package:sornaz/classes/my_app.dart';
import 'package:sornaz/helpers/app_data.dart';
import 'package:provider/provider.dart';
import 'package:sornaz/helpers/app_locale_provider.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppData()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
      ],
      child: const MyApp(),
    ),
  );
}
