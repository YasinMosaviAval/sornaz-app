import 'package:flutter/material.dart';
import 'package:sornaz/helpers/app_data.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(
    ChangeNotifierProvider(create: (_) => AppData(), child: const MyApp()),
  );
}
