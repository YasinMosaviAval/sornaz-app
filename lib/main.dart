import 'package:flutter/material.dart';
import 'package:sornaz/helpers/app_data.dart';
import 'package:provider/provider.dart';
import 'package:sornaz/helpers/app_locale_provider.dart';

void main() {
  runApp(
    // ChangeNotifierProvider(create: (_) => AppData(), child: const MyApp()),
    //   );
    // }

    // void main() {
    //   runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppData()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
      ],
      child: const MyApp(),
    ),
  );
}
